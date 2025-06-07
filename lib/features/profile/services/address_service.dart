import '../../../core/api/api_service.dart';
import '../../../core/models/api_response.dart';
import '../models/address_model.dart';

class AddressService {
  final ApiService _apiService = ApiService();
  
  /// Fetch all saved addresses for the current user
  /// GET /api/v1/addressBook
  Future<ApiResponse<List<AddressModel>>> getAddresses() async {
    try {
      final response = await _apiService.get<List<AddressModel>>(
        '/addressBook',
        fromJsonT: (json) {
          print('🏠 Address parsing - json type: ${json.runtimeType}');
          print('🏠 Address parsing - json content: $json');
          
          // Handle case where API returns direct array of addresses
          if (json is List) {
            print('🏠 Address parsing - processing direct List with ${json.length} items');
            final list = json;
            final addresses = <AddressModel>[];
            
            for (int i = 0; i < list.length; i++) {
              final item = list[i];
              print('🏠 Address parsing - item $i type: ${item.runtimeType}');
              
              if (item is Map<String, dynamic>) {
                try {
                  final address = AddressModel.fromJson(item);
                  addresses.add(address);
                  print('🏠 Address parsing - successfully parsed item $i');
                } catch (e) {
                  print('🏠 Address parsing - failed to parse item $i: $e');
                }
              } else {
                print('🏠 Address parsing - item $i is not a Map, skipping');
              }
            }
            
            print('🏠 Address parsing - final result: ${addresses.length} addresses');
            return addresses;
          }
          
          print('🏠 Address parsing - returning empty list, json was: ${json.runtimeType}');
          return <AddressModel>[];
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: 'Failed to fetch addresses: $e');
    }
  }
  
  /// Add a new address
  /// POST /api/v1/user/address
  Future<ApiResponse<AddressModel>> addAddress({
    required String address,
    required String street,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required double latitude,
    required double longitude,
    required int addressType, // 1=home, 2=office, 3=other
    required int countryId,
    bool isPrimary = false,
    String? building,
    String? floor,
    String? apartment,
    String? landmark,
  }) async {
    try {
      final data = {
        'address': address,
        'street': street,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'address_type': addressType.toString(),
        'country_id': countryId.toString(),
        'is_primary': isPrimary ? '1' : '0',
        if (building != null && building.isNotEmpty) 'building': building,
        if (floor != null && floor.isNotEmpty) 'floor': floor,
        if (apartment != null && apartment.isNotEmpty) 'apartment': apartment,
        if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      };
      
      final response = await _apiService.post<AddressModel>(
        '/user/address',
        data: data,
        fromJsonT: (json) {
          if (json['data'] != null) {
            return AddressModel.fromJson(json['data'] as Map<String, dynamic>);
          }
          throw Exception('Invalid response format');
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: 'Failed to add address: $e');
    }
  }
  
  /// Update an existing address
  /// POST /api/v1/user/address/{id}
  Future<ApiResponse<AddressModel>> updateAddress({
    required String addressId,
    required String address,
    required String street,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required double latitude,
    required double longitude,
    required int addressType,
    required int countryId,
    bool isPrimary = false,
    String? building,
    String? floor,
    String? apartment,
    String? landmark,
  }) async {
    try {
      final data = {
        'address': address,
        'street': street,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'address_type': addressType.toString(),
        'country_id': countryId.toString(),
        'is_primary': isPrimary ? '1' : '0',
        if (building != null && building.isNotEmpty) 'building': building,
        if (floor != null && floor.isNotEmpty) 'floor': floor,
        if (apartment != null && apartment.isNotEmpty) 'apartment': apartment,
        if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      };
      
      final response = await _apiService.post<AddressModel>(
        '/user/address/$addressId',
        data: data,
        fromJsonT: (json) {
          if (json['data'] != null) {
            return AddressModel.fromJson(json['data'] as Map<String, dynamic>);
          }
          throw Exception('Invalid response format');
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: 'Failed to update address: $e');
    }
  }
  
  /// Delete an address
  /// DELETE /api/v1/addressBook/{id}
  Future<ApiResponse<bool>> deleteAddress(String addressId) async {
    try {
      final response = await _apiService.delete<bool>(
        '/addressBook/$addressId',
        fromJsonT: (json) {
          return json['success'] == true || json['status'] == 'success';
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: 'Failed to delete address: $e');
    }
  }
  
  /// Set an address as primary/default
  /// GET /api/v1/user/address/{id}/primary
  Future<ApiResponse<bool>> setDefaultAddress(String addressId) async {
    try {
      final response = await _apiService.get<bool>(
        '/user/address/$addressId/primary',
        fromJsonT: (json) {
          return json['success'] == true || json['status'] == 'success';
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: 'Failed to set default address: $e');
    }
  }
  
  /// Get address details by ID
  /// GET /api/v1/addressBook/{id}
  Future<ApiResponse<AddressModel>> getAddressById(String addressId) async {
    try {
      final response = await _apiService.get<AddressModel>(
        '/addressBook/$addressId',
        fromJsonT: (json) {
          if (json['data'] != null) {
            return AddressModel.fromJson(json['data'] as Map<String, dynamic>);
          }
          throw Exception('Invalid response format');
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: 'Failed to fetch address: $e');
    }
  }
  
  /// Convert address type from string to int for API
  static int getAddressTypeId(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return 1;
      case 'work':
      case 'office':
        return 2;
      case 'other':
      case 'hotel':
      default:
        return 3;
    }
  }
  
  /// Convert address type from int to string for UI
  static String getAddressTypeString(int typeId) {
    switch (typeId) {
      case 1:
        return 'home';
      case 2:
        return 'work';
      case 3:
      default:
        return 'other';
    }
  }
}