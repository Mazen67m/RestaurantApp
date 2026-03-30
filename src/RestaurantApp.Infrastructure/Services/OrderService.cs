using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Order;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Enums;

namespace RestaurantApp.Infrastructure.Services;

/// <summary>
/// Facade service that delegates to specialized order services.
/// Keeps the original IOrderService interface for backward compatibility.
/// </summary>
public class OrderService : IOrderService
{
    private readonly IOrderCreationService _creationService;
    private readonly IOrderQueryService _queryService;
    private readonly IOrderLifecycleService _lifecycleService;

    public OrderService(
        IOrderCreationService creationService,
        IOrderQueryService queryService,
        IOrderLifecycleService lifecycleService)
    {
        _creationService = creationService;
        _queryService = queryService;
        _lifecycleService = lifecycleService;
    }

    // Customer operations
    public Task<ApiResponse<OrderCreatedDto>> CreateOrderAsync(int userId, CreateOrderDto dto)
    {
        return _creationService.CreateOrderAsync(userId, dto);
    }

    public Task<ApiResponse<List<OrderSummaryDto>>> GetUserOrdersAsync(int userId, int page = 1, int pageSize = 10)
    {
        return _queryService.GetUserOrdersAsync(userId, page, pageSize);
    }

    public Task<ApiResponse<OrderDto>> GetOrderAsync(int userId, int orderId)
    {
        return _queryService.GetOrderAsync(userId, orderId);
    }

    public Task<ApiResponse<OrderTrackingDto>> GetOrderTrackingAsync(int userId, int orderId)
    {
        return _queryService.GetOrderTrackingAsync(userId, orderId);
    }

    public Task<ApiResponse> CancelOrderAsync(int userId, int orderId, string reason)
    {
        return _lifecycleService.CancelOrderAsync(userId, orderId, reason);
    }

    public Task<ApiResponse<OrderCreatedDto>> ReorderAsync(int userId, int orderId)
    {
        return _creationService.ReorderAsync(userId, orderId);
    }

    // Admin/Cashier operations
    public Task<ApiResponse<PagedResponse<OrderSummaryDto>>> GetOrdersAsync(
        int? branchId = null,
        OrderStatus? status = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 20)
    {
        return _queryService.GetOrdersAsync(branchId, status, fromDate, toDate, page, pageSize);
    }

    public Task<ApiResponse<OrderDto>> GetOrderDetailsAsync(int orderId)
    {
        return _queryService.GetOrderDetailsAsync(orderId);
    }

    public Task<ApiResponse> UpdateOrderStatusAsync(int orderId, OrderStatus newStatus)
    {
        return _lifecycleService.UpdateOrderStatusAsync(orderId, newStatus);
    }
}
