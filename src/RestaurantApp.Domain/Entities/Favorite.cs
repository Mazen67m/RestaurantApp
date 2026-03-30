namespace RestaurantApp.Domain.Entities;

/// <summary>
/// Customer's favorite menu items (wishlist)
/// </summary>
public class Favorite : BaseEntity
{
    /// <summary>
    /// The customer who favorited the item
    /// </summary>
    public int UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;
    
    /// <summary>
    /// The favorited menu item
    /// </summary>
    public int MenuItemId { get; set; }
    public MenuItem MenuItem { get; set; } = null!;
}
