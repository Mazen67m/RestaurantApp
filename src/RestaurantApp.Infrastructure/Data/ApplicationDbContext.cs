using System;
using System.Linq;
using System.Linq.Expressions;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Query;
using RestaurantApp.Domain.Entities;

namespace RestaurantApp.Infrastructure.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser, IdentityRole<int>, int>
{
    private readonly IPublisher _publisher;

    public ApplicationDbContext(
        DbContextOptions<ApplicationDbContext> options,
        IPublisher publisher) : base(options)
    {
        _publisher = publisher;
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        base.OnConfiguring(optionsBuilder);
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
    public DbSet<UserDevice> UserDevices => Set<UserDevice>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();


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

        builder.Entity<Order>()
            .HasIndex(o => o.OrderNumber)
            .IsUnique() // OrderNumber should be unique
            .HasDatabaseName("IX_Orders_OrderNumber");
        
        // OrderItems
        builder.Entity<OrderItem>()
            .HasIndex(oi => oi.OrderId)
            .HasDatabaseName("IX_OrderItems_OrderId");

        // MenuItemAddOns
        builder.Entity<MenuItemAddOn>()
            .HasIndex(ma => ma.MenuItemId)
            .HasDatabaseName("IX_MenuItemAddOns_MenuItemId");

        // Branches
        builder.Entity<Branch>()
            .HasIndex(b => b.RestaurantId)
            .HasDatabaseName("IX_Branches_RestaurantId");

        // MenuCategories
        builder.Entity<MenuCategory>()
            .HasIndex(mc => mc.RestaurantId)
            .HasDatabaseName("IX_MenuCategories_RestaurantId");

        // UserAddresses
        builder.Entity<UserAddress>()
            .HasIndex(ua => ua.UserId)
            .HasDatabaseName("IX_UserAddresses_UserId");

        // DeliveryZones
        builder.Entity<DeliveryZone>()
            .HasIndex(dz => dz.BranchId)
            .HasDatabaseName("IX_DeliveryZones_BranchId");

        // Favorites
        builder.Entity<Favorite>()
            .HasIndex(f => f.UserId)
            .HasDatabaseName("IX_Favorites_UserId");
        
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

        // Soft Delete - Global Query Filters
        foreach (var entityType in builder.Model.GetEntityTypes())
        {
            if (entityType.ClrType != null && typeof(BaseEntity).IsAssignableFrom(entityType.ClrType))
            {
                var parameter = Expression.Parameter(entityType.ClrType, "e");
                var property = Expression.Property(parameter, "IsDeleted");
                var falseConstant = Expression.Constant(false);
                var equal = Expression.Equal(property, falseConstant);
                var filter = Expression.Lambda(equal, parameter);

                builder.Entity(entityType.ClrType).HasQueryFilter(filter);
                builder.Entity(entityType.ClrType).HasIndex("IsDeleted");
            }
        }
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateTimestamps();
        var result = await base.SaveChangesAsync(cancellationToken);
        await DispatchDomainEvents();
        return result;
    }

    private void UpdateTimestamps()
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
    }

    private async Task DispatchDomainEvents()
    {
        var entities = ChangeTracker.Entries<BaseEntity>()
            .Where(e => e.Entity.DomainEvents.Any())
            .Select(e => e.Entity)
            .ToList();

        var domainEvents = entities
            .SelectMany(e => e.DomainEvents)
            .ToList();

        foreach (var entity in entities)
        {
            entity.ClearDomainEvents();
        }

        foreach (var domainEvent in domainEvents)
        {
            await _publisher.Publish(domainEvent);
        }
    }
}
