using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.User;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.Infrastructure.Services;

public class AuditService : IAuditService
{
    private readonly ApplicationDbContext _context;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuditService(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor)
    {
        _context = context;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task LogActionAsync(int? userId, string userEmail, string action, string entityName, string entityId, string? oldValues = null, string? newValues = null)
    {
        var httpContext = _httpContextAccessor.HttpContext;
        var ipAddress = httpContext?.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var correlationId = httpContext?.Items["CorrelationId"]?.ToString();

        var log = new AuditLog
        {
            UserId = userId,
            UserEmail = userEmail,
            Action = action,
            EntityName = entityName,
            EntityId = entityId,
            OldValues = oldValues ?? string.Empty,
            NewValues = newValues ?? string.Empty,
            IpAddress = ipAddress,
            Timestamp = DateTime.UtcNow,
            CorrelationId = correlationId
        };

        _context.AuditLogs.Add(log);
        await _context.SaveChangesAsync();
    }

    public async Task<ApiResponse<PagedResponse<AuditLogDto>>> GetAuditLogsAsync(int page = 1, int pageSize = 20, string? userEmail = null, string? action = null)
    {
        var query = _context.AuditLogs.AsQueryable();

        if (!string.IsNullOrEmpty(userEmail))
        {
            query = query.Where(l => l.UserEmail.Contains(userEmail));
        }

        if (!string.IsNullOrEmpty(action))
        {
            query = query.Where(l => l.Action == action);
        }

        var totalCount = await query.CountAsync();
        var logs = await query
            .OrderByDescending(l => l.Timestamp)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(l => new AuditLogDto(
                l.Id,
                l.UserId,
                l.UserEmail,
                l.Action,
                l.EntityName,
                l.EntityId,
                l.OldValues,
                l.NewValues,
                l.IpAddress,
                l.Timestamp,
                l.CorrelationId
            ))
            .ToListAsync();

        var pagedResponse = new PagedResponse<AuditLogDto>
        {
            Items = logs,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };

        return ApiResponse<PagedResponse<AuditLogDto>>.SuccessResponse(pagedResponse);
    }
}
