import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, defaultTargetPlatform;
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL - Automatically detects platform
  // Base URL - Automatically detects platform and environment
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api.althawaq-restaurant.com/api'; // production
    }
    if (kIsWeb) return 'http://localhost:5009/api';
    
    // For non-web platforms, we check platform
    if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:5009/api'; // Android Emulator
    }
    return 'http://localhost:5009/api';
  }
  
  // SignalR Hub URL
  static String get signalRUrl {
    if (kReleaseMode) {
      return 'https://api.althawaq-restaurant.com'; // production
    }
    if (kIsWeb) return 'http://localhost:5009';
    
    if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:5009';
    }
    return 'http://localhost:5009';
  }
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String authRefresh = '/auth/refresh-token';
  
  // Device & Push Notifications
  static const String registerDevice = '/devices/register';
  static const String notifications = '/notifications';
  
  // Restaurant endpoints
  static const String restaurant = '/restaurant';
  static const String branches = '/branches';
  static const String nearestBranch = '/branches/nearest';
  
  // Menu endpoints
  static const String menuCategories = '/menu/categories';
  static const String menuItems = '/menu/items';
  static const String menuSearch = '/menu/search';
  static const String menuPopular = '/menu/popular';
  
  // Order endpoints
  static const String orders = '/orders';
  static const String orderTrack = '/orders/{id}/track';
  static const String orderCancel = '/orders/{id}/cancel';
  
  // Address endpoints
  static const String addresses = '/addresses';
  
  // Reviews endpoints (Phase 3)
  static const String reviews = '/reviews';
  static const String reviewsItem = '/reviews/item';
  static const String reviewsMy = '/reviews/my';
  static const String reviewsCanReview = '/reviews/can-review';
  static const String reviewsPending = '/reviews/pending';
  
  // Loyalty endpoints (Phase 3)
  static const String loyalty = '/loyalty';
  static const String loyaltyHistory = '/loyalty/history';
  static const String loyaltyRedeem = '/loyalty/redeem';
  static const String loyaltyTiers = '/loyalty/tiers';
  static const String loyaltyCalculateDiscount = '/loyalty/calculate-discount';
  static const String loyaltyAward = '/loyalty/award';
  
  // Favorites endpoints (Phase 3)
  static const String favorites = '/favorites';
  static const String favoritesCheck = '/favorites/check';
  static const String favoritesCount = '/favorites/count';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String token = 'access_token'; // Alias
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userRole = 'user_role';
  static const String language = 'language';
  static const String cart = 'cart';
  static const String selectedBranch = 'selected_branch';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String cacheCategories = 'cache_categories';
  static const String cachePopularItems = 'cache_popular_items';
}

class AppConstants {
  static const String appName = 'Restaurant App';
  static const String defaultLanguage = 'ar';
  static const List<String> supportedLanguages = ['ar', 'en'];
  
  // Google Maps
  static const String googleMapsApiKey = 'AIzaSyXXXXXXXXXXXXX_PLACEHOLDER';
  
  // Pagination
  static const int defaultPageSize = 10;
  
  // Order status
  static const Map<String, String> orderStatusAr = {
    'Pending': 'قيد الانتظار',
    'Confirmed': 'تم التأكيد',
    'Preparing': 'قيد التحضير',
    'Ready': 'جاهز',
    'OutForDelivery': 'في الطريق',
    'Delivered': 'تم التوصيل',
    'Cancelled': 'ملغي',
  };
  
  static const Map<String, String> orderStatusEn = {
    'Pending': 'Pending',
    'Confirmed': 'Confirmed',
    'Preparing': 'Preparing',
    'Ready': 'Ready',
    'OutForDelivery': 'Out for Delivery',
    'Delivered': 'Delivered',
    'Cancelled': 'Cancelled',
  };
}
