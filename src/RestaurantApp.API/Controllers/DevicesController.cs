using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Infrastructure.Data;
using RestaurantApp.Domain.Entities;
using System.Security.Claims;

namespace RestaurantApp.API.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class DevicesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public DevicesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpPost("register")]
    public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceDto dto)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        if (userId == 0) return Unauthorized();

        var device = await _context.UserDevices
            .FirstOrDefaultAsync(d => d.DeviceToken == dto.DeviceToken);

        if (device == null)
        {
            device = new UserDevice
            {
                UserId = userId,
                DeviceToken = dto.DeviceToken,
                DeviceType = dto.DeviceType,
                LastUsedAt = DateTime.UtcNow
            };
            _context.UserDevices.Add(device);
        }
        else
        {
            device.UserId = userId; // Update user if token was used by another
            device.DeviceType = dto.DeviceType;
            device.LastUsedAt = DateTime.UtcNow;
            _context.UserDevices.Update(device);
        }

        await _context.SaveChangesAsync();
        return Ok(new { success = true, message = "Device registered successfully" });
    }
}

public class RegisterDeviceDto
{
    public string DeviceToken { get; set; } = string.Empty;
    public string DeviceType { get; set; } = string.Empty;
}
