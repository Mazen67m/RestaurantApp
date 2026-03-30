using System.Net.Http.Json;
using System.Text.Json;

namespace RestaurantApp.Web.Services;

public class UserApiService : BaseApiService
{
    public UserApiService(HttpClient httpClient, Microsoft.AspNetCore.Components.Authorization.AuthenticationStateProvider authProvider) 
        : base(httpClient, authProvider)
    {
    }

    public async Task<List<UserDto>> GetUsersAsync(string? role = null, string? status = null, string? search = null, int page = 1, int pageSize = 20)
    {
        try
        {
            await EnsureAuthHeaderAsync();
            var queryParams = new List<string> { $"page={page}", $"pageSize={pageSize}" };
            if (!string.IsNullOrEmpty(role)) queryParams.Add($"role={role}");
            if (!string.IsNullOrEmpty(status)) queryParams.Add($"status={status}");
            if (!string.IsNullOrEmpty(search)) queryParams.Add($"search={search}");

            var queryString = string.Join("&", queryParams);
            var response = await HttpClient.GetAsync($"/api/admin/users?{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResponse<UserDto>>>();
                return result?.Data?.Items ?? new List<UserDto>();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching users: {ex.Message}");
        }

        return new List<UserDto>();
    }

    public async Task<UserDetailsDto?> GetUserByIdAsync(int id)
    {
        try
        {
            await EnsureAuthHeaderAsync();
            var response = await HttpClient.GetAsync($"/api/admin/users/{id}");

            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<ApiResponse<UserDetailsDto>>();
                return result?.Data;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching user {id}: {ex.Message}");
        }

        return null;
    }

    public async Task<bool> UpdateUserAsync(int id, UpdateUserRequest request)
    {
        try
        {
            await EnsureAuthHeaderAsync();
            var response = await HttpClient.PutAsJsonAsync($"/api/admin/users/{id}", request);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error updating user {id}: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> CreateUserAsync(CreateUserRequest request)
    {
        try
        {
            await EnsureAuthHeaderAsync();
            var response = await HttpClient.PostAsJsonAsync("/api/admin/users", request);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating user: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> DeactivateUserAsync(int id)
    {
        try
        {
            await EnsureAuthHeaderAsync();
            var response = await HttpClient.DeleteAsync($"/api/admin/users/{id}");
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error deactivating user {id}: {ex.Message}");
            return false;
        }
    }
}

public class UserDto
{
    public int Id { get; set; }
    public string Email { get; set; } = "";
    public string FullName { get; set; } = "";
    public string? Phone { get; set; }
    public string? ProfileImageUrl { get; set; }
    public string Role { get; set; } = "";
    public bool IsActive { get; set; }
    public int OrderCount { get; set; }
    public decimal TotalSpent { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UserDetailsDto
{
    public int Id { get; set; }
    public string Email { get; set; } = "";
    public string FullName { get; set; } = "";
    public string? Phone { get; set; }
    public string? ProfileImageUrl { get; set; }
    public string PreferredLanguage { get; set; } = "";
    public string Role { get; set; } = "";
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public int OrderCount { get; set; }
    public decimal TotalSpent { get; set; }
    public List<UserOrderSummary> RecentOrders { get; set; } = new();
}

public class UserOrderSummary
{
    public int Id { get; set; }
    public string OrderNumber { get; set; } = "";
    public decimal Total { get; set; }
    public DateTime CreatedAt { get; set; }
    public string Status { get; set; } = "";
}

public class UpdateUserRequest
{
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
}

public class CreateUserRequest
{
    public string Email { get; set; } = "";
    public string FullName { get; set; } = "";
    public string Password { get; set; } = "";
    public string? Phone { get; set; }
    public string Role { get; set; } = "Customer";
}



