import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant_model.dart';
import '../models/menu_model.dart';
import '../services/api_service.dart';
import '../../core/constants/constants.dart';

class RestaurantProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Restaurant? _restaurant;
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  List<MenuCategory> _categories = [];
  Map<int, List<MenuItem>> _itemsByCategory = {};
  List<MenuItem> _popularItems = [];
  List<MenuItem> _searchResults = [];
  
  bool _isLoading = false;
  String? _error;

  Restaurant? get restaurant => _restaurant;
  List<Branch> get branches => _branches;
  Branch? get selectedBranch => _selectedBranch;
  List<MenuCategory> get categories => _categories;
  List<MenuItem> get popularItems => _popularItems;
  List<MenuItem> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MenuItem> getItemsByCategory(int categoryId) => 
      _itemsByCategory[categoryId] ?? [];

  Future<void> loadRestaurant() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.restaurant,
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        _restaurant = Restaurant.fromJson(response.data!);
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load restaurant';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBranches({double? latitude, double? longitude}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      final response = await _apiService.get<List<dynamic>>(
        ApiConstants.branches,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        _branches = response.data!.map((b) => Branch.fromJson(b)).toList();
        
        // Auto-select first branch if none selected
        if (_selectedBranch == null && _branches.isNotEmpty) {
          _selectedBranch = _branches.first;
        }
      }
    } catch (e) {
      // Silent fail
    }
    notifyListeners();
  }

  Future<Branch?> findNearestBranch(double latitude, double longitude) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.nearestBranch,
        queryParams: {'latitude': latitude, 'longitude': longitude},
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        return Branch.fromJson(response.data!);
      }
    } catch (e) {
      // Return null
    }
    return null;
  }

  void selectBranch(Branch branch) {
    _selectedBranch = branch;
    notifyListeners();
  }
  Future<void> loadCategories() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        ApiConstants.menuCategories,
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        _categories = response.data!.map((c) => MenuCategory.fromJson(c)).toList();
        _saveToCache(StorageKeys.cacheCategories, response.data!);
      } else {
        await _loadCategoriesFromCache();
      }
    } catch (e) {
      await _loadCategoriesFromCache();
    }
    notifyListeners();
  }

  Future<void> _loadCategoriesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(StorageKeys.cacheCategories);
      if (cached != null) {
        final List<dynamic> data = jsonDecode(cached);
        _categories = data.map((c) => MenuCategory.fromJson(c)).toList();
      }
    } catch (_) {}
  }

  Future<void> loadItemsByCategory(int categoryId) async {
    if (_itemsByCategory.containsKey(categoryId) && _itemsByCategory[categoryId]!.isNotEmpty) {
      notifyListeners();
      return;
    }

    try {
      final response = await _apiService.get<List<dynamic>>(
        '${ApiConstants.menuCategories}/$categoryId/items',
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        _itemsByCategory[categoryId] = 
            response.data!.map((i) => MenuItem.fromJson(i)).toList();
        _saveToCache('cache_category_$categoryId', response.data!);
      } else {
        await _loadItemsFromCache(categoryId);
      }
    } catch (e) {
      await _loadItemsFromCache(categoryId);
    }
    notifyListeners();
  }

  Future<void> _loadItemsFromCache(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cache_category_$categoryId');
      if (cached != null) {
        final List<dynamic> data = jsonDecode(cached);
        _itemsByCategory[categoryId] = data.map((i) => MenuItem.fromJson(i)).toList();
      }
    } catch (_) {}
  }

  Future<MenuItem?> getItemDetails(int itemId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConstants.menuItems}/$itemId',
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        return MenuItem.fromJson(response.data!);
      }
    } catch (e) {
      // Return null
    }
    return null;
  }
  Future<void> loadPopularItems({int count = 10}) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        ApiConstants.menuPopular,
        queryParams: {'count': count},
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        _popularItems = response.data!.map((i) => MenuItem.fromJson(i)).toList();
        _saveToCache(StorageKeys.cachePopularItems, response.data!);
      } else {
        await _loadPopularItemsFromCache();
      }
    } catch (e) {
      await _loadPopularItemsFromCache();
    }
    notifyListeners();
  }

  Future<void> _loadPopularItemsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(StorageKeys.cachePopularItems);
      if (cached != null) {
        final List<dynamic> data = jsonDecode(cached);
        _popularItems = data.map((i) => MenuItem.fromJson(i)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> searchItems(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      final response = await _apiService.get<List<dynamic>>(
        ApiConstants.menuSearch,
        queryParams: {'q': query},
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        _searchResults = response.data!.map((i) => MenuItem.fromJson(i)).toList();
      }
    } catch (e) {
      _searchResults = [];
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadRestaurant(),
      loadBranches(),
      loadCategories(),
      loadPopularItems(),
    ]);

    _isLoading = false;
    notifyListeners();
  }
}
