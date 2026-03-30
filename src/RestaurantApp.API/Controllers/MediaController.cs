using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestaurantApp.Application.DTOs;

namespace RestaurantApp.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin")]
public class MediaController : ControllerBase
{
    private readonly IWebHostEnvironment _environment;

    public MediaController(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    /// <summary>
    /// Uploads an image file for menu items or restaurant logos (Max 5MB)
    /// </summary>
    [HttpPost("upload")]
    [RequestSizeLimit(5 * 1024 * 1024)] // 5MB Limit
    public async Task<IActionResult> UploadImage(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("No file uploaded");

        // Validate file type extension
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(extension))
            return BadRequest("Invalid file type. Only JPG, PNG and WebP are allowed.");

        // SECURITY: Validate file content (Magic Bytes)
        if (!await ValidateMagicBytes(file))
        {
            return BadRequest("File content does not match its extension.");
        }

        // Create unique filename
        var fileName = $"{Guid.NewGuid()}{extension}";
        var uploadsPath = Path.Combine(_environment.WebRootPath, "uploads");
        
        if (!Directory.Exists(uploadsPath))
            Directory.CreateDirectory(uploadsPath);

        var filePath = Path.Combine(uploadsPath, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Return the absolute URL
        var request = HttpContext.Request;
        var baseUrl = $"{request.Scheme}://{request.Host}{request.PathBase}";
        var imageUrl = $"{baseUrl}/uploads/{fileName}";

        return Ok(new { ImageUrl = imageUrl });
    }

    private async Task<bool> ValidateMagicBytes(IFormFile file)
    {
        using var stream = file.OpenReadStream();
        using var reader = new BinaryReader(stream);
        
        if (file.Length < 4) return false;

        byte[] bytes = reader.ReadBytes(4);
        string hex = BitConverter.ToString(bytes).Replace("-", "");

        // Common Image Signatures
        // JPG: FF-D8-FF
        // PNG: 89-50-4E-47
        // WEBP: 52-49-46-46 (RIFF...)
        
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        
        return extension switch
        {
            ".jpg" or ".jpeg" => hex.StartsWith("FFD8FF"),
            ".png" => hex.StartsWith("89504E47"),
            ".webp" => hex.StartsWith("52494646"), // RIFF
            _ => false
        };
    }
}
