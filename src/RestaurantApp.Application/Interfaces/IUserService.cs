using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.User;

namespace RestaurantApp.Application.Interfaces;

public interface IUserService
{
    Task<ApiResponse<PagedResponse<UserDto>>> GetUsersAsync(
        int page = 1,
        int pageSize = 20,
        string? role = null,
        string? status = null,
        string? search = null);
    
    Task<ApiResponse<UserDetailsDto>> GetUserByIdAsync(int id);
    
    Task<ApiResponse<UserDto>> UpdateUserAsync(int id, UpdateUserDto dto);
    
    Task<ApiResponse<UserDto>> CreateUserAsync(CreateUserDto dto);
    
    Task<ApiResponse> DeactivateUserAsync(int id);
}



