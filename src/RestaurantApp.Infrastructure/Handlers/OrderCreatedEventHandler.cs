using Hangfire;
using MediatR;
using Microsoft.Extensions.Logging;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Events;
using RestaurantApp.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace RestaurantApp.Infrastructure.Handlers;

public class OrderCreatedEventHandler : INotificationHandler<OrderCreatedEvent>
{
    private readonly IEmailService _emailService;
    private readonly IOrderNotificationService _notificationService;
    private readonly ILogger<OrderCreatedEventHandler> _logger;
    private readonly IBackgroundJobClient _backgroundJobs;
    private readonly ApplicationDbContext _context;

    public OrderCreatedEventHandler(
        IEmailService emailService,
        IOrderNotificationService notificationService,
        ILogger<OrderCreatedEventHandler> logger,
        IBackgroundJobClient backgroundJobs,
        ApplicationDbContext context)
    {
        _emailService = emailService;
        _notificationService = notificationService;
        _logger = logger;
        _backgroundJobs = backgroundJobs;
        _context = context;
    }

    public async Task Handle(OrderCreatedEvent notification, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Handling OrderCreatedEvent for Order ID: {OrderId}", notification.Order.Id);

        var order = notification.Order;
        
        try 
        {
            // Fetch User info if not loaded
            var user = order.User;
            if (user == null)
            {
                user = await _context.Users.FindAsync(order.UserId);
            }

            // Real-time notification to Dashboard
            await _notificationService.NotifyNewOrder(
                order.Id,
                order.OrderNumber,
                user?.FullName ?? "Customer",
                order.OrderItems.Sum(i => i.Quantity),
                order.Total,
                order.OrderType);

            // Enqueue background email job
            if (user?.Email != null)
            {
                _backgroundJobs.Enqueue(() => _emailService.SendOrderConfirmationAsync(user.Email, order.OrderNumber, order.Total));
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing OrderCreatedEvent for order {OrderNumber}", order.OrderNumber);
        }
    }
}
