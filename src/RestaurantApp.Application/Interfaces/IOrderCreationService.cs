using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Order;

namespace RestaurantApp.Application.Interfaces;

public interface IOrderCreationService
{
    Task<ApiResponse<OrderCreatedDto>> CreateOrderAsync(int userId, CreateOrderDto dto);
    Task<ApiResponse<OrderCreatedDto>> ReorderAsync(int userId, int orderId);
}
