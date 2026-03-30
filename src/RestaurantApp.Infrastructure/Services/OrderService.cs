using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Order;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Domain.Enums;
using Microsoft.Extensions.Logging;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.Infrastructure.Services;

public class OrderService : IOrderService
{
    private readonly ApplicationDbContext _context;
    private readonly IEmailService _emailService;
    private readonly ILoyaltyService _loyaltyService;
    private readonly IOrderNotificationService _notificationService;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        ApplicationDbContext context, 
        IEmailService emailService,
        ILoyaltyService loyaltyService,
        IOrderNotificationService notificationService,
        ILogger<OrderService> logger)
    {
        _context = context;
        _emailService = emailService;
        _loyaltyService = loyaltyService;
        _notificationService = notificationService;
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

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();
        
        // Commit transaction before external calls
        await transaction.CommitAsync();

        // Send confirmation email (fire and forget - outside transaction)
        var user = await _context.Users.FindAsync(userId);
        if (user?.Email != null)
        {
            _ = Task.Run(async () => 
            {
                try
                {
                    await _emailService.SendOrderConfirmationAsync(user.Email, order.OrderNumber, order.Total);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send order confirmation email for order {OrderId}", order.Id);
                }
            });
        }
        // Send real-time notification to Admin Dashboard
        await _notificationService.NotifyNewOrder(
            order.Id, 
            order.OrderNumber, 
            user?.FullName ?? "Customer", 
            order.OrderItems.Sum(i => i.Quantity), 
            order.Total, 
            order.OrderType);

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

    public async Task<ApiResponse<List<OrderSummaryDto>>> GetUserOrdersAsync(int userId, int page = 1, int pageSize = 10)
    {
        var orders = await _context.Orders
            .AsNoTracking()
            .Include(o => o.OrderItems)
            .Include(o => o.Branch)
            .Include(o => o.User)
            .Where(o => o.UserId == userId)
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var dtos = orders.Select(o => new OrderSummaryDto(
            o.Id,
            o.OrderNumber,
            o.Status,
            o.Total,
            o.OrderItems.Sum(i => i.Quantity),
            o.CreatedAt,
            o.Branch.NameAr,
            o.Branch.NameEn,
            o.User.FullName,
            o.User.PhoneNumber ?? ""
        )).ToList();

        return ApiResponse<List<OrderSummaryDto>>.SuccessResponse(dtos);
    }

    public async Task<ApiResponse<OrderDto>> GetOrderAsync(int userId, int orderId)
    {
        var order = await _context.Orders
            .AsNoTracking()
            .Include(o => o.Branch)
            .Include(o => o.OrderItems)
                .ThenInclude(i => i.OrderItemAddOns)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);

        if (order == null)
        {
            return ApiResponse<OrderDto>.ErrorResponse("Order not found");
        }

        return ApiResponse<OrderDto>.SuccessResponse(MapToOrderDto(order));
    }

    public async Task<ApiResponse<OrderTrackingDto>> GetOrderTrackingAsync(int userId, int orderId)
    {
        var order = await _context.Orders
            .AsNoTracking()
            .FirstOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);

        if (order == null)
        {
            return ApiResponse<OrderTrackingDto>.ErrorResponse("Order not found");
        }

        // Get real status history from database
        var historyRecords = await _context.OrderStatusHistories
            .AsNoTracking()
            .Where(h => h.OrderId == orderId)
            .OrderBy(h => h.CreatedAt)
            .ToListAsync();

        // Build status history from real records
        var statusHistory = new List<OrderStatusHistoryDto>();
        
        // Always include the initial Pending status (order creation)
        statusHistory.Add(new OrderStatusHistoryDto(OrderStatus.Pending, order.CreatedAt));
        
        // Add all recorded status changes
        foreach (var record in historyRecords)
        {
            statusHistory.Add(new OrderStatusHistoryDto(record.NewStatus, record.CreatedAt));
        }

        return ApiResponse<OrderTrackingDto>.SuccessResponse(new OrderTrackingDto(
            order.OrderNumber,
            order.Status,
            order.EstimatedDeliveryTime,
            statusHistory
        ));
    }

    public async Task<ApiResponse> CancelOrderAsync(int userId, int orderId, string reason)
    {
        var order = await _context.Orders
            .FirstOrDefaultAsync(o => o.Id == orderId && o.UserId == userId);

        if (order == null)
        {
            return ApiResponse.ErrorResponse("Order not found");
        }

        if (order.Status > OrderStatus.Confirmed)
        {
            return ApiResponse.ErrorResponse("Order cannot be cancelled at this stage");
        }

        order.Status = OrderStatus.Cancelled;
        order.CancellationReason = reason;
        await _context.SaveChangesAsync();

        return ApiResponse.SuccessResponse("Order cancelled");
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

    // Admin operations
    public async Task<ApiResponse<PagedResponse<OrderSummaryDto>>> GetOrdersAsync(
        int? branchId = null,
        OrderStatus? status = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 20)
    {
        var query = _context.Orders
            .AsNoTracking()
            .Include(o => o.OrderItems)
                .ThenInclude(i => i.OrderItemAddOns)
            .Include(o => o.Branch)
            .Include(o => o.User)
            .Include(o => o.Delivery)`r`n            .AsSplitQuery() // Performance optimization for complex includes`r`n            .AsQueryable();

        if (branchId.HasValue)
            query = query.Where(o => o.BranchId == branchId.Value);
        if (status.HasValue)
            query = query.Where(o => o.Status == status.Value);
        if (fromDate.HasValue)
            query = query.Where(o => o.CreatedAt >= fromDate.Value);
        if (toDate.HasValue)
            query = query.Where(o => o.CreatedAt <= toDate.Value);

        var totalCount = await query.CountAsync();

        var orders = await query
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
             .ToListAsync();

        var dtos = orders.Select(o => new OrderSummaryDto(
            o.Id,
            o.OrderNumber,
            o.Status,
            o.Total,
            o.OrderItems.Sum(i => i.Quantity),
            o.CreatedAt,
            o.Branch.NameAr,
            o.Branch.NameEn,
            o.User.FullName,
            o.User.PhoneNumber ?? "",
            o.Delivery?.NameEn,
            o.OrderItems.Select(i => new OrderItemSummaryDto(
                i.MenuItemNameAr,
                i.MenuItemNameEn,
                i.Quantity,
                i.Notes,
                i.OrderItemAddOns.Select(a => new OrderItemAddOnSummaryDto(a.NameAr, a.NameEn)).ToList()
            )).ToList()
        )).ToList();

        return ApiResponse<PagedResponse<OrderSummaryDto>>.SuccessResponse(new PagedResponse<OrderSummaryDto>
        {
            Items = dtos,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        });
    }

    public async Task<ApiResponse<OrderDto>> GetOrderDetailsAsync(int orderId)
    {
        var order = await _context.Orders
            .AsNoTracking()
            .Include(o => o.Branch)
            .Include(o => o.Delivery)
            .Include(o => o.OrderItems)
                .ThenInclude(i => i.OrderItemAddOns)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            return ApiResponse<OrderDto>.ErrorResponse("Order not found");
        }

        return ApiResponse<OrderDto>.SuccessResponse(MapToOrderDto(order));
    }

    public async Task<ApiResponse> UpdateOrderStatusAsync(int orderId, OrderStatus newStatus)
    {
        var order = await _context.Orders.FindAsync(orderId);
        if (order == null)
        {
            return ApiResponse.ErrorResponse("Order not found");
        }

        var previousStatus = order.Status;

        // Only record history if status actually changed
        if (previousStatus != newStatus)
        {
            // Record status change in history
            var statusHistory = new OrderStatusHistory
            {
                OrderId = orderId,
                PreviousStatus = previousStatus,
                NewStatus = newStatus,
                ChangedBy = "Admin", // TODO: Get actual user from HttpContext
                Notes = null
            };

            _context.OrderStatusHistories.Add(statusHistory);

            // Update order status
            order.Status = newStatus;

            if (newStatus == OrderStatus.Delivered)
            {
                order.ActualDeliveryTime = DateTime.UtcNow;
                order.PaymentStatus = PaymentStatus.Paid;

                // Make driver available again - removed as drivers can take multiple orders
            }

            await _context.SaveChangesAsync();

            // Award loyalty points AFTER saving the main order changes
            if (newStatus == OrderStatus.Delivered)
            {
                try
                {
                    await _loyaltyService.AwardPointsAsync(
                        order.UserId.ToString(),
                        order.Id,
                        order.Total);
                }
                catch (Exception ex)
                {
                    // Log error but don't fail the status update
                    _logger.LogError(ex, "Failed to award loyalty points for order {OrderId}", order.Id);
                }
            }

            // Send real-time notification
            try
            {
                await _notificationService.NotifyStatusUpdate(
                    orderId,
                    order.UserId.ToString(),
                    newStatus);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send notification for order {OrderId}", order.Id);
            }

            // Send status update email
            try
            {
                var user = await _context.Users.FindAsync(order.UserId);
                if (user?.Email != null)
                {
                    await _emailService.SendOrderStatusUpdateAsync(user.Email, order.OrderNumber, newStatus.ToString());
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email for order {OrderId}", order.Id);
            }
        }

        return ApiResponse.SuccessResponse("Order status updated");
    }

    private static string GenerateOrderNumber()
    {
        return $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..6].ToUpper()}";
    }

    private static OrderDto MapToOrderDto(Order order)
    {
        return new OrderDto(
            order.Id,
            order.OrderNumber,
            order.OrderType,
            order.Status,
            order.PaymentMethod,
            order.PaymentStatus,
            order.SubTotal,
            order.DeliveryFee,
            order.Discount,
            order.Total,
            order.DeliveryAddressLine,
            order.CustomerNotes,
            order.RequestedDeliveryTime,
            order.EstimatedDeliveryTime,
            order.CreatedAt,
            new BranchOrderInfo(order.Branch.Id, order.Branch.NameAr, order.Branch.NameEn, order.Branch.Phone),
            order.OrderItems.Select(i => new OrderItemDto(
                i.Id,
                i.MenuItemId,
                i.MenuItemNameAr,
                i.MenuItemNameEn,
                i.UnitPrice,
                i.Quantity,
                i.AddOnsTotal,
                i.TotalPrice,
                i.Notes,
                i.OrderItemAddOns.Select(a => new OrderItemAddOnDto(
                    a.Id,
                    a.NameAr,
                    a.NameEn,
                    a.Price
                )).ToList()
            )).ToList(),
            order.Delivery?.NameEn
        );
    }
}
