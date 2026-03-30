using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Order;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Domain.Enums;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.Infrastructure.Services.Orders;

public class OrderQueryService : IOrderQueryService
{
    private readonly ApplicationDbContext _context;

    public OrderQueryService(ApplicationDbContext context)
    {
        _context = context;
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
            .AsSplitQuery()
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
            .AsSplitQuery()
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
            .Include(o => o.Delivery)
            .AsSplitQuery() // Performance optimization for complex includes
            .AsQueryable();

        if (branchId.HasValue)
            query = query.Where(o => o.BranchId == branchId.Value);
        if (status.HasValue)
            query = query.Where(o => o.Status == status.Value);
        if (fromDate.HasValue)
            query = query.Where(o => o.CreatedAt >= fromDate.Value);
        if (toDate.HasValue)
            query = query.Where(o => o.CreatedAt <= toDate.Value);

        var totalCount = await query.CountAsync();

        var dtos = await query
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(o => new OrderSummaryDto(
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
                o.Delivery != null ? o.Delivery.NameEn : null,
                o.OrderItems.Select(i => new OrderItemSummaryDto(
                    i.MenuItemNameAr,
                    i.MenuItemNameEn,
                    i.Quantity,
                    i.Notes,
                    i.OrderItemAddOns.Select(a => new OrderItemAddOnSummaryDto(a.NameAr, a.NameEn)).ToList()
                )).ToList()
            ))
            .ToListAsync();

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
            .AsSplitQuery()
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            return ApiResponse<OrderDto>.ErrorResponse("Order not found");
        }

        return ApiResponse<OrderDto>.SuccessResponse(MapToOrderDto(order));
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
