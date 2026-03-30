using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Domain.Entities;

namespace RestaurantApp.Infrastructure.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser, IdentityRole<int>, int>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        base.OnConfiguring(optionsBuilder);
        
        // Suppress the PendingModelChangesWarning
        optionsBuilder.ConfigureWarnings(warnings =>
            warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
    }

    public DbSet<Restaurant> Restaurants => Set<Restaurant>();
    public DbSet<Branch> Branches => Set<Branch>();
    public DbSet<MenuCategory> MenuCategories => Set<MenuCategory>();
    public DbSet<MenuItem> MenuItems => Set<MenuItem>();
    public DbSet<MenuItemAddOn> MenuItemAddOns => Set<MenuItemAddOn>();
    public DbSet<UserAddress> UserAddresses => Set<UserAddress>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<OrderItemAddOn> OrderItemAddOns => Set<OrderItemAddOn>();
    public DbSet<Offer> Offers => Set<Offer>();
    public DbSet<DeliveryZone> DeliveryZones => Set<DeliveryZone>();
    
    // Phase 3: Reviews, Loyalty, Favorites
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<LoyaltyPoints> LoyaltyPoints => Set<LoyaltyPoints>();
    public DbSet<LoyaltyTransaction> LoyaltyTransactions => Set<LoyaltyTransaction>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    
    // Delivery Management
    public DbSet<Delivery> Deliveries => Set<Delivery>();
    
    // Order Status History
    public DbSet<OrderStatusHistory> OrderStatusHistories => Set<OrderStatusHistory>();
    
    // Authentication & Security
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();


    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Apply all configurations from assembly
        builder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
        
        // Configure decimal precision
        foreach (var entityType in builder.Model.GetEntityTypes())
        {
            var properties = entityType.ClrType.GetProperties()
                .Where(p => p.PropertyType == typeof(decimal) || p.PropertyType == typeof(decimal?));

            foreach (var property in properties)
            {
                builder.Entity(entityType.Name).Property(property.Name)
                    .HasColumnType("decimal(18,2)");
            }
        }
        
        // ========================================
        // Performance Indexes - Production Readiness
        // ========================================
        
        // Orders table - High-traffic queries
        builder.Entity<Order>()
            .HasIndex(o => o.UserId)
            .HasDatabaseName("IX_Orders_UserId");
        
        builder.Entity<Order>()
            .HasIndex(o => o.BranchId)
            .HasDatabaseName("IX_Orders_BranchId");
        
        builder.Entity<Order>()
            .HasIndex(o => o.Status)
            .HasDatabaseName("IX_Orders_Status");
        
        builder.Entity<Order>()
            .HasIndex(o => o.CreatedAt)
            .HasDatabaseName("IX_Orders_CreatedAt");
        
        // Reviews table - Moderation and display queries
        builder.Entity<Review>()
            .HasIndex(r => r.MenuItemId)
            .HasDatabaseName("IX_Reviews_MenuItemId");
        
        builder.Entity<Review>()
            .HasIndex(r => r.IsApproved)
            .HasDatabaseName("IX_Reviews_IsApproved");
        
        // MenuItems table - Catalog queries
        builder.Entity<MenuItem>()
            .HasIndex(m => m.CategoryId)
            .HasDatabaseName("IX_MenuItems_CategoryId");
        
        builder.Entity<MenuItem>()
            .HasIndex(m => m.IsAvailable)
            .HasDatabaseName("IX_MenuItems_IsAvailable");
        
        // LoyaltyTransactions table - User history queries
        builder.Entity<LoyaltyTransaction>()
            .HasIndex(lt => lt.UserId)
            .HasDatabaseName("IX_LoyaltyTransactions_UserId");
        
        // OrderStatusHistory table - Order tracking
        builder.Entity<OrderStatusHistory>()
            .HasIndex(osh => osh.OrderId)
            .HasDatabaseName("IX_OrderStatusHistory_OrderId");
        
        // RefreshTokens table - Authentication queries
        builder.Entity<RefreshToken>()
            .HasIndex(rt => rt.Token)
            .HasDatabaseName("IX_RefreshTokens_Token");
        
        builder.Entity<RefreshToken>()
            .HasIndex(rt => rt.UserId)
            .HasDatabaseName("IX_RefreshTokens_UserId");
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var entries = ChangeTracker.Entries()
            .Where(e => e.Entity is BaseEntity && 
                       (e.State == EntityState.Added || e.State == EntityState.Modified));

        foreach (var entry in entries)
        {
            var entity = (BaseEntity)entry.Entity;
            
            if (entry.State == EntityState.Added)
            {
                entity.CreatedAt = DateTime.UtcNow;
            }
            else
            {
                entity.UpdatedAt = DateTime.UtcNow;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
