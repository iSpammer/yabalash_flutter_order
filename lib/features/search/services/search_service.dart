import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../../restaurants/models/product_model.dart';

class SearchService {
  final ApiService _apiService = ApiService();

  Future<List<RestaurantModel>> searchRestaurants(String query, {double? latitude, double? longitude}) async {
    try {
      final response = await _apiService.post(
        '/search/vendors',
        data: {
          'search': query,
          'latitude': latitude ?? 0.0,
          'longitude': longitude ?? 0.0,
          'limit': 20,
        },
      );

      if (response.success && response.data != null) {
        final List<dynamic> vendorsData = response.data['vendors'] ?? [];
        return vendorsData
            .map((json) => RestaurantModel.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to search restaurants: $e');
    }
  }

  Future<List<ProductModel>> searchProducts(String query, {double? latitude, double? longitude}) async {
    try {
      final response = await _apiService.post(
        '/search/products',
        data: {
          'search': query,
          'latitude': latitude ?? 0.0,
          'longitude': longitude ?? 0.0,
          'limit': 20,
        },
      );

      if (response.success && response.data != null) {
        final List<dynamic> productsData = response.data['products'] ?? [];
        return productsData
            .map((json) => ProductModel.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<Map<String, dynamic>> searchAll(String query, {String type = 'delivery', double? latitude, double? longitude}) async {
    try {
      // Convert pickup to takeaway as per React Native implementation
      String apiType = type == 'pickup' ? 'takeaway' : type;
      
      final Map<String, dynamic> requestData = {
        'keyword': query,  // Changed from 'search' to 'keyword' as per RN implementation
        'type': apiType,  // delivery/takeaway type
        'limit': 20,
        'page': 1,
      };
      
      // Add location if provided
      if (latitude != null && longitude != null) {
        requestData['latitude'] = latitude;
        requestData['longitude'] = longitude;
      }
      
      final response = await _apiService.post(
        '/v2/search/all',
        data: requestData,
      );

      if (response.success && response.data != null) {
        // Parse the v2 search response format
        final responseData = response.data;
        List<RestaurantModel> restaurants = [];
        List<ProductModel> products = [];
        
        // The v2 API returns an array of sections with results
        if (responseData is List) {
          for (var section in responseData) {
            final results = section['result'] as List? ?? [];
            
            for (var item in results) {
              final responseType = item['response_type'] as String?;
              
              if (responseType == 'vendor') {
                try {
                  restaurants.add(RestaurantModel.fromJson(item));
                } catch (e) {
                  debugPrint('Error parsing restaurant: $e');
                }
              } else if (responseType == 'product') {
                try {
                  products.add(ProductModel.fromJson(item));
                } catch (e) {
                  debugPrint('Error parsing product: $e');
                }
              }
            }
          }
        }
        
        return {
          'restaurants': restaurants,
          'products': products,
        };
      }
      
      return {'restaurants': <RestaurantModel>[], 'products': <ProductModel>[]};
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }
}