import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import '../../../core/models/api_response.dart';

class AddressProvider extends ChangeNotifier {
  final AddressService _addressService = AddressService();
  
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;
  AddressModel? _selectedAddress;
  AddressModel? _defaultAddress;
  
  // Getters
  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AddressModel? get selectedAddress => _selectedAddress;
  AddressModel? get defaultAddress => _defaultAddress;
  bool get hasAddresses => _addresses.isNotEmpty;
  
  // Get non-current location addresses (saved addresses only)
  List<AddressModel> get savedAddresses => 
      _addresses.where((address) => address.id != 'current_location').toList();
  
  /// Fetch all addresses from the server
  Future<void> fetchAddresses() async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _addressService.getAddresses();
      
      if (response.success && response.data != null) {
        _addresses = response.data!;
        
        // Find default address
        _defaultAddress = _addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => _addresses.isNotEmpty ? _addresses.first : AddressModel.currentLocation(),
        );
        
        // If no selected address, use default
        _selectedAddress ??= _defaultAddress;
        
        _setError(null);
      } else {
        _setError(response.message ?? 'Failed to fetch addresses');
      }
    } catch (e) {
      _setError('An error occurred while fetching addresses: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Add a new address
  Future<bool> addAddress({
    required String label,
    required String fullAddress,
    required String street,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required double latitude,
    required double longitude,
    required String type,
    required int countryId,
    bool isDefault = false,
    String? building,
    String? floor,
    String? apartment,
    String? landmark,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final addressTypeId = AddressService.getAddressTypeId(type);
      
      final response = await _addressService.addAddress(
        address: fullAddress,
        street: street,
        city: city,
        state: state,
        country: country,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        addressType: addressTypeId,
        countryId: countryId,
        isPrimary: isDefault,
        building: building,
        floor: floor,
        apartment: apartment,
        landmark: landmark,
      );
      
      if (response.success && response.data != null) {
        // Add the new address to local list
        _addresses.add(response.data!);
        
        // If this is set as default, update default address
        if (isDefault) {
          _updateDefaultAddress(response.data!);
        }
        
        _setError(null);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to add address');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while adding address: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Update an existing address
  Future<bool> updateAddress({
    required String addressId,
    required String label,
    required String fullAddress,
    required String street,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required double latitude,
    required double longitude,
    required String type,
    required int countryId,
    bool isDefault = false,
    String? building,
    String? floor,
    String? apartment,
    String? landmark,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final addressTypeId = AddressService.getAddressTypeId(type);
      
      final response = await _addressService.updateAddress(
        addressId: addressId,
        address: fullAddress,
        street: street,
        city: city,
        state: state,
        country: country,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        addressType: addressTypeId,
        countryId: countryId,
        isPrimary: isDefault,
        building: building,
        floor: floor,
        apartment: apartment,
        landmark: landmark,
      );
      
      if (response.success && response.data != null) {
        // Update the address in local list
        final index = _addresses.indexWhere((addr) => addr.id == addressId);
        if (index != -1) {
          _addresses[index] = response.data!;
          
          // If this is set as default, update default address
          if (isDefault) {
            _updateDefaultAddress(response.data!);
          }
        }
        
        _setError(null);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to update address');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while updating address: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _addressService.deleteAddress(addressId);
      
      if (response.success) {
        // Remove from local list
        _addresses.removeWhere((address) => address.id == addressId);
        
        // If deleted address was selected or default, update selections
        if (_selectedAddress?.id == addressId) {
          _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
        }
        
        if (_defaultAddress?.id == addressId) {
          _defaultAddress = _addresses.isNotEmpty ? _addresses.first : null;
        }
        
        _setError(null);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete address');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while deleting address: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Set an address as default
  Future<bool> setDefaultAddress(String addressId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _addressService.setDefaultAddress(addressId);
      
      if (response.success) {
        // Update default address locally
        final address = _addresses.firstWhere(
          (addr) => addr.id == addressId,
          orElse: () => throw Exception('Address not found'),
        );
        
        _updateDefaultAddress(address);
        _setError(null);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to set default address');
        return false;
      }
    } catch (e) {
      _setError('An error occurred while setting default address: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Select an address for current use
  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }
  
  /// Clear selected address
  void clearSelectedAddress() {
    _selectedAddress = null;
    notifyListeners();
  }
  
  /// Get address by ID
  AddressModel? getAddressById(String id) {
    try {
      return _addresses.firstWhere((address) => address.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Add current location as an option
  void addCurrentLocationOption() {
    final currentLocation = AddressModel.currentLocation();
    
    // Remove existing current location if any
    _addresses.removeWhere((addr) => addr.id == 'current_location');
    
    // Add current location at the beginning
    _addresses.insert(0, currentLocation);
    notifyListeners();
  }
  
  /// Remove current location option
  void removeCurrentLocationOption() {
    _addresses.removeWhere((addr) => addr.id == 'current_location');
    notifyListeners();
  }
  
  /// Helper method to update default address
  void _updateDefaultAddress(AddressModel newDefault) {
    // Update all addresses to not be default
    for (int i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: false);
    }
    
    // Set the new default
    final index = _addresses.indexWhere((addr) => addr.id == newDefault.id);
    if (index != -1) {
      _addresses[index] = _addresses[index].copyWith(isDefault: true);
      _defaultAddress = _addresses[index];
    }
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String? error) {
    _error = error;
    if (error != null) {
      notifyListeners();
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Refresh addresses
  Future<void> refresh() async {
    await fetchAddresses();
  }
  
  /// Clear all addresses (for logout)
  void clear() {
    _addresses.clear();
    _selectedAddress = null;
    _defaultAddress = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}