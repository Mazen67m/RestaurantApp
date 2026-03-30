using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.User;

namespace RestaurantApp.Application.Interfaces;

public interface IAuditService
{
    Task LogActionAsync(int? userId, string userEmail, string action, string entityName, string entityId, string? oldValues = null, string? newValues = null);
    Task<ApiResponse<PagedResponse<AuditLogDto>>> GetAuditLogsAsync(int page = 1, int pageSize = 20, string? userEmail = null, string? action = null);
}

public record AuditLogDto(
    int Id,
    int? UserId,
    string UserEmail,
    string Action,
    string EntityName,
    string EntityId,
    string? OldValues,
    string? NewValues,
    string IpAddress,
    DateTime Timestamp,
    string? CorrelationId
);
