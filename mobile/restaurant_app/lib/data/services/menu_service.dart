import '../../core/constants/constants.dart';
import '../models/menu_model.dart';
import 'api_service.dart';

/// Service for menu-related API calls
class MenuService {
  final ApiService _apiService = ApiService();

  /// Get all menu categories
  Future<List<MenuCategory>> getCategories() async {
    final response = await _apiService.get<List>(
      ApiConstants.menuCategories,
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => MenuCategory.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Get category by ID
  Future<MenuCategory?> getCategoryById(int id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConstants.menuCategories}/$id',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return MenuCategory.fromJson(response.data!);
    }
    return null;
  }

  /// Get items by category
  Future<List<MenuItem>> getItemsByCategory(int categoryId) async {
    final response = await _apiService.get<List>(
      '${ApiConstants.menuCategories}/$categoryId/items',
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => MenuItem.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Get all menu items
  Future<List<MenuItem>> getAllItems() async {
    final response = await _apiService.get<List>(
      ApiConstants.menuItems,
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => MenuItem.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Get menu item by ID
  Future<MenuItem?> getItemById(int id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConstants.menuItems}/$id',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return MenuItem.fromJson(response.data!);
    }
    return null;
  }

  /// Search menu items
  Future<List<MenuItem>> searchItems(String query) async {
    final response = await _apiService.get<List>(
      ApiConstants.menuSearch,
      queryParams: {'q': query},
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => MenuItem.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Get popular items
  Future<List<MenuItem>> getPopularItems({int count = 10}) async {
    final response = await _apiService.get<List>(
      ApiConstants.menuPopular,
      queryParams: {'count': count},
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => MenuItem.fromJson(item))
          .toList();
    }
    return [];
  }

  // Deprecated: Auth token is now handled globally by ApiService interceptor
  void setAuthToken(String token) {}
}
