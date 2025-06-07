import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Google Maps service that replicates React Native app functionality
/// Based on investigation of googlePlaceApi.js and PinAddressOnMap.js
class GoogleMapsService {
  static final _dio = Dio();

  /// Get place autocomplete suggestions
  /// Replicates googlePlacesApi function from React Native app
  static Future<GooglePlacesResponse?> getPlaceAutocomplete({
    required String input,
    String? latLng,
    String? region,
  }) async {
    try {
      debugPrint('=== Google Places Autocomplete Request ===');
      debugPrint('Input: $input');
      debugPrint('LatLng: $latLng');

      // Build query string with country components (based on app bundle)
      String query = _getAppRelatedPlaces();
      
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$input'
          '&key=${ApiConstants.googleMapsApiKey}$query';
      
      if (latLng != null) {
        url += '&location=$latLng';
      }

      debugPrint('Request URL: $url');

      final response = await _dio.get(url);
      
      debugPrint('=== Google Places Autocomplete Response ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      if (response.statusCode == 200) {
        return GooglePlacesResponse.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error in Google Places autocomplete: $e');
      return null;
    }
  }

  /// Get place details by place ID
  /// Replicates getPlaceDetails function from React Native app
  static Future<GooglePlaceDetailsResponse?> getPlaceDetails({
    required String placeId,
  }) async {
    try {
      debugPrint('=== Google Place Details Request ===');
      debugPrint('Place ID: $placeId');

      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&key=${ApiConstants.googleMapsApiKey}';

      debugPrint('Request URL: $url');

      final response = await _dio.get(url);
      
      debugPrint('=== Google Place Details Response ===');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return GooglePlaceDetailsResponse.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error in Google Place details: $e');
      return null;
    }
  }

  /// Reverse geocoding to get address from coordinates
  /// Replicates placesGeoCoding and getAddressFromLatLong functions
  static Future<GoogleGeocodingResponse?> reverseGeocode({
    required double latitude,
    required double longitude,
    String language = 'en',
  }) async {
    try {
      debugPrint('=== Google Reverse Geocoding Request ===');
      debugPrint('Lat: $latitude, Lng: $longitude');

      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$latitude,$longitude'
          '&key=${ApiConstants.googleMapsApiKey}'
          '&language=$language';

      debugPrint('Request URL: $url');

      final response = await _dio.get(url);
      
      debugPrint('=== Google Reverse Geocoding Response ===');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return GoogleGeocodingResponse.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error in Google reverse geocoding: $e');
      return null;
    }
  }

  /// Search for nearby places
  /// Replicates nearbySearch function from React Native app
  static Future<GoogleNearbySearchResponse?> nearbySearch({
    required double latitude,
    required double longitude,
    String type = 'restaurant',
    int radius = 5000,
  }) async {
    try {
      debugPrint('=== Google Nearby Search Request ===');
      debugPrint('Lat: $latitude, Lng: $longitude');
      debugPrint('Type: $type, Radius: $radius');

      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$latitude,$longitude'
          '&type=$type'
          '&radius=$radius'
          '&key=${ApiConstants.googleMapsApiKey}';

      debugPrint('Request URL: $url');

      final response = await _dio.get(url);
      
      debugPrint('=== Google Nearby Search Response ===');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return GoogleNearbySearchResponse.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error in Google nearby search: $e');
      return null;
    }
  }

  /// Get country-specific place components based on app bundle
  /// Replicates getAppRelatedPlaces function from React Native app
  static String _getAppRelatedPlaces() {
    // This would normally check the app bundle ID
    // For now, return empty string (no country restriction)
    // In React Native app, this returned:
    // - '&components=country:ARG' for appi bundle
    // - '&components=country:BS' for ahoy bundle
    // - '' for default (yabalash)
    return '';
  }

  /// Get formatted address from geocoding result
  /// Helper function to extract main address from geocoding response
  static String? getFormattedAddress(GoogleGeocodingResponse? response) {
    if (response?.results.isNotEmpty == true) {
      return response!.results.first.formattedAddress;
    }
    return null;
  }

  /// Extract coordinates from place details
  /// Helper function to get lat/lng from place details response
  static Map<String, double>? getCoordinatesFromPlaceDetails(GooglePlaceDetailsResponse? response) {
    if (response?.result?.geometry?.location != null) {
      final location = response!.result!.geometry!.location!;
      return {
        'latitude': location.lat,
        'longitude': location.lng,
      };
    }
    return null;
  }
}

// Response models based on Google Maps API structure

class GooglePlacesResponse {
  final List<GooglePlacePrediction> predictions;
  final String status;

  GooglePlacesResponse({
    required this.predictions,
    required this.status,
  });

  factory GooglePlacesResponse.fromJson(Map<String, dynamic> json) {
    return GooglePlacesResponse(
      predictions: json['predictions'] != null
          ? (json['predictions'] as List)
              .map((p) => GooglePlacePrediction.fromJson(p))
              .toList()
          : [],
      status: json['status'] ?? '',
    );
  }
}

class GooglePlacePrediction {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  GooglePlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  factory GooglePlacePrediction.fromJson(Map<String, dynamic> json) {
    return GooglePlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'],
      secondaryText: json['structured_formatting']?['secondary_text'],
    );
  }
}

class GooglePlaceDetailsResponse {
  final GooglePlaceResult? result;
  final String status;

  GooglePlaceDetailsResponse({
    this.result,
    required this.status,
  });

  factory GooglePlaceDetailsResponse.fromJson(Map<String, dynamic> json) {
    return GooglePlaceDetailsResponse(
      result: json['result'] != null 
          ? GooglePlaceResult.fromJson(json['result'])
          : null,
      status: json['status'] ?? '',
    );
  }
}

class GooglePlaceResult {
  final String placeId;
  final String name;
  final String formattedAddress;
  final GoogleGeometry? geometry;
  final List<GoogleAddressComponent> addressComponents;

  GooglePlaceResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    this.geometry,
    this.addressComponents = const [],
  });

  factory GooglePlaceResult.fromJson(Map<String, dynamic> json) {
    return GooglePlaceResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      geometry: json['geometry'] != null 
          ? GoogleGeometry.fromJson(json['geometry'])
          : null,
      addressComponents: json['address_components'] != null
          ? (json['address_components'] as List)
              .map((c) => GoogleAddressComponent.fromJson(c))
              .toList()
          : [],
    );
  }
}

class GoogleGeocodingResponse {
  final List<GoogleGeocodingResult> results;
  final String status;

  GoogleGeocodingResponse({
    required this.results,
    required this.status,
  });

  factory GoogleGeocodingResponse.fromJson(Map<String, dynamic> json) {
    return GoogleGeocodingResponse(
      results: json['results'] != null
          ? (json['results'] as List)
              .map((r) => GoogleGeocodingResult.fromJson(r))
              .toList()
          : [],
      status: json['status'] ?? '',
    );
  }
}

class GoogleGeocodingResult {
  final String formattedAddress;
  final GoogleGeometry? geometry;
  final List<GoogleAddressComponent> addressComponents;

  GoogleGeocodingResult({
    required this.formattedAddress,
    this.geometry,
    this.addressComponents = const [],
  });

  factory GoogleGeocodingResult.fromJson(Map<String, dynamic> json) {
    return GoogleGeocodingResult(
      formattedAddress: json['formatted_address'] ?? '',
      geometry: json['geometry'] != null 
          ? GoogleGeometry.fromJson(json['geometry'])
          : null,
      addressComponents: json['address_components'] != null
          ? (json['address_components'] as List)
              .map((c) => GoogleAddressComponent.fromJson(c))
              .toList()
          : [],
    );
  }
}

class GoogleNearbySearchResponse {
  final List<GoogleNearbyPlace> results;
  final String status;

  GoogleNearbySearchResponse({
    required this.results,
    required this.status,
  });

  factory GoogleNearbySearchResponse.fromJson(Map<String, dynamic> json) {
    return GoogleNearbySearchResponse(
      results: json['results'] != null
          ? (json['results'] as List)
              .map((r) => GoogleNearbyPlace.fromJson(r))
              .toList()
          : [],
      status: json['status'] ?? '',
    );
  }
}

class GoogleNearbyPlace {
  final String placeId;
  final String name;
  final GoogleGeometry? geometry;
  final double? rating;

  GoogleNearbyPlace({
    required this.placeId,
    required this.name,
    this.geometry,
    this.rating,
  });

  factory GoogleNearbyPlace.fromJson(Map<String, dynamic> json) {
    return GoogleNearbyPlace(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      geometry: json['geometry'] != null 
          ? GoogleGeometry.fromJson(json['geometry'])
          : null,
      rating: json['rating']?.toDouble(),
    );
  }
}

class GoogleGeometry {
  final GoogleLocation? location;

  GoogleGeometry({this.location});

  factory GoogleGeometry.fromJson(Map<String, dynamic> json) {
    return GoogleGeometry(
      location: json['location'] != null 
          ? GoogleLocation.fromJson(json['location'])
          : null,
    );
  }
}

class GoogleLocation {
  final double lat;
  final double lng;

  GoogleLocation({
    required this.lat,
    required this.lng,
  });

  factory GoogleLocation.fromJson(Map<String, dynamic> json) {
    return GoogleLocation(
      lat: json['lat']?.toDouble() ?? 0.0,
      lng: json['lng']?.toDouble() ?? 0.0,
    );
  }
}

class GoogleAddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  GoogleAddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory GoogleAddressComponent.fromJson(Map<String, dynamic> json) {
    return GoogleAddressComponent(
      longName: json['long_name'] ?? '',
      shortName: json['short_name'] ?? '',
      types: json['types'] != null 
          ? List<String>.from(json['types'])
          : [],
    );
  }
}