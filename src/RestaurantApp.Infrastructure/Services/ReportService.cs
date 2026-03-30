using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Report;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Enums;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.Infrastructure.Services;

public class ReportService : IReportService
{
    private readonly ApplicationDbContext _context;

    public ReportService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ApiResponse<BusinessSummaryDto>> GetBusinessSummaryAsync(DateTime? fromDate = null, DateTime? toDate = null)
    {
        var now = DateTime.UtcNow;
        var todayStart = new DateTime(now.Year, now.Month, now.Day, 0, 0, 0, DateTimeKind.Utc);
        
        fromDate ??= todayStart.AddMonths(-1);
        toDate ??= now;

        var ordersQuery = _context.Orders
            .Where(o => o.CreatedAt >= fromDate && o.CreatedAt <= toDate);

        var todayOrdersQuery = _context.Orders
            .Where(o => o.CreatedAt >= todayStart);

        var totalRevenue = await ordersQuery
            .Where(o => o.Status != OrderStatus.Cancelled)
            .SumAsync(o => o.Total);

        var totalOrders = await ordersQuery.CountAsync();
        
        var totalCustomers = await _context.Users
            .Where(u => u.CreatedAt >= fromDate && u.CreatedAt <= toDate)
            .CountAsync();

        var averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

        var pendingOrders = await ordersQuery.CountAsync(o => o.Status == OrderStatus.Pending);
        
        var activeCustomers = await _context.Users
            .Where(u => u.IsActive)
            .CountAsync();

        var todayRevenue = await todayOrdersQuery
            .Where(o => o.Status != OrderStatus.Cancelled)
            .SumAsync(o => o.Total);

        var todayOrders = await todayOrdersQuery.CountAsync();

        var summary = new BusinessSummaryDto(
            totalRevenue,
            totalOrders,
            totalCustomers,
            averageOrderValue,
            pendingOrders,
            activeCustomers,
            todayRevenue,
            todayOrders
        );

        return ApiResponse<BusinessSummaryDto>.SuccessResponse(summary);
    }

    public async Task<ApiResponse<List<RevenueReportDto>>> GetRevenueReportAsync(
        DateTime? fromDate,
        DateTime? toDate,
        string groupBy = "day")
    {
        fromDate ??= DateTime.UtcNow.AddMonths(-1);
        toDate ??= DateTime.UtcNow;

        var orders = await _context.Orders
            .Where(o => o.CreatedAt >= fromDate && o.CreatedAt <= toDate)
            .Where(o => o.Status != OrderStatus.Cancelled)
            .ToListAsync();

        var grouped = groupBy.ToLower() switch
        {
            "day" => orders.GroupBy(o => o.CreatedAt.Date),
            "week" => orders.GroupBy(o => GetWeekStart(o.CreatedAt)),
            "month" => orders.GroupBy(o => new DateTime(o.CreatedAt.Year, o.CreatedAt.Month, 1)),
            _ => orders.GroupBy(o => o.CreatedAt.Date)
        };

        var report = grouped.Select(g => new RevenueReportDto(
            FormatPeriod(g.Key, groupBy),
            g.Key,
            GetPeriodEnd(g.Key, groupBy),
            g.Sum(o => o.Total),
            g.Count(),
            g.Average(o => o.Total)
        )).OrderBy(r => r.PeriodStart).ToList();

        return ApiResponse<List<RevenueReportDto>>.SuccessResponse(report);
    }

    public async Task<ApiResponse<OrderReportDto>> GetOrderReportAsync(
        DateTime? fromDate,
        DateTime? toDate,
        string? status = null,
        int? branchId = null)
    {
        fromDate ??= DateTime.UtcNow.AddMonths(-1);
        toDate ??= DateTime.UtcNow;

        var query = _context.Orders
            .Where(o => o.CreatedAt >= fromDate && o.CreatedAt <= toDate);

        if (branchId.HasValue)
            query = query.Where(o => o.BranchId == branchId.Value);

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<OrderStatus>(status, out var orderStatus))
            query = query.Where(o => o.Status == orderStatus);

        var orders = await query.ToListAsync();

        var totalOrders = orders.Count;
        var pendingOrders = orders.Count(o => o.Status == OrderStatus.Pending);
        var confirmedOrders = orders.Count(o => o.Status == OrderStatus.Confirmed);
        var preparingOrders = orders.Count(o => o.Status == OrderStatus.Preparing);
        var readyOrders = orders.Count(o => o.Status == OrderStatus.Ready);
        var outForDeliveryOrders = orders.Count(o => o.Status == OrderStatus.OutForDelivery);
        var deliveredOrders = orders.Count(o => o.Status == OrderStatus.Delivered);
        var cancelledOrders = orders.Count(o => o.Status == OrderStatus.Cancelled);

        var totalRevenue = orders
            .Where(o => o.Status != OrderStatus.Cancelled)
            .Sum(o => o.Total);

        var averageOrderValue = orders.Count > 0 ? totalRevenue / orders.Count : 0;

        var trends = orders
            .GroupBy(o => o.CreatedAt.Date)
            .Select(g => new OrderTrendDto(
                g.Key,
                g.Count(),
                g.Where(o => o.Status != OrderStatus.Cancelled).Sum(o => o.Total)
            ))
            .OrderBy(t => t.Date)
            .ToList();

        var report = new OrderReportDto(
            totalOrders,
            pendingOrders,
            confirmedOrders,
            preparingOrders,
            readyOrders,
            outForDeliveryOrders,
            deliveredOrders,
            cancelledOrders,
            totalRevenue,
            averageOrderValue,
            trends
        );

        return ApiResponse<OrderReportDto>.SuccessResponse(report);
    }

    public async Task<ApiResponse<List<PopularItemReportDto>>> GetPopularItemsReportAsync(
        DateTime? fromDate,
        DateTime? toDate,
        int limit = 10)
    {
        fromDate ??= DateTime.UtcNow.AddMonths(-1);
        toDate ??= DateTime.UtcNow;

        var popularItems = await _context.OrderItems
            .Include(oi => oi.Order)
            .Include(oi => oi.MenuItem)
            .Where(oi => oi.Order.CreatedAt >= fromDate && oi.Order.CreatedAt <= toDate)
            .Where(oi => oi.Order.Status != OrderStatus.Cancelled)
            .GroupBy(oi => new { oi.MenuItemId, oi.MenuItemNameEn, oi.MenuItemNameAr })
            .Select(g => new PopularItemReportDto(
                g.Key.MenuItemId,
                g.Key.MenuItemNameEn ?? "",
                g.Key.MenuItemNameAr ?? "",
                g.Sum(oi => oi.Quantity),
                g.Sum(oi => oi.TotalPrice),
                g.Average(oi => oi.UnitPrice)
            ))
            .OrderByDescending(p => p.QuantitySold)
            .Take(limit)
            .ToListAsync();

        return ApiResponse<List<PopularItemReportDto>>.SuccessResponse(popularItems);
    }

    public async Task<ApiResponse<List<BranchPerformanceDto>>> GetBranchPerformanceReportAsync(
        DateTime? fromDate,
        DateTime? toDate,
        int? branchId = null)
    {
        fromDate ??= DateTime.UtcNow.AddMonths(-1);
        toDate ??= DateTime.UtcNow;

        var query = _context.Orders
            .Include(o => o.Branch)
            .Where(o => o.CreatedAt >= fromDate && o.CreatedAt <= toDate);

        if (branchId.HasValue)
            query = query.Where(o => o.BranchId == branchId.Value);

        var branchStats = await query
            .GroupBy(o => new { o.BranchId, o.Branch.NameEn, o.Branch.NameAr })
            .Select(g => new BranchPerformanceDto(
                g.Key.BranchId,
                g.Key.NameEn ?? "",
                g.Key.NameAr ?? "",
                g.Count(),
                g.Where(o => o.Status != OrderStatus.Cancelled).Sum(o => o.Total),
                g.Where(o => o.Status != OrderStatus.Cancelled).Average(o => o.Total),
                g.Count(o => o.Status == OrderStatus.Delivered),
                g.Count(o => o.Status == OrderStatus.Cancelled)
            ))
            .OrderByDescending(b => b.Revenue)
            .ToListAsync();

        return ApiResponse<List<BranchPerformanceDto>>.SuccessResponse(branchStats);
    }

    private DateTime GetWeekStart(DateTime date)
    {
        var diff = (7 + (date.DayOfWeek - DayOfWeek.Sunday)) % 7;
        return date.AddDays(-1 * diff).Date;
    }

    private string FormatPeriod(DateTime date, string groupBy)
    {
        return groupBy.ToLower() switch
        {
            "day" => date.ToString("yyyy-MM-dd"),
            "week" => $"Week {GetWeekNumber(date)}",
            "month" => date.ToString("yyyy-MM"),
            _ => date.ToString("yyyy-MM-dd")
        };
    }

    private DateTime GetPeriodEnd(DateTime date, string groupBy)
    {
        return groupBy.ToLower() switch
        {
            "day" => date.AddDays(1),
            "week" => date.AddDays(7),
            "month" => date.AddMonths(1),
            _ => date.AddDays(1)
        };
    }

    private int GetWeekNumber(DateTime date)
    {
        var startOfYear = new DateTime(date.Year, 1, 1);
        var days = (date - startOfYear).Days;
        return (days / 7) + 1;
    }
}



