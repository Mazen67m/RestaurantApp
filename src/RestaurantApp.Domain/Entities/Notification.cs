using System;
using RestaurantApp.Domain.Entities;

namespace RestaurantApp.Domain.Entities;

public class Notification : BaseEntity
{
    public int UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string Type { get; set; } = "General"; // Order, Offer, Security, General
    public string? ActionData { get; set; } // JSON or simple string for navigation
    public bool IsRead { get; set; } = false;
    
    public virtual ApplicationUser? User { get; set; }
}
