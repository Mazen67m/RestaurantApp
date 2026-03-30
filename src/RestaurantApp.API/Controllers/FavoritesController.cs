using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Favorite;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Infrastructure.Data;
using System.Security.Claims;

namespace RestaurantApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FavoritesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public FavoritesController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get current user's favorites
    /// </summary>
    [HttpGet]
    [Authorize]
    public async Task<IActionResult> GetFavorites()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(rawUserId) || !int.TryParse(rawUserId, out int userId))
        {
            return Unauthorized();
        }

        var favorites = await _context.Favorites
            .Where(f => f.UserId == userId)
            .Include(f => f.MenuItem)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => new FavoriteDto(
                f.Id,
                f.MenuItemId,
                f.MenuItem.NameEn,
                f.MenuItem.NameAr,
                f.MenuItem.Price,
                f.MenuItem.DiscountedPrice,
                f.MenuItem.ImageUrl,
                f.MenuItem.IsAvailable,
                f.CreatedAt
            ))
            .ToListAsync();

        return Ok(ApiResponse<List<FavoriteDto>>.SuccessResponse(favorites));
    }

    /// <summary>
    /// Get favorites for a specific user (for testing/demo)
    /// </summary>
    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetUserFavorites(int userId)
    {
        var favorites = await _context.Favorites
            .Where(f => f.UserId == userId)
            .Include(f => f.MenuItem)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => new FavoriteDto(
                f.Id,
                f.MenuItemId,
                f.MenuItem.NameEn,
                f.MenuItem.NameAr,
                f.MenuItem.Price,
                f.MenuItem.DiscountedPrice,
                f.MenuItem.ImageUrl,
                f.MenuItem.IsAvailable,
                f.CreatedAt
            ))
            .ToListAsync();

        return Ok(ApiResponse<List<FavoriteDto>>.SuccessResponse(favorites));
    }

    /// <summary>
    /// Check if an item is in favorites
    /// </summary>
    [HttpGet("check/{menuItemId}")]
    [Authorize]
    public async Task<IActionResult> CheckFavorite(int menuItemId)
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(rawUserId) || !int.TryParse(rawUserId, out int userId))
        {
            return Unauthorized();
        }

        var isFavorite = await _context.Favorites
            .AnyAsync(f => f.UserId == userId && f.MenuItemId == menuItemId);

        return Ok(ApiResponse<bool>.SuccessResponse(isFavorite));
    }

    /// <summary>
    /// Add item to favorites
    /// </summary>
    [HttpPost("{menuItemId}")]
    [Authorize]
    public async Task<IActionResult> AddFavorite(int menuItemId)
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(rawUserId) || !int.TryParse(rawUserId, out int userId))
        {
            return Unauthorized();
        }

        // Check if already exists
        var exists = await _context.Favorites
            .AnyAsync(f => f.UserId == userId && f.MenuItemId == menuItemId);

        if (exists)
        {
            return Ok(ApiResponse.SuccessResponse("Already in favorites"));
        }

        // Check if menu item exists
        var menuItem = await _context.MenuItems.FindAsync(menuItemId);
        if (menuItem == null)
        {
            return NotFound(ApiResponse.ErrorResponse("Menu item not found"));
        }

        var favorite = new Favorite
        {
            UserId = userId,
            MenuItemId = menuItemId
        };

        _context.Favorites.Add(favorite);
        await _context.SaveChangesAsync();

        return Ok(ApiResponse.SuccessResponse("Added to favorites"));
    }

    /// <summary>
    /// Remove item from favorites
    /// </summary>
    [HttpDelete("{menuItemId}")]
    [Authorize]
    public async Task<IActionResult> RemoveFavorite(int menuItemId)
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(rawUserId) || !int.TryParse(rawUserId, out int userId))
        {
            return Unauthorized();
        }

        var favorite = await _context.Favorites
            .FirstOrDefaultAsync(f => f.UserId == userId && f.MenuItemId == menuItemId);

        if (favorite == null)
        {
            return NotFound(ApiResponse.ErrorResponse("Not in favorites"));
        }

        _context.Favorites.Remove(favorite);
        await _context.SaveChangesAsync();

        return Ok(ApiResponse.SuccessResponse("Removed from favorites"));
    }

    /// <summary>
    /// Toggle favorite status (add if not exists, remove if exists)
    /// </summary>
    [HttpPost("{menuItemId}/toggle")]
    [Authorize]
    public async Task<IActionResult> ToggleFavorite(int menuItemId)
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(rawUserId) || !int.TryParse(rawUserId, out int userId))
        {
            return Unauthorized();
        }

        var favorite = await _context.Favorites
            .FirstOrDefaultAsync(f => f.UserId == userId && f.MenuItemId == menuItemId);

        if (favorite != null)
        {
            _context.Favorites.Remove(favorite);
            await _context.SaveChangesAsync();
            return Ok(ApiResponse<bool>.SuccessResponse(false, "Removed from favorites"));
        }
        else
        {
            // Check if menu item exists
            var menuItem = await _context.MenuItems.FindAsync(menuItemId);
            if (menuItem == null)
            {
                return NotFound(ApiResponse.ErrorResponse("Menu item not found"));
            }

            var newFavorite = new Favorite
            {
                UserId = userId,
                MenuItemId = menuItemId
            };

            _context.Favorites.Add(newFavorite);
            await _context.SaveChangesAsync();
            return Ok(ApiResponse<bool>.SuccessResponse(true, "Added to favorites"));
        }
    }

    /// <summary>
    /// Get favorite count for current user
    /// </summary>
    [HttpGet("count")]
    [Authorize]
    public async Task<IActionResult> GetFavoriteCount()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(rawUserId) || !int.TryParse(rawUserId, out int userId))
        {
            return Unauthorized();
        }

        var count = await _context.Favorites.CountAsync(f => f.UserId == userId);
        return Ok(ApiResponse<int>.SuccessResponse(count));
    }
}
