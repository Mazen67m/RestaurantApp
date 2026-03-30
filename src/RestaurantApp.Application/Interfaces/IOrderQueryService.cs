using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Order;
using RestaurantApp.Domain.Enums;

namespace RestaurantApp.Application.Interfaces;

public interface IOrderQueryService
{
    // Customer query operations
    Task<ApiResponse<List<OrderSummaryDto>>> GetUserOrdersAsync(int userId, int page = 1, int pageSize = 10);
    Task<ApiResponse<OrderDto>> GetOrderAsync(int userId, int orderId);
    Task<ApiResponse<OrderTrackingDto>> GetOrderTrackingAsync(int userId, int orderId);

    // Admin query operations
    Task<ApiResponse<PagedResponse<OrderSummaryDto>>> GetOrdersAsync(
        int? branchId = null,
        OrderStatus? status = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 20);
    Task<ApiResponse<OrderDto>> GetOrderDetailsAsync(int orderId);
}
