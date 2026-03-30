import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/constants/constants.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.token);
  }

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _apiService.hasToken();
      if (hasToken) {
        await getProfile();
        // Register device for notifications
        NotificationService().registerDeviceWithBackend();
      }
    } catch (e) {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.login,
        body: {'email': email, 'password': password},
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        await _saveAuthData(authResponse);
        await getProfile();
        _isAuthenticated = true;
        NotificationService().registerDeviceWithBackend();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String preferredLanguage = 'ar',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.register,
        body: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'preferredLanguage': preferredLanguage,
        },
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        await _saveAuthData(authResponse);
        await getProfile();
        _isAuthenticated = true;
        NotificationService().registerDeviceWithBackend();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> getProfile() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.profile,
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        _user = User.fromJson(response.data!);
        _isAuthenticated = true;
      }
    } catch (e) {
      // Silent fail
    }
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    required String preferredLanguage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiConstants.profile,
        body: {
          'fullName': fullName,
          'phone': phone,
          'preferredLanguage': preferredLanguage,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        _user = User.fromJson(response.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Update failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConstants.forgotPassword,
        body: {'email': email},
      );

      _isLoading = false;
      if (!response.success) {
        _error = response.message ?? 'Error sending reset code';
      }
      notifyListeners();
      return response.success;
    } catch (e) {
      _error = 'Connection error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConstants.resetPassword,
        body: {
          'email': email,
          'token': code,
          'newPassword': newPassword,
        },
      );

      _isLoading = false;
      if (!response.success) {
        _error = response.message ?? 'Password reset failed';
      }
      notifyListeners();
      return response.success;
    } catch (e) {
      _error = 'Connection error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConstants.changePassword,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      _isLoading = false;
      if (!response.success) {
        _error = response.message ?? 'Password change failed';
      }
      notifyListeners();
      return response.success;
    } catch (e) {
      _error = 'Connection error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    await _storage.deleteAll();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _apiService.saveToken(authResponse.token);
    await _storage.write(
      key: StorageKeys.userId,
      value: authResponse.userId.toString(),
    );
    await _storage.write(key: StorageKeys.userEmail, value: authResponse.email);
    await _storage.write(key: StorageKeys.userName, value: authResponse.fullName);
    await _storage.write(key: StorageKeys.userRole, value: authResponse.role);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
