using System.Net.Http.Json;
using System.Text.Json;

namespace RestaurantApp.Web.Services;

public class ReportApiService
{
    private readonly HttpClient _httpClient;

    public ReportApiService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<BusinessSummaryDto?> GetSummaryAsync(DateTime? fromDate = null, DateTime? toDate = null)
    {
        try
        {
            var queryParams = new List<string>();
            if (fromDate.HasValue) queryParams.Add($"fromDate={fromDate:yyyy-MM-dd}");
            if (toDate.HasValue) queryParams.Add($"toDate={toDate:yyyy-MM-dd}");

            var queryString = queryParams.Any() ? "?" + string.Join("&", queryParams) : "";
            var response = await _httpClient.GetAsync($"/api/admin/reports/summary{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var jsonResponse = await response.Content.ReadFromJsonAsync<JsonElement>();

                if (jsonResponse.ValueKind == JsonValueKind.Object &&
                    jsonResponse.TryGetProperty("data", out var dataProperty))
                {
                    return JsonSerializer.Deserialize<BusinessSummaryDto>(dataProperty.GetRawText());
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching summary: {ex.Message}");
        }

        return null;
    }

    public async Task<List<RevenueReportDto>> GetRevenueReportAsync(DateTime? fromDate = null, DateTime? toDate = null, string groupBy = "day")
    {
        try
        {
            var queryParams = new List<string> { $"groupBy={groupBy}" };
            if (fromDate.HasValue) queryParams.Add($"fromDate={fromDate:yyyy-MM-dd}");
            if (toDate.HasValue) queryParams.Add($"toDate={toDate:yyyy-MM-dd}");

            var queryString = "?" + string.Join("&", queryParams);
            var response = await _httpClient.GetAsync($"/api/admin/reports/revenue{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var jsonResponse = await response.Content.ReadFromJsonAsync<JsonElement>();

                if (jsonResponse.ValueKind == JsonValueKind.Object &&
                    jsonResponse.TryGetProperty("data", out var dataProperty))
                {
                    var revenue = JsonSerializer.Deserialize<List<RevenueReportDto>>(dataProperty.GetRawText());
                    return revenue ?? new List<RevenueReportDto>();
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching revenue report: {ex.Message}");
        }

        return new List<RevenueReportDto>();
    }

    public async Task<OrderReportDto?> GetOrderReportAsync(DateTime? fromDate = null, DateTime? toDate = null, string? status = null, int? branchId = null)
    {
        try
        {
            var queryParams = new List<string>();
            if (fromDate.HasValue) queryParams.Add($"fromDate={fromDate:yyyy-MM-dd}");
            if (toDate.HasValue) queryParams.Add($"toDate={toDate:yyyy-MM-dd}");
            if (!string.IsNullOrEmpty(status)) queryParams.Add($"status={status}");
            if (branchId.HasValue) queryParams.Add($"branchId={branchId}");

            var queryString = queryParams.Any() ? "?" + string.Join("&", queryParams) : "";
            var response = await _httpClient.GetAsync($"/api/admin/reports/orders{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var jsonResponse = await response.Content.ReadFromJsonAsync<JsonElement>();

                if (jsonResponse.ValueKind == JsonValueKind.Object &&
                    jsonResponse.TryGetProperty("data", out var dataProperty))
                {
                    return JsonSerializer.Deserialize<OrderReportDto>(dataProperty.GetRawText());
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching order report: {ex.Message}");
        }

        return null;
    }

    public async Task<List<PopularItemReportDto>> GetPopularItemsAsync(DateTime? fromDate = null, DateTime? toDate = null, int limit = 10)
    {
        try
        {
            var queryParams = new List<string> { $"limit={limit}" };
            if (fromDate.HasValue) queryParams.Add($"fromDate={fromDate:yyyy-MM-dd}");
            if (toDate.HasValue) queryParams.Add($"toDate={toDate:yyyy-MM-dd}");

            var queryString = "?" + string.Join("&", queryParams);
            var response = await _httpClient.GetAsync($"/api/admin/reports/popular-items{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var jsonResponse = await response.Content.ReadFromJsonAsync<JsonElement>();

                if (jsonResponse.ValueKind == JsonValueKind.Object &&
                    jsonResponse.TryGetProperty("data", out var dataProperty))
                {
                    var items = JsonSerializer.Deserialize<List<PopularItemReportDto>>(dataProperty.GetRawText());
                    return items ?? new List<PopularItemReportDto>();
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching popular items: {ex.Message}");
        }

        return new List<PopularItemReportDto>();
    }

    public async Task<List<BranchPerformanceDto>> GetBranchPerformanceAsync(DateTime? fromDate = null, DateTime? toDate = null, int? branchId = null)
    {
        try
        {
            var queryParams = new List<string>();
            if (fromDate.HasValue) queryParams.Add($"fromDate={fromDate:yyyy-MM-dd}");
            if (toDate.HasValue) queryParams.Add($"toDate={toDate:yyyy-MM-dd}");
            if (branchId.HasValue) queryParams.Add($"branchId={branchId}");

            var queryString = queryParams.Any() ? "?" + string.Join("&", queryParams) : "";
            var response = await _httpClient.GetAsync($"/api/admin/reports/branch-performance{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var jsonResponse = await response.Content.ReadFromJsonAsync<JsonElement>();

                if (jsonResponse.ValueKind == JsonValueKind.Object &&
                    jsonResponse.TryGetProperty("data", out var dataProperty))
                {
                    var branches = JsonSerializer.Deserialize<List<BranchPerformanceDto>>(dataProperty.GetRawText());
                    return branches ?? new List<BranchPerformanceDto>();
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching branch performance: {ex.Message}");
        }

        return new List<BranchPerformanceDto>();
    }
}

public class BusinessSummaryDto
{
    public decimal TotalRevenue { get; set; }
    public int TotalOrders { get; set; }
    public int TotalCustomers { get; set; }
    public decimal AverageOrderValue { get; set; }
    public int PendingOrders { get; set; }
    public int ActiveCustomers { get; set; }
    public decimal TodayRevenue { get; set; }
    public int TodayOrders { get; set; }
}

public class RevenueReportDto
{
    public string Period { get; set; } = "";
    public DateTime PeriodStart { get; set; }
    public DateTime PeriodEnd { get; set; }
    public decimal Revenue { get; set; }
    public int OrderCount { get; set; }
    public decimal AverageOrderValue { get; set; }
}

public class OrderReportDto
{
    public int TotalOrders { get; set; }
    public int PendingOrders { get; set; }
    public int ConfirmedOrders { get; set; }
    public int PreparingOrders { get; set; }
    public int ReadyOrders { get; set; }
    public int OutForDeliveryOrders { get; set; }
    public int DeliveredOrders { get; set; }
    public int CancelledOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal AverageOrderValue { get; set; }
    public List<OrderTrendDto> Trends { get; set; } = new();
}

public class OrderTrendDto
{
    public DateTime Date { get; set; }
    public int OrderCount { get; set; }
    public decimal Revenue { get; set; }
}

public class PopularItemReportDto
{
    public int MenuItemId { get; set; }
    public string NameEn { get; set; } = "";
    public string NameAr { get; set; } = "";
    public int QuantitySold { get; set; }
    public decimal Revenue { get; set; }
    public decimal AveragePrice { get; set; }
}

public class BranchPerformanceDto
{
    public int BranchId { get; set; }
    public string BranchNameEn { get; set; } = "";
    public string BranchNameAr { get; set; } = "";
    public int OrderCount { get; set; }
    public decimal Revenue { get; set; }
    public decimal AverageOrderValue { get; set; }
    public int DeliveredOrders { get; set; }
    public int CancelledOrders { get; set; }
}



