import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/api_response.dart';
import '../models/restaurant_model.dart';
import '../models/menu_category_model.dart';
import '../models/product_model.dart';

class RestaurantService {
  final ApiService _apiService = ApiService();
  
  // Get restaurant details (uses vendor/category/list endpoint like React Native)
  Future<ApiResponse<RestaurantModel>> getRestaurantDetails({
    required int restaurantId,
    double? latitude,
    double? longitude,
  }) async {
    Map<String, dynamic> requestData = {
      'vendor_id': restaurantId,
    };
    
    if (latitude != null && longitude != null) {
      requestData['latitude'] = latitude.toString();
      requestData['longitude'] = longitude.toString();
    }
    
    // Use the same endpoint as React Native: POST /vendor/category/list
    try {
      debugPrint('Getting vendor details for vendor $restaurantId');
      
      final response = await _apiService.post(
        '/vendor/category/list',
        data: requestData,
      );
      
      if (response.success && response.data != null) {
        // The vendor/category/list endpoint returns categories directly as a list
        dynamic responseData;
        if (response.data is List) {
          // If response is a list (categories), we need to fetch vendor details separately
          debugPrint('Response is a list of categories (${(response.data as List).length} categories)');
          
          // Fetch vendor details from the /vendor endpoint
          try {
            final vendorResponse = await _apiService.get(
              '/vendor/$restaurantId',
              queryParameters: latitude != null && longitude != null ? {
                'latitude': latitude.toString(),
                'longitude': longitude.toString(),
              } : null,
            );
            
            if (vendorResponse.success && vendorResponse.data != null) {
              final vendorData = vendorResponse.data!['data'] ?? vendorResponse.data!;
              responseData = {
                'vendor': vendorData,
                'categories': response.data,
              };
            } else {
              // Create minimal vendor data if vendor endpoint fails
              responseData = {
                'vendor': {'id': restaurantId},
                'categories': response.data,
              };
            }
          } catch (e) {
            debugPrint('Failed to fetch vendor data: $e');
            responseData = {
              'vendor': {'id': restaurantId},
              'categories': response.data,
            };
          }
        } else if (response.data is Map) {
          responseData = response.data!['data'] ?? response.data!;
        } else {
          throw Exception('Unexpected response format');
        }
        
        // Debug log to understand the response structure
        debugPrint('Vendor response keys: ${responseData.keys.toList()}');
        
        // Extract vendor data - handle case where vendor might be missing
        Map<String, dynamic> vendorData;
        if (responseData.containsKey('vendor') && responseData['vendor'] != null) {
          vendorData = responseData['vendor'];
        } else {
          // If no vendor data, check if we have vendor info from another endpoint
          debugPrint('No vendor data in response, fetching from vendor endpoint');
          try {
            final vendorResponse = await _apiService.get(
              '/vendor/$restaurantId',
              queryParameters: latitude != null && longitude != null ? {
                'latitude': latitude.toString(),
                'longitude': longitude.toString(),
              } : null,
            );
            if (vendorResponse.success && vendorResponse.data != null) {
              vendorData = vendorResponse.data!['data'] ?? vendorResponse.data!;
            } else {
              // Create minimal vendor data
              vendorData = {'id': restaurantId};
            }
          } catch (e) {
            debugPrint('Failed to fetch vendor data: $e');
            vendorData = {'id': restaurantId};
          }
        }
        
        // Extract products and categories from the response
        final productsData = responseData['products'];
        final categoriesData = responseData['categories'];
        
        if (vendorData.containsKey('show_slot')) {
          debugPrint('show_slot value: ${vendorData['show_slot']}');
        }
        if (vendorData.containsKey('is_open')) {
          debugPrint('is_open value: ${vendorData['is_open']}');
        }
        if (productsData != null) {
          if (productsData is Map && productsData.containsKey('data')) {
            debugPrint('Products count in response: ${(productsData['data'] as List?)?.length ?? 0}');
          } else if (productsData is List) {
            debugPrint('Products count in response: ${productsData.length}');
          }
        }
        if (categoriesData != null) {
          debugPrint('Categories count in response: ${(categoriesData as List?)?.length ?? 0}');
        }
        
        // Add products and categories to vendor data for model parsing
        final enrichedVendorData = Map<String, dynamic>.from(vendorData);
        if (productsData != null) {
          enrichedVendorData['products'] = productsData;
        }
        if (categoriesData != null) {
          enrichedVendorData['categories'] = categoriesData;
        }
        
        debugPrint('About to parse restaurant model with enriched data');
        debugPrint('Enriched vendor data keys: ${enrichedVendorData.keys.toList()}');
        
        try {
          final restaurant = RestaurantModel.fromJson(enrichedVendorData);
          debugPrint('Successfully parsed restaurant: ${restaurant.name}');
          return ApiResponse.success(data: restaurant);
        } catch (modelError) {
          debugPrint('Error parsing RestaurantModel: $modelError');
          debugPrint('Model error stackTrace: ${StackTrace.current}');
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error loading vendor details: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is DioException) {
        debugPrint('DioException response: ${e.response?.data}');
        debugPrint('DioException status: ${e.response?.statusCode}');
      }
      
      // If vendor/category/list fails, try the direct vendor endpoint
      try {
        debugPrint('Trying fallback endpoint /vendor/$restaurantId');
        final fallbackResponse = await _apiService.get(
          '/vendor/$restaurantId',
          queryParameters: latitude != null && longitude != null ? {
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
          } : null,
        );
        
        if (fallbackResponse.success && fallbackResponse.data != null) {
          // Handle the response data
          dynamic responseData;
          if (fallbackResponse.data is List) {
            // If it's a list of categories, wrap it
            responseData = {
              'vendor': {'id': restaurantId},
              'categories': fallbackResponse.data,
            };
          } else if (fallbackResponse.data is Map) {
            responseData = fallbackResponse.data!['data'] ?? fallbackResponse.data!;
          }
          
          final vendorData = responseData['vendor'] ?? responseData;
          
          // Add categories if available
          if (responseData.containsKey('categories')) {
            vendorData['categories'] = responseData['categories'];
          }
          
          try {
            final restaurant = RestaurantModel.fromJson(vendorData);
            debugPrint('Successfully parsed restaurant from fallback: ${restaurant.name}');
            return ApiResponse.success(data: restaurant);
          } catch (modelError) {
            debugPrint('Error parsing RestaurantModel from fallback: $modelError');
          }
        }
      } catch (fallbackError) {
        debugPrint('Fallback endpoint also failed: $fallbackError');
      }
    }
    
    return ApiResponse.error(
      message: 'Failed to load restaurant details',
    );
  }
  
  // Get vendor categories with fallback
  Future<ApiResponse<List<MenuCategoryModel>>> getVendorCategories({
    required int vendorId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/vendorCategory',
      data: {
        'vendor_id': vendorId,
      },
    );
    
    if (response.success && response.data != null) {
      final categoriesData = response.data!['data'] ?? response.data!;
      final categories = (categoriesData as List?)
          ?.map((e) => MenuCategoryModel.fromJson(e))
          .toList() ?? [];
      return ApiResponse.success(data: categories);
    }
    
    // If vendorCategory endpoint fails (404), try getting all vendor products
    // and create categories from them
    if (response.statusCode == 404) {
      final productsResponse = await getVendorProducts(vendorId: vendorId);
      if (productsResponse.success && productsResponse.data != null) {
        // Group products by category to create categories
        final Map<int, List<ProductModel>> groupedProducts = {};
        for (final product in productsResponse.data!) {
          if (!groupedProducts.containsKey(product.categoryId)) {
            groupedProducts[product.categoryId] = [];
          }
          groupedProducts[product.categoryId]!.add(product);
        }
        
        final categories = groupedProducts.entries.map((entry) {
          final categoryId = entry.key;
          final products = entry.value;
          final categoryName = products.first.categoryName ?? 'Category $categoryId';
          
          return MenuCategoryModel(
            id: categoryId,
            name: categoryName,
            description: null,
            image: null,
            position: categoryId,
            isActive: true,
            productCount: products.length,
          );
        }).toList();
        
        return ApiResponse.success(data: categories);
      }
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Failed to load categories',
      errors: response.errors,
    );
  }
  
  // Get products by category
  Future<ApiResponse<List<ProductModel>>> getProductsByCategory({
    required int vendorId,
    required int categoryId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/productList',
      data: {
        'vendor_id': vendorId,
        'category_id': categoryId,
        'page': page,
        'limit': limit,
      },
    );
    
    if (response.success && response.data != null) {
      final productsData = response.data!['data']?['products'] ?? 
                          response.data!['products'] ?? 
                          response.data!['data'] ?? 
                          response.data!;
      final products = (productsData as List?)
          ?.map((e) => ProductModel.fromJson(e))
          .toList() ?? [];
      return ApiResponse.success(data: products);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Failed to load products',
      errors: response.errors,
    );
  }
  
  // Get all vendor products
  Future<ApiResponse<List<ProductModel>>> getVendorProducts({
    required int vendorId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/vendorProducts',
      data: {
        'vendor_id': vendorId,
        'page': page,
        'limit': limit,
      },
    );
    
    if (response.success && response.data != null) {
      final productsData = response.data!['data']?['products'] ?? 
                          response.data!['products'] ?? 
                          response.data!['data'] ?? 
                          response.data!;
      final products = (productsData as List?)
          ?.map((e) => ProductModel.fromJson(e))
          .toList() ?? [];
      return ApiResponse.success(data: products);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Failed to load products',
      errors: response.errors,
    );
  }
  
  // Get product details
  Future<ApiResponse<ProductModel>> getProductDetails({
    required int productId,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/product/$productId',
    );
    
    if (response.success && response.data != null) {
      final productData = response.data!['data'] ?? response.data!;
      final product = ProductModel.fromJson(productData);
      return ApiResponse.success(data: product);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Failed to load product details',
      errors: response.errors,
    );
  }
}