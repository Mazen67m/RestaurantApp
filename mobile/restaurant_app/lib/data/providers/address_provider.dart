import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../services/address_service.dart';

/// Provider for address management
class AddressProvider with ChangeNotifier {
  final AddressService _addressService = AddressService();
  
  List<Address> _addresses = [];
  Address? _selectedAddress;
  bool _isLoading = false;
  String? _error;

  List<Address> get addresses => _addresses;
  Address? get selectedAddress => _selectedAddress;
  Address? get defaultAddress => _addresses.firstWhere(
    (addr) => addr.isDefault,
    orElse: () => _addresses.isNotEmpty ? _addresses.first : Address(
      id: 0,
      label: '',
      street: '',
      building: '',
      floor: '',
      apartment: '',
      city: '',
      area: '',
      latitude: 0,
      longitude: 0,
      isDefault: false,
    ),
  );
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAddresses => _addresses.isNotEmpty;

  /// Load all addresses
  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _addressService.getAddresses();
      
      // Auto-select default address if none selected
      if (_selectedAddress == null && _addresses.isNotEmpty) {
        _selectedAddress = defaultAddress;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new address
  Future<bool> addAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAddress = await _addressService.createAddress(address);
      if (newAddress != null) {
        _addresses.add(newAddress);
        
        // If it's the first address or marked as default, select it
        if (_addresses.length == 1 || newAddress.isDefault) {
          _selectedAddress = newAddress;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update existing address
  Future<bool> updateAddress(int id, Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _addressService.updateAddress(id, address);
      if (updated != null) {
        final index = _addresses.indexWhere((addr) => addr.id == id);
        if (index != -1) {
          _addresses[index] = updated;
          
          // Update selected address if it was the one updated
          if (_selectedAddress?.id == id) {
            _selectedAddress = updated;
          }
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete address
  Future<bool> deleteAddress(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _addressService.deleteAddress(id);
      if (success) {
        _addresses.removeWhere((addr) => addr.id == id);
        
        // Clear selection if deleted address was selected
        if (_selectedAddress?.id == id) {
          _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set address as default
  Future<bool> setDefaultAddress(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _addressService.setDefaultAddress(id);
      if (success) {
        // Update local state
        _addresses = _addresses.map((addr) {
          return Address(
            id: addr.id,
            label: addr.label,
            street: addr.street,
            building: addr.building,
            floor: addr.floor,
            apartment: addr.apartment,
            city: addr.city,
            area: addr.area,
            latitude: addr.latitude,
            longitude: addr.longitude,
            isDefault: addr.id == id,
            additionalDirections: addr.additionalDirections,
          );
        }).toList();
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select an address
  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Clear selected address
  void clearSelection() {
    _selectedAddress = null;
    notifyListeners();
  }
}
