using RestaurantApp.Domain.Entities;

namespace RestaurantApp.Application.Interfaces;

public interface IOrderRepository : IRepository<Order>
{
    Task<Order?> GetByOrderNumberAsync(string orderNumber);
    Task<IEnumerable<Order>> GetUserOrdersAsync(int userId, int count = 10);
}
