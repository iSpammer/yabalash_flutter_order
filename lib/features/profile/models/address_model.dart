import 'package:uuid/uuid.dart';

class AddressModel {
  final String id;
  final int? numericId; // Numeric ID from API
  final String label;
  final String fullAddress;
  final String? street;
  final String? building;
  final String? floor;
  final String? apartment;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final String type; // home, work, hotel, other
  final bool isDefault;
  final DateTime createdAt;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final int? countryId;

  AddressModel({
    required this.id,
    this.numericId,
    required this.label,
    required this.fullAddress,
    this.street,
    this.building,
    this.floor,
    this.apartment,
    this.landmark,
    this.latitude,
    this.longitude,
    required this.type,
    this.isDefault = false,
    DateTime? createdAt,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.countryId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructor for current location
  factory AddressModel.currentLocation() {
    return AddressModel(
      id: 'current_location',
      label: 'Current Location',
      fullAddress: 'Using GPS location',
      type: 'current',
      isDefault: true,
    );
  }

  // Factory constructor from JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      numericId: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      label: json['label'] ?? _getLabelFromAddressType(json['type'] ?? json['address_type']) ?? 'Address',
      fullAddress: json['fullAddress'] ?? json['address'] ?? '',
      street: json['street'],
      building: json['building'] ?? json['house_number'],
      floor: json['floor'],
      apartment: json['apartment'],
      landmark: json['landmark'] ?? json['extra_instruction'],
      latitude: json['latitude'] != null
          ? json['latitude'] is String
              ? double.tryParse(json['latitude'])
              : json['latitude']?.toDouble()
          : null,
      longitude: json['longitude'] != null
          ? json['longitude'] is String
              ? double.tryParse(json['longitude'])
              : json['longitude']?.toDouble()
          : null,
      type: _getTypeFromAddressType(json['type'] ?? json['address_type']),
      isDefault: json['isDefault'] ?? json['is_primary'] == 1 || json['is_primary'] == '1',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      countryId: json['country_id'] != null 
          ? (json['country_id'] is int ? json['country_id'] : int.tryParse(json['country_id']?.toString() ?? ''))
          : null,
    );
  }

  // Helper method to convert API address_type to our type string
  static String _getTypeFromAddressType(dynamic addressType) {
    if (addressType == null) return 'other';
    
    final typeInt = addressType is int ? addressType : int.tryParse(addressType.toString());
    switch (typeInt) {
      case 1:
        return 'home';
      case 2:
        return 'work';
      case 3:
      default:
        return 'other';
    }
  }

  // Helper method to convert API address_type to label
  static String _getLabelFromAddressType(dynamic addressType) {
    if (addressType == null) return 'Other';
    
    final typeInt = addressType is int ? addressType : int.tryParse(addressType.toString());
    switch (typeInt) {
      case 1:
        return 'Home';
      case 2:
        return 'Work';
      case 3:
      default:
        return 'Other';
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'fullAddress': fullAddress,
      'address': fullAddress,
      'street': street,
      'building': building,
      'floor': floor,
      'apartment': apartment,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'address_type': _getAddressTypeId(type),
      'isDefault': isDefault,
      'is_primary': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'country_id': countryId,
    };
  }

  // Helper method to convert type string to API address_type
  static int _getAddressTypeId(String type) {
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

  // Copy with method
  AddressModel copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? street,
    String? building,
    String? floor,
    String? apartment,
    String? landmark,
    double? latitude,
    double? longitude,
    String? type,
    bool? isDefault,
    DateTime? createdAt,
    String? city,
    String? state,
    String? country,
    String? pincode,
    int? countryId,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      street: street ?? this.street,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      apartment: apartment ?? this.apartment,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      countryId: countryId ?? this.countryId,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AddressModel &&
        other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}