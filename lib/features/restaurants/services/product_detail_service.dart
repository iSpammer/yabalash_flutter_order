import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/api_response.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/offer_model.dart';

class ProductDetailService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<ProductModel>> getProductDetails({
    required int productId,
    double? latitude,
    double? longitude,
  }) async {
    Map<String, dynamic> queryParams = {};
    
    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/product/$productId',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.success && response.data != null) {
      try {
        final responseData = response.data!['data'] ?? response.data!;
        
        // Get the product object from the response
        final productJson = responseData['product'] ?? responseData;
        
        // Create the product model
        final product = ProductModel.fromJson(productJson);
        
        return ApiResponse.success(data: product);
      } catch (e) {
        debugPrint('Error parsing product details: $e');
        debugPrint('Response data: ${response.data}');
        return ApiResponse.error(message: 'Failed to parse product details: $e');
      }
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load product details',
      errors: response.errors,
    );
  }

  Future<ApiResponse<List<ReviewModel>>> getProductReviews({
    required int productId,
    int page = 1,
    int limit = 10,
  }) async {
    // Use the new getProductRatings method which is the correct API endpoint
    return getProductRatings(productId: productId);
  }

  Future<ApiResponse<List<ReviewModel>>> getProductRatings({
    required int productId,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/rating/get-product-rating',
      queryParameters: {
        'id': productId.toString(),
      },
    );

    if (response.success && response.data != null) {
      try {
        final ratingsData = response.data!['data'] ?? response.data!;
        
        debugPrint('=== Product Ratings Debug ===');
        debugPrint('Ratings data keys: ${ratingsData.keys.toList()}');
        debugPrint('=====================================');
        
        // Parse ratings/reviews from response
        final reviews = <ReviewModel>[];
        
        // Check different possible response structures
        if (ratingsData['ratings'] != null) {
          final ratingsArray = ratingsData['ratings'] as List;
          for (var ratingJson in ratingsArray) {
            reviews.add(ReviewModel.fromJson(ratingJson));
          }
        } else if (ratingsData['reviews'] != null) {
          final reviewsArray = ratingsData['reviews'] as List;
          for (var reviewJson in reviewsArray) {
            reviews.add(ReviewModel.fromJson(reviewJson));
          }
        } else if (ratingsData is List) {
          // Direct array of ratings
          for (var ratingJson in ratingsData) {
            reviews.add(ReviewModel.fromJson(ratingJson));
          }
        }
        
        return ApiResponse.success(data: reviews);
      } catch (e) {
        debugPrint('Error parsing product ratings: $e');
        debugPrint('Response data: ${response.data}');
        return ApiResponse.error(message: 'Failed to parse product ratings: $e');
      }
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load product ratings',
      errors: response.errors,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getProductDetailsWithExtras({
    required int productId,
    double? latitude,
    double? longitude,
  }) async {
    Map<String, dynamic> queryParams = {};
    
    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/product/$productId',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.success && response.data != null) {
      try {
        final responseData = response.data!['data'] ?? response.data!;
        
        debugPrint('=== Product Detail Service Debug ===');
        debugPrint('Response data keys: ${responseData.keys.toList()}');
        
        // Find the product in the response arrays since there's no direct 'product' key
        Map<String, dynamic>? productJson;
        
        // Search in suggested_category_products first
        final suggestedProducts = responseData['suggested_category_products'] as List? ?? [];
        for (var product in suggestedProducts) {
          if (product['id'] == productId) {
            productJson = product as Map<String, dynamic>;
            debugPrint('Found product $productId in suggested_category_products');
            break;
          }
        }
        
        // If not found, search in frequently_bought
        if (productJson == null) {
          final frequentlyBought = responseData['frequently_bought'] as List? ?? [];
          for (var product in frequentlyBought) {
            if (product['id'] == productId) {
              productJson = product as Map<String, dynamic>;
              debugPrint('Found product $productId in frequently_bought');
              break;
            }
          }
        }
        
        // If not found, search in relatedProducts
        if (productJson == null) {
          final relatedProducts = responseData['relatedProducts'] as List? ?? [];
          for (var product in relatedProducts) {
            if (product['id'] == productId) {
              productJson = product as Map<String, dynamic>;
              debugPrint('Found product $productId in relatedProducts');
              break;
            }
          }
        }
        
        // If still not found, fallback to responseData itself (shouldn't happen)
        if (productJson == null) {
          debugPrint('Product $productId not found in any array, using responseData as fallback');
          productJson = responseData;
        }
        
        debugPrint('Product JSON keys: ${productJson?.keys.toList()}');
        debugPrint('Product ID: ${productJson?['id']}');
        debugPrint('Product title: ${productJson?['title']}');
        debugPrint('Product variants: ${productJson?['variant']}');
        debugPrint('Product media: ${productJson?['media']}');
        debugPrint('Product vendor: ${productJson?['vendor']?['name']}');
        
        // Ensure we have a valid product
        if (productJson == null) {
          return ApiResponse.error(message: 'Product $productId not found in response');
        }
        
        // Extract coupon list for offers
        final couponList = responseData['coupon_list'] as List? ?? [];
        debugPrint('Coupons count: ${couponList.length}');
        
        // Extract related products (avoid variable name conflict)
        final relatedProductsArray = responseData['relatedProducts'] as List? ?? [];
        final suggestedProductsArray = responseData['suggested_category_products'] as List? ?? [];
        final frequentlyBoughtArray = responseData['frequently_bought'] as List? ?? [];
        debugPrint('Related products count: ${relatedProductsArray.length + suggestedProductsArray.length + frequentlyBoughtArray.length}');
        
        // Create the product model
        final product = ProductModel.fromJson(productJson);
        debugPrint('Parsed product name: ${product.name}');
        debugPrint('Parsed product price: ${product.price}');
        debugPrint('Parsed product images: ${product.media?.length ?? 0}');
        debugPrint('=====================================');
        
        // Convert coupons to offers
        final offers = couponList.map((coupon) => OfferModel.fromJson(coupon)).toList();
        
        // Combine all related products
        final allRelatedProducts = [...relatedProductsArray, ...suggestedProductsArray, ...frequentlyBoughtArray];
        
        return ApiResponse.success(data: {
          'product': product,
          'offers': offers,
          'relatedProducts': allRelatedProducts,
        });
      } catch (e) {
        debugPrint('Error parsing product details with extras: $e');
        debugPrint('Response data: ${response.data}');
        return ApiResponse.error(message: 'Failed to parse product details: $e');
      }
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load product details',
      errors: response.errors,
    );
  }

  Future<ApiResponse<List<OfferModel>>> getProductOffers({
    required int productId,
  }) async {
    // Since offers come from the main product endpoint, we'll get them from there
    final response = await getProductDetailsWithExtras(productId: productId);
    
    if (response.success && response.data != null) {
      try {
        final offers = response.data!['offers'] as List<OfferModel>? ?? [];
        return ApiResponse.success(data: offers);
      } catch (e) {
        debugPrint('Error getting offers: $e');
        return ApiResponse.error(message: 'Failed to get offers');
      }
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load offers',
      errors: response.errors,
    );
  }

  Future<ApiResponse<bool>> submitReview({
    required int productId,
    required double rating,
    required String reviewText,
    int? orderId,
    int? orderVendorProductId,
    List<String>? imageUrls,
  }) async {
    Map<String, dynamic> requestBody = {
      'product_id': productId,
      'rating': rating.toInt(), // API expects integer rating
      'review': reviewText,
    };

    // Add required order context if available
    if (orderId != null) {
      requestBody['order_id'] = orderId;
    }
    if (orderVendorProductId != null) {
      requestBody['order_vendor_product_id'] = orderVendorProductId;
    }

    if (imageUrls != null && imageUrls.isNotEmpty) {
      requestBody['review_images'] = imageUrls;
    }

    final response = await _apiService.post<Map<String, dynamic>>(
      '/rating/update-product-rating',
      data: requestBody,
    );

    if (response.success) {
      return ApiResponse.success(data: true);
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to submit review',
      errors: response.errors,
    );
  }

  Future<ApiResponse<List<ProductModel>>> getRelatedProducts({
    required int productId,
    int? categoryId,
    int? vendorId,
    int limit = 10,
  }) async {
    Map<String, dynamic> queryParams = {
      'limit': limit.toString(),
    };

    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }

    if (vendorId != null) {
      queryParams['vendor_id'] = vendorId.toString();
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/product/$productId/related',
      queryParameters: queryParams,
    );

    if (response.success && response.data != null) {
      try {
        final productsData = response.data!['data'] ?? response.data!;
        final products = (productsData['products'] as List?)
            ?.map((productJson) => ProductModel.fromJson(productJson))
            .toList() ?? [];
        return ApiResponse.success(data: products);
      } catch (e) {
        debugPrint('Error parsing related products: $e');
        return ApiResponse.error(message: 'Failed to parse related products');
      }
    }

    return ApiResponse.error(
      message: response.message ?? 'Failed to load related products',
      errors: response.errors,
    );
  }
}