namespace RestaurantApp.Domain.Entities;

/// <summary>
/// Refresh token for JWT authentication
/// Allows users to obtain new access tokens without re-authenticating
/// </summary>
public class RefreshToken
{
    public int Id { get; set; }
    
    /// <summary>
    /// The actual refresh token value (cryptographically secure random string)
    /// </summary>
    public string Token { get; set; } = string.Empty;
    
    /// <summary>
    /// User ID this token belongs to
    /// </summary>
    public int UserId { get; set; }
    
    /// <summary>
    /// When this token expires
    /// </summary>
    public DateTime ExpiresAt { get; set; }
    
    /// <summary>
    /// When this token was created
    /// </summary>
    public DateTime CreatedAt { get; set; }
    
    /// <summary>
    /// IP address that created this token
    /// </summary>
    public string? CreatedByIp { get; set; }
    
    /// <summary>
    /// When this token was revoked (if applicable)
    /// </summary>
    public DateTime? RevokedAt { get; set; }
    
    /// <summary>
    /// IP address that revoked this token
    /// </summary>
    public string? RevokedByIp { get; set; }
    
    /// <summary>
    /// Token that replaced this one (for rotation)
    /// </summary>
    public string? ReplacedByToken { get; set; }
    
    /// <summary>
    /// Reason for revocation
    /// </summary>
    public string? RevocationReason { get; set; }
    
    /// <summary>
    /// Check if token is currently active
    /// </summary>
    public bool IsActive => RevokedAt == null && !IsExpired;
    
    /// <summary>
    /// Check if token is expired
    /// </summary>
    public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
}
