import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/api_response.dart';
import '../models/category_detail_model.dart';
import '../../restaurants/models/product_model.dart';

class CategoryService {
  final ApiService _apiService = ApiService();

  /// Get category details by ID
  Future<ApiResponse<CategoryDetailModel>> getCategoryDetails({
    required int categoryId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/category/$categoryId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        try {
          final categoryData = response.data!['data'] ?? response.data!;
          final category = CategoryDetailModel.fromJson(categoryData);
          return ApiResponse.success(data: category);
        } catch (e) {
          debugPrint('Error parsing category details: $e');
          return ApiResponse.error(message: 'Failed to parse category details');
        }
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load category details',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading category details: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }

  /// Get products in a category with filtering and sorting
  Future<ApiResponse<CategoryProductsResponse>> getCategoryProducts({
    required int categoryId,
    int page = 1,
    int limit = 20,
    CategoryFilters? filters,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add location parameters
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
      }

      // Add filter parameters
      if (filters != null) {
        queryParams.addAll(filters.toQueryParameters());
      }

      // Get category products - the API returns products in the category endpoint itself
      final response = await _apiService.get<Map<String, dynamic>>(
        '/category/$categoryId',
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        try {
          final productsResponse = CategoryProductsResponse.fromJson(response.data!);
          return ApiResponse.success(data: productsResponse);
        } catch (e) {
          debugPrint('Error parsing category products: $e');
          return ApiResponse.error(message: 'Failed to parse products');
        }
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load category products',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading category products: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }

  /// Get products as ProductModel objects for easy consumption
  Future<ApiResponse<List<ProductModel>>> getCategoryProductsAsModels({
    required int categoryId,
    int page = 1,
    int limit = 20,
    CategoryFilters? filters,
    double? latitude,
    double? longitude,
  }) async {
    final response = await getCategoryProducts(
      categoryId: categoryId,
      page: page,
      limit: limit,
      filters: filters,
      latitude: latitude,
      longitude: longitude,
    );

    if (response.success && response.data != null) {
      try {
        final products = response.data!.products
            .map((productJson) => ProductModel.fromJson(productJson))
            .toList();
        return ApiResponse.success(data: products);
      } catch (e) {
        debugPrint('Error converting products to models: $e');
        return ApiResponse.error(message: 'Failed to process products');
      }
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load products',
      errors: response.errors,
    );
  }

  /// Search products within a category
  Future<ApiResponse<List<ProductModel>>> searchCategoryProducts({
    required int categoryId,
    required String query,
    int page = 1,
    int limit = 20,
    CategoryFilters? filters,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'q': query,
        'search': query,
      };

      // Add location parameters
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
      }

      // Add filter parameters
      if (filters != null) {
        queryParams.addAll(filters.toQueryParameters());
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/category/$categoryId/products/search',
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        try {
          final data = response.data!['data'] ?? response.data!;
          final productsData = data['products'] ?? data['data'] ?? [];
          
          final products = (productsData as List)
              .map((productJson) => ProductModel.fromJson(productJson))
              .toList();
          
          return ApiResponse.success(data: products);
        } catch (e) {
          debugPrint('Error parsing search results: $e');
          return ApiResponse.error(message: 'Failed to parse search results');
        }
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to search products',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error searching category products: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }

  /// Get category statistics (for analytics)
  Future<ApiResponse<Map<String, dynamic>>> getCategoryStats({
    required int categoryId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/category/$categoryId/stats',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(data: response.data!);
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load category statistics',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading category stats: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }

  /// Get available filter options for a category
  Future<ApiResponse<Map<String, dynamic>>> getCategoryFilterOptions({
    required int categoryId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/category/$categoryId/filters',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(data: response.data!);
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load filter options',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading filter options: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }
}