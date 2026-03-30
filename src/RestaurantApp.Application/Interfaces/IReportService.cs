using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Report;

namespace RestaurantApp.Application.Interfaces;

public interface IReportService
{
    Task<ApiResponse<BusinessSummaryDto>> GetBusinessSummaryAsync(DateTime? fromDate = null, DateTime? toDate = null);
    
    Task<ApiResponse<List<RevenueReportDto>>> GetRevenueReportAsync(
        DateTime? fromDate,
        DateTime? toDate,
        string groupBy = "day");
    
    Task<ApiResponse<OrderReportDto>> GetOrderReportAsync(
        DateTime? fromDate,
        DateTime? toDate,
        string? status = null,
        int? branchId = null);
    
    Task<ApiResponse<List<PopularItemReportDto>>> GetPopularItemsReportAsync(
        DateTime? fromDate,
        DateTime? toDate,
        int limit = 10);
    
    Task<ApiResponse<List<BranchPerformanceDto>>> GetBranchPerformanceReportAsync(
        DateTime? fromDate,
        DateTime? toDate,
        int? branchId = null);
}



