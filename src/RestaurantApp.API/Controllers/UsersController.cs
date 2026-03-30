using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestaurantApp.Application.DTOs.User;
using RestaurantApp.Application.Interfaces;

namespace RestaurantApp.API.Controllers;

[ApiController]
[Route("api/admin/users")]
[Authorize(Roles = "Admin")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IResourceAuthorizationService _authService;

    public UsersController(
        IUserService userService,
        IResourceAuthorizationService authService)
    {
        _userService = userService;
        _authService = authService;
    }

    [HttpGet]
    public async Task<IActionResult> GetUsers(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? role = null,
        [FromQuery] string? status = null,
        [FromQuery] string? search = null)
    {
        var result = await _userService.GetUsersAsync(page, pageSize, role, status, search);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetUser(int id)
    {
        var currentUserId = GetUserId();
        
        // IDOR Protection: Check if user can access this user's data
        if (!await _authService.CanAccessUserAsync(currentUserId, id))
        {
            return Forbid();
        }

        var result = await _userService.GetUserByIdAsync(id);
        if (!result.Success)
        {
            return NotFound(result);
        }
        return Ok(result);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserDto dto)
    {
        var currentUserId = GetUserId();
        
        // IDOR Protection: Check if user can modify this user
        if (!await _authService.CanAccessUserAsync(currentUserId, id))
        {
            return Forbid();
        }

        var result = await _userService.UpdateUserAsync(id, dto);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserDto dto)
    {
        var result = await _userService.CreateUserAsync(dto);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return CreatedAtAction(nameof(GetUser), new { id = result.Data!.Id }, result);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeactivateUser(int id)
    {
        var currentUserId = GetUserId();
        
        // IDOR Protection: Only SuperAdmin can deactivate users
        if (!await _authService.IsSuperAdminAsync(currentUserId))
        {
            return Forbid();
        }

        var result = await _userService.DeactivateUserAsync(id);
        if (!result.Success)
        {
            return NotFound(result);
        }
        return Ok(result);
    }

    private int GetUserId()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return int.Parse(userIdClaim!);
    }
}



