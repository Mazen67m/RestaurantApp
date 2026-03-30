using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using RestaurantApp.API.Hubs;
using RestaurantApp.Infrastructure;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using Serilog;
using FluentValidation;
using FluentValidation.AspNetCore;
using RestaurantApp.API.Middleware;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Hangfire;
using RestaurantApp.Application;


// CRITICAL: Clear default claim type mappings to prevent JWT handler from transforming claims
JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

// Configure Serilog
Serilog.Log.Logger = new Serilog.LoggerConfiguration()
    .MinimumLevel.Override("Microsoft", Serilog.Events.LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File(new Serilog.Formatting.Compact.CompactJsonFormatter(), "logs/api-log.json", rollingInterval: Serilog.RollingInterval.Day)
    .CreateLogger();

var builder = WebApplication.CreateBuilder(args);
builder.Host.UseSerilog();

// Configure Kestrel with request size limits to prevent DoS attacks
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 10 * 1024 * 1024; // 10MB global limit
    options.Limits.MaxRequestLineSize = 8192; // 8KB max request line
    options.Limits.MaxRequestHeadersTotalSize = 32768; // 32KB max headers
});

// Add services to the container
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
    });

// Add ProblemDetails for RFC 7807 error responses
builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = context =>
    {
        context.ProblemDetails.Instance = context.HttpContext.Request.Path;
        context.ProblemDetails.Extensions["traceId"] = context.HttpContext.TraceIdentifier;
    };
});

// Add FluentValidation
builder.Services.AddValidatorsFromAssemblyContaining<RestaurantApp.Application.Validators.Order.CreateOrderDtoValidator>();
builder.Services.AddFluentValidationAutoValidation();

// Configure API Behavior for validation errors with ProblemDetails
builder.Services.Configure<Microsoft.AspNetCore.Mvc.ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState
            .Where(e => e.Value?.Errors.Count > 0)
            .SelectMany(e => e.Value!.Errors.Select(x => x.ErrorMessage))
            .ToList();

        var problemDetails = RestaurantApp.Application.Common.ProblemDetailsFactory
            .CreateValidationProblem("Validation failed", errors, context.HttpContext.Request.Path);

        return new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(problemDetails);
    };
});

// Register Domain Services
builder.Services.AddScoped<RestaurantApp.Application.Services.OrderPricingService>();
builder.Services.AddScoped<RestaurantApp.Application.Services.CouponValidationService>();

// Register Use Cases
builder.Services.AddScoped<RestaurantApp.Infrastructure.UseCases.Orders.CreateOrderUseCase>();
builder.Services.AddScoped<RestaurantApp.Infrastructure.UseCases.Orders.UpdateOrderStatusUseCase>();



// Distributed Cache (Redis in production, Memory in development)
if (builder.Environment.IsProduction())
{
    var redisConnection = builder.Configuration.GetConnectionString("Redis");
    if (!string.IsNullOrEmpty(redisConnection))
    {
        builder.Services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = redisConnection;
            options.InstanceName = "RestaurantApp:";
        });
    }
    else
    {
        // Fallback to memory cache if Redis not configured
        builder.Services.AddDistributedMemoryCache();
    }
}
else
{
    // Use in-memory cache for development
    builder.Services.AddDistributedMemoryCache();
}


// Add Infrastructure services (DbContext, Identity, Services)
builder.Services.AddInfrastructure(builder.Configuration);

// Add Application services (MediatR, Handlers)
builder.Services.AddApplication();

// Add MediatR and scan assemblies
builder.Services.AddMediatR(cfg => {
    cfg.RegisterServicesFromAssemblies(
        typeof(RestaurantApp.Application.DependencyInjection).Assembly,
        typeof(RestaurantApp.Infrastructure.DependencyInjection).Assembly
    );
});

// Add Hangfire
builder.Services.AddHangfire(configuration => configuration
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseSqlServerStorage(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddHangfireServer();

// JWT Authentication
var jwtKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY") 
             ?? builder.Configuration["Jwt:Key"];

// Only validate in production - development can use appsettings key
if (builder.Environment.IsProduction() && 
    (string.IsNullOrEmpty(jwtKey) || jwtKey == "REPLACE_WITH_ENV_VARIABLE_IN_PRODUCTION"))
{
    throw new InvalidOperationException(
        "JWT Secret Key is not configured for production. Set JWT_SECRET_KEY environment variable.");
}

if (string.IsNullOrEmpty(jwtKey))
{
    throw new InvalidOperationException(
        "JWT Secret Key is not configured. Check appsettings.Development.json or set JWT_SECRET_KEY environment variable.");
}

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtKey)),
        RoleClaimType = ClaimTypes.Role
    };
});

// Swagger/OpenAPI - Enhanced Documentation
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "Restaurant App API", 
        Version = "v1.0",
        Description = @"
            **Food Ordering System API**
            
            Complete RESTful API for restaurant management and food ordering.
            
            **Features:**
            - User Authentication & Authorization
            - Menu Management (Categories & Items)
            - Order Processing & Tracking
            - Branch Management
            - Delivery System
            - Loyalty Points & Rewards
            - Reviews & Ratings
            - Offers & Coupons
            
            **Security:** All admin endpoints require JWT authentication with Admin role.
            
            **Error Responses:** This API uses RFC 7807 ProblemDetails for error responses.
        ",
        Contact = new OpenApiContact
        {
            Name = "Restaurant App Support",
            Email = "support@restaurantapp.com"
        },
        License = new OpenApiLicense
        {
            Name = "MIT License"
        }
    });
    
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });

    // Enable XML documentation
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = System.IO.Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (System.IO.File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }

    // Enable examples from Swashbuckle.AspNetCore.Filters
    // TODO: Uncomment after installing Swashbuckle.AspNetCore.Filters package
    // c.ExampleFilters();
});

// Register Swagger example providers
// TODO: Uncomment after installing Swashbuckle.AspNetCore.Filters package
// builder.Services.AddSwaggerExamplesFromAssemblyOf<RestaurantApp.API.Swagger.CreateOrderDtoExample>();


// CORS - Environment-based configuration
builder.Services.AddCors(options =>
{
    // Development: Allow all for easier testing
    options.AddPolicy("Development", policy =>
    {
        policy.SetIsOriginAllowed(_ => true)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
    
    // Production: Restrict to known origins
    options.AddPolicy("Production", policy =>
    {
        var allowedOrigins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() 
                           ?? new[] { "http://localhost:5119" };
        
        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

// Rate Limiting
builder.Services.AddRateLimiter(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 2,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst
            }));

    options.AddFixedWindowLimiter("AuthPolicy", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueLimit = 0;
    });
            
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
});

// SignalR for real-time updates
var signalRBuilder = builder.Services.AddSignalR();

// Use Redis backplane in production for horizontal scaling
if (builder.Environment.IsProduction())
{
    var redisConnection = builder.Configuration.GetConnectionString("Redis");
    if (!string.IsNullOrEmpty(redisConnection))
    {
        signalRBuilder.AddStackExchangeRedis(redisConnection, options =>
        {
            options.Configuration.ChannelPrefix = StackExchange.Redis.RedisChannel.Literal("RestaurantApp");
        });
    }
}

builder.Services.AddScoped<RestaurantApp.API.Services.IAdminNotificationService, RestaurantApp.API.Services.AdminNotificationService>();
builder.Services.AddScoped<RestaurantApp.Application.Interfaces.IOrderNotificationService, RestaurantApp.API.Services.OrderNotificationService>();

// Health Checks - Enhanced for production monitoring
builder.Services.AddHealthChecks()
    .AddDbContextCheck<RestaurantApp.Infrastructure.Data.ApplicationDbContext>(
        name: "database",
        failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Degraded,
        tags: new[] { "db", "sql", "sqlserver" })
    .AddSqlServer(
        connectionString: builder.Configuration.GetConnectionString("DefaultConnection")!,
        name: "sql-server",
        failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Unhealthy,
        tags: new[] { "db", "sql", "sqlserver" })
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy(
        $"API running. Uptime: {DateTime.UtcNow - System.Diagnostics.Process.GetCurrentProcess().StartTime.ToUniversalTime():g}"), 
        tags: new[] { "api" })
    .AddCheck("memory", () =>
    {
        var allocated = GC.GetTotalMemory(false);
        var threshold = 1024L * 1024L * 1024L; // 1GB threshold
        
        return allocated < threshold
            ? Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy($"Memory: {allocated / 1024 / 1024}MB")
            : Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Degraded($"High memory usage: {allocated / 1024 / 1024}MB");
    }, tags: new[] { "api", "memory" });


// TODO: Add Redis health check when AspNetCore.HealthChecks.Redis package is installed
// if (builder.Environment.IsProduction())
// {
//     var redisConnection = builder.Configuration.GetConnectionString("Redis");
//     if (!string.IsNullOrEmpty(redisConnection))
//     {
//         builder.Services.AddHealthChecks()
//             .AddRedis(redisConnection, name: "redis-cache", tags: new[] { "cache", "redis" });
//     }
// }

// OpenTelemetry Distributed Tracing
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource
        .AddService(serviceName: "RestaurantApp.API", serviceVersion: "1.0.0"))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation(options =>
        {
            options.RecordException = true;
            options.Filter = (httpContext) =>
            {
                // Exclude health check endpoints from tracing
                return !httpContext.Request.Path.StartsWithSegments("/health");
            };
        })
        .AddHttpClientInstrumentation()
        .AddSqlClientInstrumentation(options =>
        {
            options.SetDbStatementForText = true;
            options.RecordException = true;
        }));
        // .AddConsoleExporter()); // Disabled for cleaner logs - Use OTLP exporter in production

// API Versioning
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new Asp.Versioning.ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
    options.ApiVersionReader = Asp.Versioning.ApiVersionReader.Combine(
        new Asp.Versioning.QueryStringApiVersionReader("api-version"),
        new Asp.Versioning.HeaderApiVersionReader("X-API-Version"));
});

var app = builder.Build();

// Log JWT configuration
app.Logger.LogInformation("JWT Config - Issuer: {Issuer}", builder.Configuration["Jwt:Issuer"]);
app.Logger.LogInformation("JWT Config - Audience: {Audience}", builder.Configuration["Jwt:Audience"]);
var sensitiveKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY") ?? builder.Configuration["Jwt:Key"];
var keyDisplay = string.IsNullOrEmpty(sensitiveKey) ? "NULL" : $"{sensitiveKey.Substring(0, Math.Min(5, sensitiveKey.Length))}...";
app.Logger.LogInformation("JWT Config - Key Used: {Key}", keyDisplay);

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Restaurant App API v1");
    });
}

// Request/Response logging for monitoring
app.UseMiddleware<RestaurantApp.API.Middleware.RequestResponseLoggingMiddleware>();

// Correlation ID for distributed tracing
app.UseCorrelationId();

// Security Headers
app.UseSecurityHeaders();

// Global exception handling - must be early in pipeline
app.UseMiddleware<RestaurantApp.API.Middleware.ExceptionHandlingMiddleware>();

app.UseHttpsRedirection();
app.UseStaticFiles(); // Enable static tools (images, etc)

// Use environment-specific CORS policy
var corsPolicy = app.Environment.IsDevelopment() ? "Development" : "Production";
app.UseCors(corsPolicy);

app.UseRateLimiter();

app.UseAuthentication();
app.UseTokenBlacklist();
app.UseAuthorization();
app.UseHangfireDashboard();

app.MapControllers();

// Map SignalR Hubs
app.MapHub<OrderHub>("/hubs/orders");

// Health Check Endpoints - Enhanced with detailed responses
app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = System.Text.Json.JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            timestamp = DateTime.UtcNow,
            duration = report.TotalDuration,
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration,
                exception = e.Value.Exception?.Message,
                data = e.Value.Data
            })
        });
        await context.Response.WriteAsync(result);
    }
});

// Separate endpoints for Kubernetes-style health checks
app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("db") || check.Tags.Contains("cache")
});

app.MapHealthChecks("/health/live", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("api")
});

// Seed initial data
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var logger = services.GetRequiredService<ILogger<Program>>();
        try
        {
            logger.LogInformation("Starting database seeding...");
            await DbInitializer.InitializeAsync(services);
            logger.LogInformation("Database seeding completed successfully!");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred while seeding the database.");
            // Don't throw - allow the application to continue
        }
}

app.Run();
