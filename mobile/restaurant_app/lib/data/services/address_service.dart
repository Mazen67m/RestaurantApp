import '../../core/constants/constants.dart';
import '../models/address.dart';
import 'api_service.dart';

/// Service for address-related API calls
class AddressService {
  final ApiService _apiService = ApiService();

  /// Get all addresses for current user
  Future<List<Address>> getAddresses() async {
    try {
      final response = await _apiService.get<List>(
        ApiConstants.addresses,
        fromJson: (data) => data as List,
      );

      if (response.success && response.data != null) {
        return response.data!.map((item) => Address.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get address by ID
  Future<Address?> getAddressById(int id) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConstants.addresses}/$id',
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        return Address.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create new address
  Future<Address?> createAddress(Address address) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.addresses,
        body: address.toJson(),
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        return Address.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update existing address
  Future<Address?> updateAddress(int id, Address address) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '${ApiConstants.addresses}/$id',
        body: address.toJson(),
        fromJson: (data) => data,
      );

      if (response.success && response.data != null) {
        return Address.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete address
  Future<bool> deleteAddress(int id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.addresses}/$id',
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Set address as default
  Future<bool> setDefaultAddress(int id) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.addresses}/$id/set-default',
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
