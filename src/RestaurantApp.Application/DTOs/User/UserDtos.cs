namespace RestaurantApp.Application.DTOs.User;

public record UserDto(
    int Id,
    string Email,
    string FullName,
    string? Phone,
    string? ProfileImageUrl,
    string Role,
    bool IsActive,
    int OrderCount,
    decimal TotalSpent,
    DateTime CreatedAt
);

public record UserDetailsDto(
    int Id,
    string Email,
    string FullName,
    string? Phone,
    string? ProfileImageUrl,
    string PreferredLanguage,
    string Role,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? LastLoginAt,
    int OrderCount,
    decimal TotalSpent,
    List<UserOrderSummary> RecentOrders
);

public record UserOrderSummary(
    int Id,
    string OrderNumber,
    decimal Total,
    DateTime CreatedAt,
    string Status
);

public record UpdateUserDto(
    string? FullName,
    string? Phone,
    string? Role,
    bool? IsActive
);

public record CreateUserDto(
    string Email,
    string FullName,
    string Password,
    string? Phone,
    string Role = "Customer"
);



