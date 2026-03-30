import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';

/// Provider for branch selection and management
class BranchProvider with ChangeNotifier {
  final BranchService _branchService = BranchService();
  
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  bool _isLoading = false;
  String? _error;

  List<Branch> get branches => _branches;
  Branch? get selectedBranch => _selectedBranch;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBranches => _branches.isNotEmpty;

  /// Load all branches
  Future<void> loadBranches({double? userLat, double? userLon}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var allBranches = await _branchService.getBranches(
        latitude: userLat,
        longitude: userLon,
      );

      // Filter to only show active branches that are accepting orders
      _branches = allBranches.where((branch) => 
        branch.isActive && branch.acceptingOrders
      ).toList();

      // If user location provided, calculate distances
      if (userLat != null && userLon != null) {
        _branches = _branches.map((branch) {
          final distance = _branchService.calculateDistance(
            userLat,
            userLon,
            branch.latitude,
            branch.longitude,
          );
          return branch.copyWith(distanceKm: distance);
        }).toList();

        // Sort by distance
        _branches.sort((a, b) => 
          (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity)
        );
      }

      // Auto-select nearest branch if none selected
      if (_selectedBranch == null && _branches.isNotEmpty) {
        _selectedBranch = _branches.first;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a branch
  void selectBranch(Branch branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  /// Get nearest branch based on user location
  Future<void> selectNearestBranch(double latitude, double longitude) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nearest = await _branchService.getNearestBranch(latitude, longitude);
      if (nearest != null) {
        _selectedBranch = nearest;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear selected branch
  void clearSelection() {
    _selectedBranch = null;
    notifyListeners();
  }

  /// Set auth token for API calls
  void setAuthToken(String token) {
    _branchService.setAuthToken(token);
  }
}
