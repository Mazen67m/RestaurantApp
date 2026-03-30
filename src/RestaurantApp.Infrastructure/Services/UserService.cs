using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.User;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.Infrastructure.Services;

public class UserService : IUserService
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole<int>> _roleManager;

    public UserService(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole<int>> roleManager)
    {
        _context = context;
        _userManager = userManager;
        _roleManager = roleManager;
    }

    public async Task<ApiResponse<PagedResponse<UserDto>>> GetUsersAsync(
        int page = 1,
        int pageSize = 20,
        string? role = null,
        string? status = null,
        string? search = null)
    {
        var query = _context.Users.AsQueryable();

        // Apply search filter
        if (!string.IsNullOrWhiteSpace(search))
        {
            search = search.ToLower();
            query = query.Where(u => 
                (u.Email != null && u.Email.ToLower().Contains(search)) ||
                u.FullName.ToLower().Contains(search) ||
                (u.PhoneNumber != null && u.PhoneNumber.Contains(search)));
        }

        // Apply role filter
        if (!string.IsNullOrWhiteSpace(role))
        {
            var usersInRole = await _userManager.GetUsersInRoleAsync(role);
            var userIds = usersInRole?.Select(u => u.Id).ToList() ?? new List<int>();
            if (userIds.Any())
            {
                query = query.Where(u => userIds.Contains(u.Id));
            }
        }

        // Apply status filter
        if (!string.IsNullOrWhiteSpace(status))
        {
            if (status.ToLower() == "active")
                query = query.Where(u => u.IsActive);
            else if (status.ToLower() == "inactive")
                query = query.Where(u => !u.IsActive);
        }

        var totalCount = await query.CountAsync();

        // Get users with their order statistics
        var users = await query
            .AsNoTracking()
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();


        // Batch load order statistics for all users (fixes N+1 query problem)
        var allUserIds = users.Select(u => u.Id).ToList();
        
        var orderStats = await _context.Orders
            .Where(o => allUserIds.Contains(o.UserId))
            .GroupBy(o => o.UserId)
            .Select(g => new
            {
                UserId = g.Key,
                Count = g.Count(),
                Total = g.Sum(o => o.Total)
            })
            .ToDictionaryAsync(x => x.UserId);

        // Batch load user roles (fixes N+1 query problem)
        var userRoles = await _context.UserRoles
            .Where(ur => allUserIds.Contains(ur.UserId))
            .Join(_context.Roles, 
                ur => ur.RoleId, 
                r => r.Id, 
                (ur, r) => new { ur.UserId, r.Name })
            .ToListAsync();

        var userRolesDict = userRoles
            .GroupBy(x => x.UserId)
            .ToDictionary(g => g.Key, g => g.First()?.Name ?? "Customer");

        // Map to DTOs using pre-loaded data
        var userDtos = users.Select(user =>
        {
            var stats = orderStats.GetValueOrDefault(user.Id);
            return new UserDto(
                user.Id,
                user.Email ?? "",
                user.FullName,
                user.PhoneNumber,
                user.ProfileImageUrl,
                userRolesDict[user.Id],
                user.IsActive,
                stats?.Count ?? 0,
                stats?.Total ?? 0,
                user.CreatedAt
            );
        }).ToList();

        var pagedResponse = new PagedResponse<UserDto>
        {
            Items = userDtos,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };

        return ApiResponse<PagedResponse<UserDto>>.SuccessResponse(pagedResponse);
    }

    public async Task<ApiResponse<UserDetailsDto>> GetUserByIdAsync(int id)
    {
        var user = await _context.Users
            .AsNoTracking()
            .Include(u => u.Orders)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return ApiResponse<UserDetailsDto>.ErrorResponse("User not found");
        }

        var userRoles = await _userManager.GetRolesAsync(user);
        var primaryRole = userRoles.FirstOrDefault() ?? "Customer";

        var orders = await _context.Orders
            .Where(o => o.UserId == user.Id)
            .OrderByDescending(o => o.CreatedAt)
            .Take(10)
            .Select(o => new UserOrderSummary(
                o.Id,
                o.OrderNumber,
                o.Total,
                o.CreatedAt,
                o.Status.ToString()
            ))
            .ToListAsync();

        var orderStats = await _context.Orders
            .Where(o => o.UserId == user.Id)
            .GroupBy(o => 1)
            .Select(g => new
            {
                Count = g.Count(),
                Total = g.Sum(o => o.Total)
            })
            .FirstOrDefaultAsync();

        var userDetails = new UserDetailsDto(
            user.Id,
            user.Email ?? "",
            user.FullName,
            user.PhoneNumber,
            user.ProfileImageUrl,
            user.PreferredLanguage,
            primaryRole,
            user.IsActive,
            user.CreatedAt,
            user.LastLoginAt,
            orderStats?.Count ?? 0,
            orderStats?.Total ?? 0,
            orders
        );

        return ApiResponse<UserDetailsDto>.SuccessResponse(userDetails);
    }

    public async Task<ApiResponse<UserDto>> UpdateUserAsync(int id, UpdateUserDto dto)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user == null)
        {
            return ApiResponse<UserDto>.ErrorResponse("User not found");
        }

        if (!string.IsNullOrWhiteSpace(dto.FullName))
            user.FullName = dto.FullName;

        if (!string.IsNullOrWhiteSpace(dto.Phone))
            user.PhoneNumber = dto.Phone;

        if (dto.IsActive.HasValue)
            user.IsActive = dto.IsActive.Value;

        if (!string.IsNullOrWhiteSpace(dto.Role))
        {
            var currentRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, currentRoles);

            if (!await _roleManager.RoleExistsAsync(dto.Role))
            {
                await _roleManager.CreateAsync(new IdentityRole<int>(dto.Role));
            }

            await _userManager.AddToRoleAsync(user, dto.Role);
        }

        await _userManager.UpdateAsync(user);

        var userRoles = await _userManager.GetRolesAsync(user);
        var primaryRole = userRoles.FirstOrDefault() ?? "Customer";

        var orderStats = await _context.Orders
            .Where(o => o.UserId == user.Id)
            .GroupBy(o => 1)
            .Select(g => new
            {
                Count = g.Count(),
                Total = g.Sum(o => o.Total)
            })
            .FirstOrDefaultAsync();

        var userDto = new UserDto(
            user.Id,
            user.Email ?? "",
            user.FullName,
            user.PhoneNumber,
            user.ProfileImageUrl,
            primaryRole,
            user.IsActive,
            orderStats?.Count ?? 0,
            orderStats?.Total ?? 0,
            user.CreatedAt
        );

        return ApiResponse<UserDto>.SuccessResponse(userDto);
    }

    public async Task<ApiResponse<UserDto>> CreateUserAsync(CreateUserDto dto)
    {
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);
        if (existingUser != null)
        {
            return ApiResponse<UserDto>.ErrorResponse("Email is already in use");
        }

        var user = new ApplicationUser
        {
            UserName = dto.Email,
            Email = dto.Email,
            FullName = dto.FullName,
            PhoneNumber = dto.Phone,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var result = await _userManager.CreateAsync(user, dto.Password);
        if (!result.Succeeded)
        {
            return ApiResponse<UserDto>.ErrorResponse(string.Join(", ", result.Errors.Select(e => e.Description)));
        }

        // Add role
        if (!string.IsNullOrWhiteSpace(dto.Role))
        {
            if (!await _roleManager.RoleExistsAsync(dto.Role))
            {
                await _roleManager.CreateAsync(new IdentityRole<int>(dto.Role));
            }
            await _userManager.AddToRoleAsync(user, dto.Role);
        }
        else
        {
            await _userManager.AddToRoleAsync(user, "Customer");
        }

        var userDto = new UserDto(
            user.Id,
            user.Email ?? "",
            user.FullName,
            user.PhoneNumber,
            user.ProfileImageUrl,
            dto.Role ?? "Customer",
            user.IsActive,
            0,
            0,
            user.CreatedAt
        );

        return ApiResponse<UserDto>.SuccessResponse(userDto);
    }

    public async Task<ApiResponse> DeactivateUserAsync(int id)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user == null)
        {
            return ApiResponse.ErrorResponse("User not found");
        }

        user.IsActive = false;
        await _userManager.UpdateAsync(user);

        return ApiResponse.SuccessResponse("User deactivated successfully");
    }
}

