using RestaurantApp.Application.Common;
using RestaurantApp.Domain.Enums;

namespace RestaurantApp.Application.Interfaces;

public interface IOrderLifecycleService
{
    Task<ApiResponse> CancelOrderAsync(int userId, int orderId, string reason);
    Task<ApiResponse> UpdateOrderStatusAsync(int orderId, OrderStatus newStatus);
}
