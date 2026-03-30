using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.DTOs.Restaurant;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Infrastructure.Data;

namespace RestaurantApp.Infrastructure.Services;

public class RestaurantService : IRestaurantService
{
    private readonly ApplicationDbContext _context;
    private readonly ICacheService _cacheService;

    public RestaurantService(ApplicationDbContext context, ICacheService cacheService)
    {
        _context = context;
        _cacheService = cacheService;
    }

    public async Task<ApiResponse<RestaurantDto>> GetRestaurantAsync()
    {
        var cacheKey = "restaurant_info";
        var cached = await _cacheService.GetAsync<RestaurantDto>(cacheKey);
        if (cached != null) return ApiResponse<RestaurantDto>.SuccessResponse(cached);

        var restaurant = await _context.Restaurants
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.IsActive);

        if (restaurant == null)
        {
            return ApiResponse<RestaurantDto>.ErrorResponse("Restaurant not found");
        }

        var dto = new RestaurantDto(
            restaurant.Id,
            restaurant.NameAr,
            restaurant.NameEn,
            restaurant.DescriptionAr,
            restaurant.DescriptionEn,
            restaurant.LogoUrl,
            restaurant.CoverImageUrl,
            restaurant.PrimaryColor,
            restaurant.SecondaryColor,
            restaurant.Phone,
            restaurant.Email,
            restaurant.IsActive
        );

        await _cacheService.SetAsync(cacheKey, dto, TimeSpan.FromHours(24));
        return ApiResponse<RestaurantDto>.SuccessResponse(dto);
    }

    public async Task<ApiResponse<RestaurantDto>> UpdateRestaurantAsync(UpdateRestaurantDto dto)
    {
        var restaurant = await _context.Restaurants.FirstOrDefaultAsync(r => r.IsActive);
        if (restaurant == null)
        {
            return ApiResponse<RestaurantDto>.ErrorResponse("Restaurant not found");
        }

        if (dto.NameAr != null) restaurant.NameAr = dto.NameAr;
        if (dto.NameEn != null) restaurant.NameEn = dto.NameEn;
        if (dto.DescriptionAr != null) restaurant.DescriptionAr = dto.DescriptionAr;
        if (dto.DescriptionEn != null) restaurant.DescriptionEn = dto.DescriptionEn;
        if (dto.LogoUrl != null) restaurant.LogoUrl = dto.LogoUrl;
        if (dto.CoverImageUrl != null) restaurant.CoverImageUrl = dto.CoverImageUrl;
        if (dto.PrimaryColor != null) restaurant.PrimaryColor = dto.PrimaryColor;
        if (dto.SecondaryColor != null) restaurant.SecondaryColor = dto.SecondaryColor;
        if (dto.Phone != null) restaurant.Phone = dto.Phone;
        if (dto.Email != null) restaurant.Email = dto.Email;
        if (dto.IsActive.HasValue) restaurant.IsActive = dto.IsActive.Value;

        await _context.SaveChangesAsync();

        var resultDto = new RestaurantDto(
            restaurant.Id,
            restaurant.NameAr,
            restaurant.NameEn,
            restaurant.DescriptionAr,
            restaurant.DescriptionEn,
            restaurant.LogoUrl,
            restaurant.CoverImageUrl,
            restaurant.PrimaryColor,
            restaurant.SecondaryColor,
            restaurant.Phone,
            restaurant.Email,
            restaurant.IsActive
        );

        return ApiResponse<RestaurantDto>.SuccessResponse(resultDto);
    }

    public async Task<ApiResponse<List<BranchDto>>> GetBranchesAsync(decimal? latitude = null, decimal? longitude = null, bool includeInactive = false)
    {
        var cacheKey = $"branches:{includeInactive}";
        var branches = await _cacheService.GetAsync<List<Domain.Entities.Branch>>(cacheKey);

        if (branches == null)
        {
            var query = _context.Branches.AsQueryable();
            
            if (!includeInactive)
            {
                query = query.Where(b => b.IsActive);
            }

            branches = await query
                .AsNoTracking()
                .OrderBy(b => b.NameEn)
                .ToListAsync();

            await _cacheService.SetAsync(cacheKey, branches, TimeSpan.FromHours(1));
        }

        var dtos = branches.Select(b => new BranchDto(
            b.Id,
            b.RestaurantId,
            b.NameAr,
            b.NameEn,
            b.AddressAr,
            b.AddressEn,
            b.Latitude,
            b.Longitude,
            b.Phone,
            b.DeliveryRadiusKm,
            b.MinOrderAmount,
            b.DeliveryFee,
            b.FreeDeliveryThreshold,
            b.DefaultPreparationTimeMinutes,
            b.OpeningTime.ToString(@"hh\:mm"),
            b.ClosingTime.ToString(@"hh\:mm"),
            b.IsActive,
            b.AcceptingOrders,
            latitude.HasValue && longitude.HasValue 
                ? CalculateDistance((double)latitude.Value, (double)longitude.Value, (double)b.Latitude, (double)b.Longitude)
                : null
        )).ToList();

        // Sort by distance if coordinates provided
        if (latitude.HasValue && longitude.HasValue)
        {
            dtos = dtos.OrderBy(b => b.DistanceKm).ToList();
        }

        return ApiResponse<List<BranchDto>>.SuccessResponse(dtos);
    }

    public async Task<ApiResponse<BranchDto>> GetBranchAsync(int id)
    {
        var branch = await _context.Branches
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == id && b.IsActive);

        if (branch == null)
        {
            return ApiResponse<BranchDto>.ErrorResponse("Branch not found");
        }

        var dto = new BranchDto(
            branch.Id,
            branch.RestaurantId,
            branch.NameAr,
            branch.NameEn,
            branch.AddressAr,
            branch.AddressEn,
            branch.Latitude,
            branch.Longitude,
            branch.Phone,
            branch.DeliveryRadiusKm,
            branch.MinOrderAmount,
            branch.DeliveryFee,
            branch.FreeDeliveryThreshold,
            branch.DefaultPreparationTimeMinutes,
            branch.OpeningTime.ToString(@"hh\:mm"),
            branch.ClosingTime.ToString(@"hh\:mm"),
            branch.IsActive,
            branch.AcceptingOrders
        );

        return ApiResponse<BranchDto>.SuccessResponse(dto);
    }

    public async Task<ApiResponse<BranchDto>> GetNearestBranchAsync(decimal latitude, decimal longitude)
    {
        var branches = await _context.Branches
            .AsNoTracking()
            .Where(b => b.IsActive && b.AcceptingOrders)
            .ToListAsync();

        if (!branches.Any())
        {
            return ApiResponse<BranchDto>.ErrorResponse("No branches available");
        }

        var nearestBranch = branches
            .Select(b => new
            {
                Branch = b,
                Distance = CalculateDistance((double)latitude, (double)longitude, (double)b.Latitude, (double)b.Longitude)
            })
            .OrderBy(x => x.Distance)
            .First();

        // Check if within delivery radius
        if (nearestBranch.Distance > (double)nearestBranch.Branch.DeliveryRadiusKm)
        {
            return ApiResponse<BranchDto>.ErrorResponse("No branches deliver to your location");
        }

        var dto = new BranchDto(
            nearestBranch.Branch.Id,
            nearestBranch.Branch.RestaurantId,
            nearestBranch.Branch.NameAr,
            nearestBranch.Branch.NameEn,
            nearestBranch.Branch.AddressAr,
            nearestBranch.Branch.AddressEn,
            nearestBranch.Branch.Latitude,
            nearestBranch.Branch.Longitude,
            nearestBranch.Branch.Phone,
            nearestBranch.Branch.DeliveryRadiusKm,
            nearestBranch.Branch.MinOrderAmount,
            nearestBranch.Branch.DeliveryFee,
            nearestBranch.Branch.FreeDeliveryThreshold,
            nearestBranch.Branch.DefaultPreparationTimeMinutes,
            nearestBranch.Branch.OpeningTime.ToString(@"hh\:mm"),
            nearestBranch.Branch.ClosingTime.ToString(@"hh\:mm"),
            nearestBranch.Branch.IsActive,
            nearestBranch.Branch.AcceptingOrders,
            nearestBranch.Distance
        );

        return ApiResponse<BranchDto>.SuccessResponse(dto);
    }

    public async Task<ApiResponse<BranchDto>> CreateBranchAsync(CreateBranchDto dto)
    {
        // Get the restaurant ID (assuming first active restaurant)
        var restaurant = await _context.Restaurants.FirstOrDefaultAsync(r => r.IsActive);
        if (restaurant == null)
        {
            return ApiResponse<BranchDto>.ErrorResponse("Restaurant not found");
        }

        var branch = new Domain.Entities.Branch
        {
            RestaurantId = restaurant.Id,
            NameAr = dto.NameAr,
            NameEn = dto.NameEn,
            AddressAr = dto.AddressAr,
            AddressEn = dto.AddressEn,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            Phone = dto.Phone,
            DeliveryRadiusKm = dto.DeliveryRadiusKm,
            MinOrderAmount = dto.MinOrderAmount,
            DeliveryFee = dto.DeliveryFee,
            FreeDeliveryThreshold = dto.FreeDeliveryThreshold,
            DefaultPreparationTimeMinutes = dto.DefaultPreparationTimeMinutes,
            OpeningTime = TimeSpan.Parse(dto.OpeningTime),
            ClosingTime = TimeSpan.Parse(dto.ClosingTime),
            IsActive = dto.IsActive,
            AcceptingOrders = dto.AcceptingOrders
        };

        _context.Branches.Add(branch);
        await _context.SaveChangesAsync();

        var resultDto = new BranchDto(
            branch.Id,
            branch.RestaurantId,
            branch.NameAr,
            branch.NameEn,
            branch.AddressAr,
            branch.AddressEn,
            branch.Latitude,
            branch.Longitude,
            branch.Phone,
            branch.DeliveryRadiusKm,
            branch.MinOrderAmount,
            branch.DeliveryFee,
            branch.FreeDeliveryThreshold,
            branch.DefaultPreparationTimeMinutes,
            branch.OpeningTime.ToString(@"hh\:mm"),
            branch.ClosingTime.ToString(@"hh\:mm"),
            branch.IsActive,
            branch.AcceptingOrders
        );

        return ApiResponse<BranchDto>.SuccessResponse(resultDto);
    }

    public async Task<ApiResponse<BranchDto>> UpdateBranchAsync(int id, UpdateBranchDto dto)
    {
        var branch = await _context.Branches.FindAsync(id);
        if (branch == null)
        {
            return ApiResponse<BranchDto>.ErrorResponse("Branch not found");
        }

        // Update only provided fields
        if (dto.NameAr != null) branch.NameAr = dto.NameAr;
        if (dto.NameEn != null) branch.NameEn = dto.NameEn;
        if (dto.AddressAr != null) branch.AddressAr = dto.AddressAr;
        if (dto.AddressEn != null) branch.AddressEn = dto.AddressEn;
        if (dto.Latitude.HasValue) branch.Latitude = dto.Latitude.Value;
        if (dto.Longitude.HasValue) branch.Longitude = dto.Longitude.Value;
        if (dto.Phone != null) branch.Phone = dto.Phone;
        if (dto.DeliveryRadiusKm.HasValue) branch.DeliveryRadiusKm = dto.DeliveryRadiusKm.Value;
        if (dto.MinOrderAmount.HasValue) branch.MinOrderAmount = dto.MinOrderAmount.Value;
        if (dto.DeliveryFee.HasValue) branch.DeliveryFee = dto.DeliveryFee.Value;
        if (dto.FreeDeliveryThreshold.HasValue) branch.FreeDeliveryThreshold = dto.FreeDeliveryThreshold.Value;
        if (dto.DefaultPreparationTimeMinutes.HasValue) branch.DefaultPreparationTimeMinutes = dto.DefaultPreparationTimeMinutes.Value;
        if (!string.IsNullOrEmpty(dto.OpeningTime)) branch.OpeningTime = TimeSpan.Parse(dto.OpeningTime);
        if (!string.IsNullOrEmpty(dto.ClosingTime)) branch.ClosingTime = TimeSpan.Parse(dto.ClosingTime);
        if (dto.IsActive.HasValue) branch.IsActive = dto.IsActive.Value;
        if (dto.AcceptingOrders.HasValue) branch.AcceptingOrders = dto.AcceptingOrders.Value;

        await _context.SaveChangesAsync();

        var resultDto = new BranchDto(
            branch.Id,
            branch.RestaurantId,
            branch.NameAr,
            branch.NameEn,
            branch.AddressAr,
            branch.AddressEn,
            branch.Latitude,
            branch.Longitude,
            branch.Phone,
            branch.DeliveryRadiusKm,
            branch.MinOrderAmount,
            branch.DeliveryFee,
            branch.FreeDeliveryThreshold,
            branch.DefaultPreparationTimeMinutes,
            branch.OpeningTime.ToString(@"hh\:mm"),
            branch.ClosingTime.ToString(@"hh\:mm"),
            branch.IsActive,
            branch.AcceptingOrders
        );

        return ApiResponse<BranchDto>.SuccessResponse(resultDto);
    }

    public async Task<ApiResponse<bool>> DeleteBranchAsync(int id)
    {
        var branch = await _context.Branches.FindAsync(id);
        if (branch == null)
        {
            return ApiResponse<bool>.ErrorResponse("Branch not found");
        }

        // Soft delete - just mark as inactive
        branch.IsActive = false;
        branch.AcceptingOrders = false;
        await _context.SaveChangesAsync();

        return ApiResponse<bool>.SuccessResponse(true);
    }

    // Haversine formula for distance calculation
    private static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371; // Earth's radius in kilometers

        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return Math.Round(R * c, 2);
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180;
}

