using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Domain.Enums;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.Infrastructure.Services.Orders;

public class OrderLifecycleService : IOrderLifecycleService
{
    private readonly ApplicationDbContext _context;
    private readonly IEmailService _emailService;
    private readonly ILoyaltyService _loyaltyService;
    private readonly IOrderNotificationService _notificationService;
    private readonly ILogger<OrderLifecycleService> _logger;

    public OrderLifecycleService(
        ApplicationDbContext context,
        IEmailService emailService,
        ILoyaltyService loyaltyService,
        IOrderNotificationService notificationService,
        ILogger<OrderLifecycleService> logger)
    {
        _context = context;
        _emailService = emailService;
        _loyaltyService = loyaltyService;
        _notificationService = notificationService;
        _logger = logger;
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
}
