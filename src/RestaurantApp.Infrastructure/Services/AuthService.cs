using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Auth;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Infrastructure.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace RestaurantApp.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IConfiguration _configuration;
    private readonly IEmailService _emailService;
    private readonly ITokenBlacklistService _blacklistService;
    private readonly ILogger<AuthService> _logger;
    private readonly ApplicationDbContext _context;

    public AuthService(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        IConfiguration configuration,
        IEmailService emailService,
        ITokenBlacklistService blacklistService,
        ILogger<AuthService> logger,
        ApplicationDbContext context)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _configuration = configuration;
        _emailService = emailService;
        _blacklistService = blacklistService;
        _logger = logger;
        _context = context;
    }

    public async Task<ApiResponse<AuthResponseDto>> RegisterAsync(RegisterDto dto)
    {
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);
        if (existingUser != null)
        {
            return ApiResponse<AuthResponseDto>.ErrorResponse("Email already registered");
        }

        var user = new ApplicationUser
        {
            Email = dto.Email,
            UserName = dto.Email,
            FullName = dto.FullName,
            PhoneNumber = dto.Phone,
            PreferredLanguage = dto.PreferredLanguage
        };

        var result = await _userManager.CreateAsync(user, dto.Password);
        if (!result.Succeeded)
        {
            return ApiResponse<AuthResponseDto>.ErrorResponse(
                "Registration failed",
                result.Errors.Select(e => e.Description).ToList());
        }

        await _userManager.AddToRoleAsync(user, "Customer");

        // Generate email verification token
        var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
        var encodedToken = Convert.ToBase64String(Encoding.UTF8.GetBytes(token));
        
        // Send verification email (in production, this would be a link to the app)
        await _emailService.SendEmailVerificationAsync(user.Email!, encodedToken);

        var authResponse = await GenerateAuthResponse(user);
        return ApiResponse<AuthResponseDto>.SuccessResponse(authResponse, "Registration successful. Please verify your email.");
    }

    public async Task<ApiResponse<AuthResponseDto>> LoginAsync(LoginDto dto)
    {
        _logger.LogInformation("[AuthService] Login attempt for: {Email}", dto.Email);
        
        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user == null)
        {
            _logger.LogWarning("[AuthService] User not found for email: {Email}", dto.Email);
            return ApiResponse<AuthResponseDto>.ErrorResponse("Invalid email or password");
        }
        
        _logger.LogInformation("[AuthService] User found - IsActive: {IsActive}, EmailConfirmed: {EmailConfirmed}", user.IsActive, user.EmailConfirmed);
        
        if (!user.IsActive)
        {
            _logger.LogWarning("[AuthService] User is not active");
            return ApiResponse<AuthResponseDto>.ErrorResponse("Invalid email or password");
        }

        // Check if account is locked out
        if (await _userManager.IsLockedOutAsync(user))
        {
            return ApiResponse<AuthResponseDto>.ErrorResponse("Account locked. Please try again later.");
        }

        // Use CheckPasswordAsync to avoid email confirmation requirement from SignInManager
        var passwordValid = await _userManager.CheckPasswordAsync(user, dto.Password);
        _logger.LogInformation("[AuthService] Password validation result: {IsValid}", passwordValid);
        
        if (!passwordValid)
        {
            // Increment failed access count for lockout
            await _userManager.AccessFailedAsync(user);
            return ApiResponse<AuthResponseDto>.ErrorResponse("Invalid email or password");
        }

        // Reset failed access count on successful login
        await _userManager.ResetAccessFailedCountAsync(user);
        
        user.LastLoginAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        var authResponse = await GenerateAuthResponse(user);
        _logger.LogInformation("[AuthService] Login successful");
        return ApiResponse<AuthResponseDto>.SuccessResponse(authResponse);
    }

    public async Task<ApiResponse<AuthResponseDto>> RefreshTokenAsync(string refreshToken, string? ipAddress = null)
    {
        var existingToken = await _context.RefreshTokens
            .SingleOrDefaultAsync(t => t.Token == refreshToken);

        if (existingToken == null)
        {
            return ApiResponse<AuthResponseDto>.ErrorResponse("Invalid refresh token");
        }

        if (existingToken.RevokedAt != null)
        {
            // Security: Attempted reuse of revoked token! Revoke all descendant tokens
            // For now, just fail
            return ApiResponse<AuthResponseDto>.ErrorResponse("Invalid refresh token");
        }

        if (existingToken.IsExpired)
        {
             return ApiResponse<AuthResponseDto>.ErrorResponse("Token expired");
        }

        var user = await _userManager.FindByIdAsync(existingToken.UserId.ToString());
        if (user == null)
        {
            return ApiResponse<AuthResponseDto>.ErrorResponse("User not found");
        }
        
        // Revoke current token (Rotate)
        existingToken.RevokedAt = DateTime.UtcNow;
        existingToken.RevokedByIp = ipAddress;
        existingToken.RevocationReason = "Replaced by new token";
        
        // Generate new token
        var newRefreshToken = GenerateRefreshToken();
        existingToken.ReplacedByToken = newRefreshToken.Token;
        newRefreshToken.UserId = user.Id;
        newRefreshToken.CreatedByIp = ipAddress;
        
        _context.RefreshTokens.Update(existingToken);
        _context.RefreshTokens.Add(newRefreshToken);
        await _context.SaveChangesAsync();
        
        var authResponse = await GenerateAuthResponse(user, newRefreshToken);
        return ApiResponse<AuthResponseDto>.SuccessResponse(authResponse);
    }

    public async Task RevokeRefreshTokenAsync(string refreshToken, string? ipAddress = null, string? reason = null)
    {
        var token = await _context.RefreshTokens
            .SingleOrDefaultAsync(t => t.Token == refreshToken);

        if (token != null && !token.IsActive)
        {
            return; // Already revoked or expired
        }

        if (token != null)
        {
            token.RevokedAt = DateTime.UtcNow;
            token.RevokedByIp = ipAddress;
            token.RevocationReason = reason ?? "Revoked manually";
            
            _context.RefreshTokens.Update(token);
            await _context.SaveChangesAsync();
        }
    }

    public async Task<ApiResponse> VerifyEmailAsync(VerifyEmailDto dto)
    {
        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user == null)
        {
            return ApiResponse.ErrorResponse("User not found");
        }

        var decodedToken = Encoding.UTF8.GetString(Convert.FromBase64String(dto.Token));
        var result = await _userManager.ConfirmEmailAsync(user, decodedToken);
        
        if (!result.Succeeded)
        {
            return ApiResponse.ErrorResponse("Email verification failed", 
                result.Errors.Select(e => e.Description).ToList());
        }

        return ApiResponse.SuccessResponse("Email verified successfully");
    }

    public async Task<ApiResponse<UserProfileDto>> GetProfileAsync(int userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null)
        {
            return ApiResponse<UserProfileDto>.ErrorResponse("User not found");
        }

        var profile = new UserProfileDto(
            user.Id,
            user.Email!,
            user.FullName,
            user.PhoneNumber,
            user.ProfileImageUrl,
            user.PreferredLanguage,
            user.EmailConfirmed
        );

        return ApiResponse<UserProfileDto>.SuccessResponse(profile);
    }

    public async Task<ApiResponse<UserProfileDto>> UpdateProfileAsync(int userId, UpdateProfileDto dto)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null)
        {
            return ApiResponse<UserProfileDto>.ErrorResponse("User not found");
        }

        user.FullName = dto.FullName;
        user.PhoneNumber = dto.Phone;
        user.PreferredLanguage = dto.PreferredLanguage;

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
        {
            return ApiResponse<UserProfileDto>.ErrorResponse("Update failed",
                result.Errors.Select(e => e.Description).ToList());
        }

        return await GetProfileAsync(userId);
    }

    public async Task<ApiResponse> ChangePasswordAsync(int userId, ChangePasswordDto dto)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user == null)
        {
            return ApiResponse.ErrorResponse("User not found");
        }

        var result = await _userManager.ChangePasswordAsync(user, dto.CurrentPassword, dto.NewPassword);
        if (!result.Succeeded)
        {
            return ApiResponse.ErrorResponse("Password change failed",
                result.Errors.Select(e => e.Description).ToList());
        }

        return ApiResponse.SuccessResponse("Password changed successfully");
    }

    public async Task<ApiResponse> ForgotPasswordAsync(ForgotPasswordDto dto)
    {
        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user == null)
        {
            // Don't reveal if user exists
            return ApiResponse.SuccessResponse("If the email exists, a reset link has been sent.");
        }

        var token = await _userManager.GeneratePasswordResetTokenAsync(user);
        var encodedToken = Convert.ToBase64String(Encoding.UTF8.GetBytes(token));
        
        await _emailService.SendPasswordResetAsync(user.Email!, encodedToken);

        return ApiResponse.SuccessResponse("If the email exists, a reset link has been sent.");
    }

    public async Task<ApiResponse> ResetPasswordAsync(ResetPasswordDto dto)
    {
        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user == null)
        {
            return ApiResponse.ErrorResponse("Invalid request");
        }

        var decodedToken = Encoding.UTF8.GetString(Convert.FromBase64String(dto.Token));
        var result = await _userManager.ResetPasswordAsync(user, decodedToken, dto.NewPassword);
        
        if (!result.Succeeded)
        {
            return ApiResponse.ErrorResponse("Password reset failed",
                result.Errors.Select(e => e.Description).ToList());
        }

        return ApiResponse.SuccessResponse("Password reset successfully");
    }

    public async Task<ApiResponse> LogoutAsync(string token)
    {
        if (string.IsNullOrEmpty(token))
            return ApiResponse.ErrorResponse("Token is required");

        try
        {
            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);
            var expiry = jwtToken.ValidTo - DateTime.UtcNow;

            if (expiry > TimeSpan.Zero)
            {
                await _blacklistService.BlacklistTokenAsync(token, expiry);
            }

            return ApiResponse.SuccessResponse("Logged out successfully");
        }
        catch (Exception)
        {
            return ApiResponse.ErrorResponse("Invalid token");
        }
    }

    private static RefreshToken GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return new RefreshToken
        {
            Token = Convert.ToBase64String(randomNumber),
            ExpiresAt = DateTime.UtcNow.AddDays(7),
            CreatedAt = DateTime.UtcNow
        };
    }

    private async Task<AuthResponseDto> GenerateAuthResponse(ApplicationUser user, RefreshToken? existingRefreshToken = null)
    {
        var roles = await _userManager.GetRolesAsync(user);
        var role = roles.FirstOrDefault() ?? "Customer";

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email!),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Role, role),
            new("language", user.PreferredLanguage)
        };

        var jwtKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY") 
                     ?? _configuration["Jwt:Key"];
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddMinutes(15);

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: expires,
            signingCredentials: credentials
        );

        var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

        RefreshToken refreshToken;
        
        if (existingRefreshToken != null)
        {
            refreshToken = existingRefreshToken;
        }
        else
        {
            refreshToken = GenerateRefreshToken();
            refreshToken.UserId = user.Id;
            _context.RefreshTokens.Add(refreshToken);
            await _context.SaveChangesAsync();
        }

        return new AuthResponseDto(
            user.Id,
            user.Email!,
            user.FullName,
            tokenString,
            expires,
            role,
            user.PreferredLanguage,
            refreshToken.Token,
            refreshToken.ExpiresAt
        );
    }
}
