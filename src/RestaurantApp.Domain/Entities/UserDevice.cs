using System;
using RestaurantApp.Domain.Entities;

namespace RestaurantApp.Domain.Entities;

public class UserDevice : BaseEntity
{
    public int UserId { get; set; }
    public string DeviceToken { get; set; } = string.Empty;
    public string DeviceType { get; set; } = string.Empty; // Android, iOS, Web, etc.
    public DateTime? LastUsedAt { get; set; }
    
    public virtual ApplicationUser? User { get; set; }
}
