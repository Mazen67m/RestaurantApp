using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Entities;
using RestaurantApp.Infrastructure.Data;
using RestaurantApp.Infrastructure.Services;
using RestaurantApp.Infrastructure.Services.Orders;

using RestaurantApp.Infrastructure.Repositories;

namespace RestaurantApp.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Database
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("DefaultConnection"),
                sqlServerOptions => {
                    sqlServerOptions.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName);
                    sqlServerOptions.EnableRetryOnFailure(
                        maxRetryCount: 5,
                        maxRetryDelay: TimeSpan.FromSeconds(30),
                        errorNumbersToAdd: null);
                    sqlServerOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
                    sqlServerOptions.CommandTimeout(30);
                }));

        // Identity
        services.AddIdentity<ApplicationUser, IdentityRole<int>>(options =>
        {
            // PRODUCTION SECURITY: Strengthened password policy (12+ chars)
            options.Password.RequireDigit = true;
            options.Password.RequireLowercase = true;
            options.Password.RequireUppercase = true;
            options.Password.RequireNonAlphanumeric = true; // Required for production
            options.Password.RequiredLength = 12;
            
            options.User.RequireUniqueEmail = true;
            
            // PRODUCTION SECURITY: Email confirmation now REQUIRED
            // Users must verify their email before they can sign in
            options.SignIn.RequireConfirmedEmail = true;
            
            options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
            options.Lockout.MaxFailedAccessAttempts = 5;
        })
        .AddEntityFrameworkStores<ApplicationDbContext>()
        .AddDefaultTokenProviders();

        // Services
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IRestaurantService, RestaurantService>();
        services.AddScoped<IMenuService, MenuService>();
        services.AddScoped<IOrderCreationService, OrderCreationService>();
        services.AddScoped<IOrderQueryService, OrderQueryService>();
        services.AddScoped<IOrderLifecycleService, OrderLifecycleService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<IAddressService, AddressService>();
        services.AddScoped<IEmailService, EmailService>();
        
        // Phase 3 Services
        services.AddScoped<IReviewService, ReviewService>();
        services.AddScoped<ILoyaltyService, LoyaltyService>();
        
        // Delivery Management
        services.AddScoped<IDeliveryService, DeliveryService>();
        
        // Admin Services
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<IOfferService, OfferService>();
        services.AddScoped<IAuditService, AuditService>();
        
        // Security Services
        services.AddScoped<IResourceAuthorizationService, ResourceAuthorizationService>();
        
        // Performance Services
        services.AddScoped<ICacheService, CacheService>();
        
        // Repositories
        services.AddScoped(typeof(IRepository<>), typeof(GenericRepository<>));
        services.AddScoped<IOrderRepository, OrderRepository>();

        // Security: Token Blacklist
        services.AddScoped<ITokenBlacklistService, TokenBlacklistService>();


        return services;
    }
}
