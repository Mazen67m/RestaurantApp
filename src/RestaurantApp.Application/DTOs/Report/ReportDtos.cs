namespace RestaurantApp.Application.DTOs.Report;

public record BusinessSummaryDto(
    decimal TotalRevenue,
    int TotalOrders,
    int TotalCustomers,
    decimal AverageOrderValue,
    int PendingOrders,
    int ActiveCustomers,
    decimal TodayRevenue,
    int TodayOrders
);

public record RevenueReportDto(
    string Period,
    DateTime PeriodStart,
    DateTime PeriodEnd,
    decimal Revenue,
    int OrderCount,
    decimal AverageOrderValue
);

public record OrderReportDto(
    int TotalOrders,
    int PendingOrders,
    int ConfirmedOrders,
    int PreparingOrders,
    int ReadyOrders,
    int OutForDeliveryOrders,
    int DeliveredOrders,
    int CancelledOrders,
    decimal TotalRevenue,
    decimal AverageOrderValue,
    List<OrderTrendDto> Trends
);

public record OrderTrendDto(
    DateTime Date,
    int OrderCount,
    decimal Revenue
);

public record PopularItemReportDto(
    int MenuItemId,
    string NameEn,
    string NameAr,
    int QuantitySold,
    decimal Revenue,
    decimal AveragePrice
);

public record BranchPerformanceDto(
    int BranchId,
    string BranchNameEn,
    string BranchNameAr,
    int OrderCount,
    decimal Revenue,
    decimal AverageOrderValue,
    int DeliveredOrders,
    int CancelledOrders
);



