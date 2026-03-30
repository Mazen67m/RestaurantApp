import 'dart:math' as math;
import '../../core/constants/constants.dart';
import '../models/branch.dart';
import 'api_service.dart';

/// Service for branch-related API calls
class BranchService {
  final ApiService _apiService = ApiService();

  /// Get all branches
  Future<List<Branch>> getBranches({double? latitude, double? longitude}) async {
    final response = await _apiService.get<List>(
      ApiConstants.branches,
      queryParams: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => Branch.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Get branch by ID
  Future<Branch?> getBranchById(int id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConstants.branches}/$id',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return Branch.fromJson(response.data!);
    }
    return null;
  }

  /// Get nearest branch based on user location
  Future<Branch?> getNearestBranch(double latitude, double longitude) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConstants.nearestBranch,
      queryParams: {
        'latitude': latitude,
        'longitude': longitude,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return Branch.fromJson(response.data!);
    }
    return null;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Deprecated: Auth token is now handled globally by ApiService interceptor
  void setAuthToken(String token) {}
}
