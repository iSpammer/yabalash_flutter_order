import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/api_response.dart';
import '../models/dashboard_model.dart';
import '../models/dashboard_section.dart';
import '../models/category_model.dart';
import '../../restaurants/models/restaurant_model.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<DashboardModel>> getHomepageData({
    double? latitude,
    double? longitude,
    String type = 'delivery',
  }) async {
    // Convert pickup to takeaway as per React Native implementation
    String apiType = type == 'pickup' ? 'takeaway' : type;

    Map<String, dynamic> requestBody = {
      'type': apiType, // 'delivery', 'takeaway', 'dine_in'
      'action': '2', // Required for V2 API
      'open_close_vendor': 0,
    };

    if (latitude != null && longitude != null) {
      requestBody['latitude'] = latitude.toString();
      requestBody['longitude'] = longitude.toString();
      requestBody['address'] = ''; // Address field for location
    }

    final response = await _apiService.post<Map<String, dynamic>>(
      '/v2/homepage', // Use V2 endpoint
      data: requestBody,
    );

    if (response.success && response.data != null) {
      final responseData = response.data!['data'] ?? response.data!;

      // V2 API returns homePageLabels array with different sections
      final homePageLabels = responseData['homePageLabels'] as List? ?? [];

      List<dynamic> banners = [];
      List<dynamic> categories = [];
      List<dynamic> vendors = [];
      List<dynamic> featuredProducts = [];

      // Parse homePageLabels array to extract different sections
      for (var section in homePageLabels) {
        final sectionSlug = section['slug'] as String?;
        final sectionData = section['data'] as List? ?? [];

        switch (sectionSlug) {
          case 'banner':
            banners = sectionData;
            break;
          case 'nav_categories':
          case 'categories':
            categories = sectionData;
            break;
          case 'vendors':
            vendors = sectionData;
            break;
          case 'featured_products':
          case 'new_products':
          case 'on_sale':
            featuredProducts.addAll(sectionData);
            break;
        }
      }

      // Handle the V2 API response structure
      final dashboardData = {
        'banners': banners,
        'categories': categories,
        'featured_restaurants':
            vendors.where((v) => v['is_featured'] == 1).toList(),
        'nearby_restaurants': vendors,
        'popular_restaurants':
            vendors.where((v) => v['is_popular'] == 1).toList(),
      };

      final dashboard = DashboardModel.fromJson(dashboardData);
      return ApiResponse.success(data: dashboard);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load dashboard data',
      errors: response.errors,
    );
  }

  Future<ApiResponse<List<DashboardSection>>> getHomepageSections({
    double? latitude,
    double? longitude,
    String type = 'delivery',
  }) async {
    // Convert pickup to takeaway as per React Native implementation
    String apiType = type == 'pickup' ? 'takeaway' : type;

    Map<String, dynamic> requestBody = {
      'type': apiType, // 'delivery', 'takeaway', 'dine_in'
      'action': '2', // Required for V2 API
      'open_close_vendor': 0,
    };

    if (latitude != null && longitude != null) {
      requestBody['latitude'] = latitude.toString();
      requestBody['longitude'] = longitude.toString();
      requestBody['address'] = ''; // Address field for location
    }

    final response = await _apiService.post<Map<String, dynamic>>(
      '/v2/homepage', // Use V2 endpoint
      data: requestBody,
    );

    // Debug logging for pickup mode investigation
    // debugPrint('[Dashboard Service] API request type: $apiType (original: $type)');
    // debugPrint('[Dashboard Service] API response success: ${response.success}');
    if (response.data != null) {
      final debugLabels =
          response.data!['data']?['homePageLabels'] as List? ?? [];
      // debugPrint('[Dashboard Service] Number of sections returned: ${debugLabels.length}');
      for (var section in debugLabels) {
        final dataLength = (section['data'] as List?)?.length ?? 0;
        // debugPrint('[Dashboard Service] Section ${section['slug']}: $dataLength items');
      }
    }

    if (response.success && response.data != null) {
      final responseData = response.data!['data'] ?? response.data!;

      // V2 API returns homePageLabels array with different sections
      final homePageLabels = responseData['homePageLabels'] as List? ?? [];

      final sections = homePageLabels
          .map((sectionJson) => DashboardSection.fromJson(sectionJson))
          .where((section) {
        // Debug each section
        // debugPrint('[Dashboard Service] Section ${section.slug} (${section.title}): shouldDisplay=${section.shouldDisplay}, dataLength=${section.data.length}');
        return section.shouldDisplay;
      }).toList();

      // debugPrint('[Dashboard Service] Total sections after filtering: ${sections.length}');

      return ApiResponse.success(data: sections);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load dashboard sections',
      errors: response.errors,
    );
  }

  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    final response = await _apiService.get<Map<String, dynamic>>('/category');

    if (response.success && response.data != null) {
      final categoriesData = response.data!['data'] ?? response.data!;
      final categories = (categoriesData['categories'] as List?)
              ?.map((e) => CategoryModel.fromJson(e))
              .toList() ??
          [];
      return ApiResponse.success(data: categories);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load categories',
      errors: response.errors,
    );
  }

  Future<ApiResponse<List<RestaurantModel>>> getRestaurantsByCategory({
    required int categoryId,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 20,
  }) async {
    Map<String, dynamic> queryParams = {
      'category_id': categoryId.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/vendors/category',
      queryParameters: queryParams,
    );

    if (response.success && response.data != null) {
      final restaurantsData = response.data!['data'] ?? response.data!;
      final restaurants = (restaurantsData['vendors'] as List?)
              ?.map((e) => RestaurantModel.fromJson(e))
              .toList() ??
          [];
      return ApiResponse.success(data: restaurants);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load restaurants',
      errors: response.errors,
    );
  }

  Future<ApiResponse<List<RestaurantModel>>> searchRestaurants({
    required String query,
    double? latitude,
    double? longitude,
    int? categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    Map<String, dynamic> queryParams = {
      'search': query,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }

    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/search/all',
      queryParameters: queryParams,
    );

    if (response.success && response.data != null) {
      final searchData = response.data!['data'] ?? response.data!;
      final restaurants = (searchData['vendors'] as List?)
              ?.map((e) => RestaurantModel.fromJson(e))
              .toList() ??
          [];
      return ApiResponse.success(data: restaurants);
    }

    return ApiResponse.error(
      message: response.message ?? 'Search failed',
      errors: response.errors,
    );
  }

  Future<ApiResponse<RestaurantModel>> getRestaurantDetails({
    required int restaurantId,
    double? latitude,
    double? longitude,
  }) async {
    Map<String, dynamic> queryParams = {};

    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/vendor/$restaurantId',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.success && response.data != null) {
      final restaurant =
          RestaurantModel.fromJson(response.data!['data'] ?? response.data!);
      return ApiResponse.success(data: restaurant);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load restaurant details',
      errors: response.errors,
    );
  }
}
