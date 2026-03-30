import '../../core/constants/constants.dart';
import '../models/review.dart';
import '../models/loyalty.dart';
import 'api_service.dart';

/// Service for Reviews and Loyalty API calls
class Phase3Service {
  final ApiService _apiService = ApiService();

  // ==================== REVIEWS ====================

  /// Get reviews for a menu item
  Future<List<Review>> getItemReviews(int menuItemId) async {
    final response = await _apiService.get<List>(
      '${ApiConstants.reviewsItem}/$menuItemId',
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => Review.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Get review summary for a menu item
  Future<ReviewSummary> getItemReviewSummary(int menuItemId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConstants.reviewsItem}/$menuItemId/summary',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return ReviewSummary.fromJson(response.data!);
    }
    
    return ReviewSummary(
      menuItemId: menuItemId,
      averageRating: 0,
      totalReviews: 0,
      fiveStarCount: 0,
      fourStarCount: 0,
      threeStarCount: 0,
      twoStarCount: 0,
      oneStarCount: 0,
    );
  }

  /// Get current user's reviews
  Future<List<Review>> getMyReviews() async {
    final response = await _apiService.get<List>(
      ApiConstants.reviewsMy,
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => Review.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Create a new review
  Future<Review?> createReview(CreateReviewRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.reviews,
      body: request.toJson(),
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return Review.fromJson(response.data!);
    }
    return null;
  }

  /// Check if user can review an item
  Future<bool> canReviewItem(int orderId, int menuItemId) async {
    final response = await _apiService.get<bool>(
      ApiConstants.reviewsCanReview,
      queryParams: {'orderId': orderId, 'menuItemId': menuItemId},
      fromJson: (data) => data as bool,
    );

    return response.success && response.data == true;
  }

  // ==================== LOYALTY ====================

  /// Get current user's loyalty points
  Future<LoyaltyPoints?> getMyPoints() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.loyalty,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return LoyaltyPoints.fromJson(response.data!);
    }
    return null;
  }

  /// Get loyalty points for a specific user (demo)
  Future<LoyaltyPoints?> getUserPoints(String userId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConstants.loyalty}/user/$userId',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return LoyaltyPoints.fromJson(response.data!);
    }
    return null;
  }

  /// Get transaction history
  Future<List<LoyaltyTransaction>> getTransactionHistory({int? limit}) async {
    final response = await _apiService.get<List>(
      ApiConstants.loyaltyHistory,
      queryParams: {if (limit != null) 'limit': limit},
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => LoyaltyTransaction.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Redeem points for a discount
  Future<RedeemResult?> redeemPoints(RedeemPointsRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.loyaltyRedeem,
      body: request.toJson(),
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return RedeemResult.fromJson(response.data!);
    }
    return null;
  }

  /// Get loyalty tier information
  Future<List<LoyaltyTier>> getTiers() async {
    final response = await _apiService.get<List>(
      ApiConstants.loyaltyTiers,
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => LoyaltyTier.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Calculate discount for a given number of points
  Future<double> calculateDiscount(int points) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.loyaltyCalculateDiscount,
      queryParams: {'points': points},
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return (response.data!['discountAmount'] ?? 0).toDouble();
    }
    return 0;
  }

  // ==================== FAVORITES ====================

  /// Get current user's favorites
  Future<List<dynamic>> getFavorites() async {
    final response = await _apiService.get<List>(
      ApiConstants.favorites,
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }
    return [];
  }

  /// Check if an item is in favorites
  Future<bool> isFavorite(int menuItemId) async {
    final response = await _apiService.get<bool>(
      '${ApiConstants.favoritesCheck}/$menuItemId',
      fromJson: (data) => data as bool,
    );

    return response.success && response.data == true;
  }

  /// Add item to favorites
  Future<bool> addFavorite(int menuItemId) async {
    final response = await _apiService.post(
      '${ApiConstants.favorites}/$menuItemId',
    );
    return response.success;
  }

  /// Remove item from favorites
  Future<bool> removeFavorite(int menuItemId) async {
    final response = await _apiService.delete(
      '${ApiConstants.favorites}/$menuItemId',
    );
    return response.success;
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(int menuItemId) async {
    final response = await _apiService.post<bool>(
      '${ApiConstants.favorites}/$menuItemId/toggle',
      fromJson: (data) => data as bool,
    );

    return response.success && response.data == true;
  }

  /// Get favorite count
  Future<int> getFavoriteCount() async {
    final response = await _apiService.get<int>(
      ApiConstants.favoritesCount,
      fromJson: (data) => data as int,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }
    return 0;
  }

  // Deprecated: Auth token is now handled globally by ApiService interceptor
  void setAuthToken(String token) {}
}
