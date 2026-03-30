using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestaurantApp.Application.DTOs.Report;
using RestaurantApp.Application.Interfaces;

namespace RestaurantApp.API.Controllers;

[ApiController]
[Route("api/admin/reports")]
[Authorize(Roles = "Admin")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null)
    {
        var result = await _reportService.GetBusinessSummaryAsync(fromDate, toDate);
        return Ok(result);
    }

    [HttpGet("revenue")]
    public async Task<IActionResult> GetRevenue(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null,
        [FromQuery] string groupBy = "day")
    {
        var result = await _reportService.GetRevenueReportAsync(fromDate, toDate, groupBy);
        return Ok(result);
    }

    [HttpGet("orders")]
    public async Task<IActionResult> GetOrders(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null,
        [FromQuery] string? status = null,
        [FromQuery] int? branchId = null)
    {
        var result = await _reportService.GetOrderReportAsync(fromDate, toDate, status, branchId);
        return Ok(result);
    }

    [HttpGet("popular-items")]
    public async Task<IActionResult> GetPopularItems(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null,
        [FromQuery] int limit = 10)
    {
        var result = await _reportService.GetPopularItemsReportAsync(fromDate, toDate, limit);
        return Ok(result);
    }

    [HttpGet("branch-performance")]
    public async Task<IActionResult> GetBranchPerformance(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null,
        [FromQuery] int? branchId = null)
    {
        var result = await _reportService.GetBranchPerformanceReportAsync(fromDate, toDate, branchId);
        return Ok(result);
    }
}



