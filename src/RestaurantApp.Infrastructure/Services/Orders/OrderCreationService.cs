using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Order;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Domain.Enums;
using RestaurantApp.Domain.Events;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.Infrastructure.Services.Orders;

public class OrderCreationService : IOrderCreationService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<OrderCreationService> _logger;

    public OrderCreationService(
        ApplicationDbContext context,
        ILogger<OrderCreationService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<ApiResponse<OrderCreatedDto>> CreateOrderAsync(int userId, CreateOrderDto dto)
    {
        // Start explicit transaction for data consistency
        await using var transaction = await _context.Database.BeginTransactionAsync();
        
        try
        {
            // Validate branch
            var branch = await _context.Branches.FindAsync(dto.BranchId);
            if (branch == null || !branch.IsActive || !branch.AcceptingOrders)
            {
                return ApiResponse<OrderCreatedDto>.ErrorResponse("Branch not available");
            }

            // Get menu items
            var menuItemIds = dto.Items.Select(i => i.MenuItemId).ToList();
            var menuItems = await _context.MenuItems
                .Include(i => i.AddOns)
                .Where(i => menuItemIds.Contains(i.Id))
                .ToDictionaryAsync(i => i.Id);

            // Validate all items exist and are available
            foreach (var item in dto.Items)
            {
                if (!menuItems.TryGetValue(item.MenuItemId, out var menuItem) || !menuItem.IsAvailable)
                {
                    return ApiResponse<OrderCreatedDto>.ErrorResponse($"Item {item.MenuItemId} is not available");
                }
            }

            // Generate order number
            var orderNumber = GenerateOrderNumber();

            // Create order
            var order = new Order
            {
                UserId = userId,
                BranchId = dto.BranchId,
                OrderNumber = orderNumber,
                OrderType = dto.OrderType,
                Status = OrderStatus.Pending,
                PaymentMethod = PaymentMethod.CashOnDelivery,
                PaymentStatus = PaymentStatus.Pending,
                DeliveryAddressLine = dto.DeliveryAddressLine,
                DeliveryLatitude = dto.DeliveryLatitude,
                DeliveryLongitude = dto.DeliveryLongitude,
                DeliveryNotes = dto.DeliveryNotes,
                RequestedDeliveryTime = dto.RequestedDeliveryTime,
                CustomerNotes = dto.CustomerNotes
            };

            decimal subTotal = 0;

            // Add order items
            foreach (var itemDto in dto.Items)
            {
                var menuItem = menuItems[itemDto.MenuItemId];
                var unitPrice = menuItem.DiscountedPrice ?? menuItem.Price;
                
                var orderItem = new OrderItem
                {
                    MenuItemId = itemDto.MenuItemId,
                    MenuItemNameAr = menuItem.NameAr,
                    MenuItemNameEn = menuItem.NameEn,
                    UnitPrice = unitPrice,
                    Quantity = itemDto.Quantity,
                    Notes = itemDto.Notes
                };

                decimal addOnsTotal = 0;

                // Add add-ons
                if (itemDto.AddOnIds?.Any() == true)
                {
                    foreach (var addOnId in itemDto.AddOnIds)
                    {
                        var addOn = menuItem.AddOns.FirstOrDefault(a => a.Id == addOnId && a.IsAvailable);
                        if (addOn != null)
                        {
                            orderItem.OrderItemAddOns.Add(new OrderItemAddOn
                            {
                                MenuItemAddOnId = addOn.Id,
                                NameAr = addOn.NameAr,
                                NameEn = addOn.NameEn,
                                Price = addOn.Price
                            });
                            addOnsTotal += addOn.Price;
                        }
                    }
                }

                orderItem.AddOnsTotal = addOnsTotal;
                orderItem.TotalPrice = (unitPrice + addOnsTotal) * itemDto.Quantity;
                subTotal += orderItem.TotalPrice;

                order.OrderItems.Add(orderItem);
            }

            order.SubTotal = subTotal;
            
            // Calculate delivery fee
            if (dto.OrderType == OrderType.Delivery)
            {
                order.DeliveryFee = subTotal >= branch.FreeDeliveryThreshold && branch.FreeDeliveryThreshold > 0
                    ? 0
                    : branch.DeliveryFee;
            }

            // Apply promo code if provided
            if (!string.IsNullOrWhiteSpace(dto.CouponCode))
            {
                var now = DateTime.UtcNow;
                var offer = await _context.Offers
                    .FirstOrDefaultAsync(o => o.Code.ToLower() == dto.CouponCode.ToLower());

                if (offer != null)
                {
                    // Validate offer
                    bool isValid = true;
                    string errorMessage = "";

                    if (!offer.IsActive)
                    {
                        isValid = false;
                        errorMessage = "This coupon is no longer active";
                    }
                    else if (now < offer.StartDate)
                    {
                        isValid = false;
                        errorMessage = "This coupon is not yet active";
                    }
                    else if (now > offer.EndDate)
                    {
                        isValid = false;
                        errorMessage = "This coupon has expired";
                    }
                    else if (offer.UsageLimit.HasValue && offer.UsageCount >= offer.UsageLimit.Value)
                    {
                        isValid = false;
                        errorMessage = "This coupon has reached its usage limit";
                    }
                    else if (offer.MinimumOrderAmount.HasValue && subTotal < offer.MinimumOrderAmount.Value)
                    {
                        isValid = false;
                        errorMessage = $"Minimum order amount for this coupon is {offer.MinimumOrderAmount.Value}";
                    }
                    else if (offer.BranchId.HasValue && offer.BranchId != dto.BranchId)
                    {
                        isValid = false;
                        errorMessage = "This coupon is not valid for the selected branch";
                    }

                    if (!isValid)
                    {
                        return ApiResponse<OrderCreatedDto>.ErrorResponse(errorMessage);
                    }

                    // Calculate discount
                    decimal discount = 0;
                    if (offer.Type == OfferType.Percentage)
                    {
                        discount = subTotal * (offer.Value / 100);
                        if (offer.MaximumDiscount.HasValue && discount > offer.MaximumDiscount.Value)
                        {
                            discount = offer.MaximumDiscount.Value;
                        }
                    }
                    else if (offer.Type == OfferType.FixedAmount)
                    {
                        discount = offer.Value;
                    }

                    order.Discount = discount;
                    order.CouponCode = dto.CouponCode;

                    // Increment usage count
                    offer.UsageCount++;
                }
                else
                {
                    return ApiResponse<OrderCreatedDto>.ErrorResponse("Invalid coupon code");
                }
            }

            // Validate minimum order
            if (subTotal < branch.MinOrderAmount)
            {
                return ApiResponse<OrderCreatedDto>.ErrorResponse(
                    $"Minimum order amount is {branch.MinOrderAmount}");
            }

            order.Total = order.SubTotal + order.DeliveryFee - order.Discount;
            order.EstimatedDeliveryTime = DateTime.UtcNow.AddMinutes(branch.DefaultPreparationTimeMinutes + 15);

            order.AddDomainEvent(new OrderCreatedEvent(order));

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();
            
            // Commit transaction before external calls
            await transaction.CommitAsync();

            return ApiResponse<OrderCreatedDto>.SuccessResponse(new OrderCreatedDto(
                order.Id,
                order.OrderNumber,
                order.Total,
                order.EstimatedDeliveryTime.Value
            ));
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Error creating order for user {UserId}", userId);
            return ApiResponse<OrderCreatedDto>.ErrorResponse("Failed to create order. Please try again.");
        }
    }

    public async Task<ApiResponse<OrderCreatedDto>> ReorderAsync(int userId, int orderId)
    {
        // Get the original order
        var order = await _context.Orders
            .Include(o => o.OrderItems)
                .ThenInclude(i => i.OrderItemAddOns)
            .Include(o => o.Branch)
            .Include(o => o.Delivery)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);

        if (order == null)
        {
            return ApiResponse<OrderCreatedDto>.ErrorResponse("Order not found");
        }

        // Only allow reordering of delivered orders
        if (order.Status != OrderStatus.Delivered)
        {
            return ApiResponse<OrderCreatedDto>.ErrorResponse("Can only reorder delivered orders");
        }

        // Create DTO from original order
        var createOrderDto = new CreateOrderDto(
            order.BranchId,
            order.OrderType,
            null, // AddressId
            order.DeliveryAddressLine,
            order.DeliveryLatitude,
            order.DeliveryLongitude,
            null, // DeliveryNotes
            null, // RequestedDeliveryTime
            null, // CustomerNotes
            null, // CouponCode - don't reuse coupon
            order.OrderItems.Select(item => new CreateOrderItemDto(
                item.MenuItemId,
                item.Quantity,
                item.Notes,
                item.OrderItemAddOns.Select(a => a.MenuItemAddOnId).ToList()
            )).ToList()
        );

        // Create the new order using existing logic
        return await CreateOrderAsync(userId, createOrderDto);
    }

    private static string GenerateOrderNumber()
    {
        return $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6].ToUpper()}";
    }
}
