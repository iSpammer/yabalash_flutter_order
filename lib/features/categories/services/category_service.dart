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
          final responseData = response.data!['data'] ?? response.data!;

          // Extract category from the response structure
          final categoryData = responseData['category'] ?? responseData;

          debugPrint('Category data for parsing: $categoryData');
          debugPrint('Category image data: ${categoryData['image']}');
          debugPrint('Category icon data: ${categoryData['icon']}');

          final category = CategoryDetailModel.fromJson(categoryData);
          return ApiResponse.success(data: category);
        } catch (e) {
          debugPrint('Error parsing category details: $e');
          debugPrint('Response data: ${response.data}');
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
    int limit = 5, // Match React Native default
    CategoryFilters? filters,
    double? latitude,
    double? longitude,
    String deliveryType = 'delivery',
  }) async {
    try {
      // Build query params exactly like React Native
      Map<String, String> queryParams = {
        'limit': limit.toString(),
        'page': page.toString(),
        'type': deliveryType,
      };

      // Add filter parameters
      if (filters != null) {
        queryParams.addAll(filters.toQueryParameters());
      }
      
      // Add location parameters
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude.toString();
        queryParams['longitude'] = longitude.toString();
      }

      debugPrint('Calling category API with params: $queryParams');

      // Use v2 endpoint like React Native
      final response = await _apiService.get<Map<String, dynamic>>(
        '/v2/category/$categoryId',
        queryParameters: queryParams,
      );

      debugPrint('Category $categoryId API response: ${response.data}');

      if (response.success && response.data != null) {
        try {
          final productsResponse =
              CategoryProductsResponse.fromJson(response.data!);
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
  
  /// Get category products with filters (React Native style)
  Future<ApiResponse<Map<String, dynamic>>> getCategoryWithFilters({
    required int categoryId,
    Map<String, dynamic>? filters,
    int limit = 3,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Map<String, dynamic> requestData = {};
      
      // Add filters if provided
      if (filters != null) {
        requestData.addAll(filters);
      }
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/category/filters/$categoryId?limit=$limit',
        data: requestData,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(data: response.data!);
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load category with filters',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading category with filters: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }
  
  /// Get optimized vendor category (v2 endpoint)
  Future<ApiResponse<Map<String, dynamic>>> getOptimizedVendorCategory({
    required int categoryId,
    Map<String, dynamic>? filters,
    int limit = 12,
    int page = 1,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Map<String, dynamic> requestData = {};
      
      // Add filters if provided (brands, variants, options, range, order_type)
      if (filters != null) {
        requestData.addAll(filters);
      }
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/v2/vendor-optimize-category/$categoryId?limit=$limit&page=$page',
        data: requestData,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(data: response.data!);
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load optimized category',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading optimized category: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }
  
  /// Get vendor category list
  Future<ApiResponse<Map<String, dynamic>>> getVendorCategoryList({
    required int vendorId,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/vendor/category/list',
        data: {
          'vendor_id': vendorId,
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(data: response.data!);
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load vendor categories',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading vendor categories: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }
  
  /// Get subcategory vendors
  Future<ApiResponse<Map<String, dynamic>>> getSubcategoryVendors({
    required int categoryId,
    String type = 'delivery',
    double? latitude,
    double? longitude,
    bool openVendor = true,
    bool closeVendor = false,
    bool bestVendor = false,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'type': type,
        'category_id': categoryId,
        'open_vendor': openVendor ? 1 : 0,
        'close_vendor': closeVendor ? 1 : 0,
        'best_vendor': bestVendor ? 1 : 0,
      };
      
      if (latitude != null && longitude != null) {
        requestData['latitude'] = latitude.toString();
        requestData['longitude'] = longitude.toString();
      }
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/get/subcategory/vendor',
        data: requestData,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(data: response.data!);
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load subcategory vendors',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading subcategory vendors: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }
  
  /// Get product estimation with addons
  Future<ApiResponse<Map<String, dynamic>>> getProductEstimationWithAddons({
    required int categoryId,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/estimation/get-product-estimation-with-addons?category_id=$categoryId',
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(data: response.data!);
      }

      return ApiResponse.error(
        message: response.message ?? 'Failed to load product estimation',
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Error loading product estimation: $e');
      return ApiResponse.error(message: 'Network error occurred');
    }
  }
}
