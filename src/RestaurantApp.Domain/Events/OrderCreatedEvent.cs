using RestaurantApp.Domain.Common;
using RestaurantApp.Domain.Entities;

namespace RestaurantApp.Domain.Events;

public class OrderCreatedEvent : IDomainEvent
{
    public Order Order { get; }

    public OrderCreatedEvent(Order order)
    {
        Order = order;
    }
}
