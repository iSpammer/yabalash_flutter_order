import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/api_response.dart';
import '../models/cart_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'product_variant_service.dart';

class CartService {
  final ApiService _apiService = ApiService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Helper method to get timezone string in format like "+03" or "-05"
  String _getTimezoneString() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes.abs() % 60);
    final sign = offset.isNegative ? '-' : '+';
    return minutes > 0 
        ? '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}'
        : '$sign${hours.toString().padLeft(2, '0')}';
  }

  // Helper method to get common headers
  Future<Map<String, String>> _getHeaders() async {
    String deviceId = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceId = androidInfo.id ?? '';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    final prefs = await SharedPreferences.getInstance();
    final countryCode = prefs.getString('countryCode') ?? '2b5f69';
    final currencyId = prefs.getString('currencyId') ?? '5';
    final language = prefs.getString('language') ?? '1';

    return {
      'systemuser': deviceId,
      'timezone': _getTimezoneString(),
      'code': countryCode,
      'currency': currencyId,
      'language': language,
    };
  }

  // Helper method to extract error message from response
  String _extractErrorMessage(dynamic messageData, String defaultMessage) {
    if (messageData == null) return defaultMessage;

    if (messageData is Map) {
      return messageData['error'] ?? messageData.toString();
    } else if (messageData is String) {
      return messageData;
    } else {
      return messageData.toString();
    }
  }

  // 1. ✅ Add Product to Cart
  Future<ApiResponse<CartModel>> addToCart({
    required String sku,
    required int quantity,
    int? productVariantId,
    List<Map<String, dynamic>>? addons,
    String type = 'delivery',
    String? scheduledDateTime,
    String? scheduleType,
    String? scheduleSlot,
    int? productId, // Add product ID parameter
  }) async {
    try {
      // Convert pickup to takeaway for API compatibility
      final apiType = type == 'pickup' ? 'takeaway' : type;
      
      final Map<String, dynamic> data = {
        'sku': sku,
        'quantity': quantity,
        'type': apiType,
      };

      if (productVariantId != null) {
        data['product_variant_id'] = productVariantId;
      }

      // Add product ID if provided
      if (productId != null) {
        data['product_id'] = productId;
      }

      debugPrint('=== ADD TO CART REQUEST DATA ===');
      debugPrint('SKU: $sku');
      debugPrint('Quantity: $quantity');
      debugPrint('Type: $type (API type: $apiType)');
      debugPrint('Product ID: $productId');
      debugPrint('Product Variant ID: $productVariantId');
      debugPrint('Full data: $data');

      if (addons != null && addons.isNotEmpty) {
        data['addon_ids'] = addons.map((addon) => addon['id']).toList();
        data['addon_options'] =
            addons.map((addon) => addon['option_id']).toList();
      }

      // Add scheduled delivery parameters if provided
      if (scheduledDateTime != null) {
        data['scheduled_date_time'] = scheduledDateTime;
      }
      if (scheduleType != null) {
        data['schedule_type'] = scheduleType;
      }
      if (scheduleSlot != null) {
        data['schedule_slot'] = scheduleSlot;
      }

      final headers = await _getHeaders();

      final response = await _apiService.post(
        ApiConstants.addToCart,
        data: data,
        headers: headers,
      );

      // Debug logging
      debugPrint('=== ADD TO CART RESPONSE ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Message: ${response.message}');
      debugPrint('Data type: ${response.data.runtimeType}');
      debugPrint('Data: ${response.data}');

      if (response.success) {
        debugPrint('✅ Successfully added to cart');
        if (response.data != null) {
          if (response.data is List && (response.data as List).isEmpty) {
            return ApiResponse.success(
              data: CartModel(products: []),
              message: response.message ?? 'Item added to cart',
            );
          } else if (response.data is Map<String, dynamic>) {
            final cartData = CartModel.fromJson(response.data);
            return ApiResponse.success(
              data: cartData,
              message: response.message ?? 'Item added successfully',
            );
          } else {
            return ApiResponse.error(
              message: 'Unexpected response format from server',
            );
          }
        } else {
          return ApiResponse.success(
            data: CartModel(products: []),
            message: response.message ?? 'Item added to cart',
          );
        }
      } else {
        String errorMessage = response.message ?? 'Failed to add to cart';
        
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = _extractErrorMessage(response.data['message'], errorMessage);
        }
        
        return ApiResponse.error(
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to add to cart';
      
      if (e.response?.data != null) {
        try {
          if (e.response!.data is Map) {
            final responseData = e.response!.data as Map<String, dynamic>;
            
            if (responseData.containsKey('message')) {
              final messageData = responseData['message'];
              errorMessage = _extractErrorMessage(messageData, errorMessage);
              
              if (messageData is Map && messageData['alert'] == 1) {
                debugPrint('Vendor conflict detected with alert flag');
              }
            }
          } else if (e.response!.data is String) {
            errorMessage = e.response!.data as String;
          }
        } catch (parseError) {
          debugPrint('Error parsing error response: $parseError');
        }
      }

      return ApiResponse.error(
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to add to cart',
      );
    }
  }

  // 2. ✅ Get Cart List
  Future<ApiResponse<CartModel>> getCartDetail({
    String type = 'delivery',
    int? addressId,
  }) async {
    try {
      // Convert pickup to takeaway for API compatibility
      final apiType = type == 'pickup' ? 'takeaway' : type;
      
      final headers = await _getHeaders();

      // Build query parameters
      String queryParams = '?type=$apiType';
      if (addressId != null) {
        queryParams += '&address_id=$addressId';
      }

      debugPrint('Cart API URL: ${ApiConstants.cartList}$queryParams');
      debugPrint('Cart API Headers: $headers');

      final responseFromApiService = await _apiService.get(
        '${ApiConstants.cartList}$queryParams',
        headers: headers,
      );

      final dynamic cartDataPayload = responseFromApiService.data;

      if (responseFromApiService.success) {
        if (cartDataPayload is Map<String, dynamic>) {
          final cartModel = CartModel.fromJson(cartDataPayload);
          return ApiResponse.success(
            data: cartModel,
            message: responseFromApiService.message ?? 'Cart details loaded successfully.',
          );
        } else if (cartDataPayload is List && cartDataPayload.isEmpty) {
          return ApiResponse.success(
            data: CartModel(products: []),
            message: 'Cart is empty.',
          );
        } else if (cartDataPayload == null) {
          return ApiResponse.success(
            data: CartModel(products: []),
            message: 'Cart data is null (empty cart).',
          );
        } else {
          return ApiResponse.error(
            message: 'Failed to load cart: Unexpected cart data format from server.',
          );
        }
      } else {
        String serverMessage = responseFromApiService.message ?? 'Failed to load cart';
        return ApiResponse.error(
          message: serverMessage,
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to load cart due to a network or server issue.';
      if (e.response?.data is Map<String, dynamic>) {
        final errorBody = e.response!.data as Map<String, dynamic>;
        final String? serverMsg =
            errorBody['message']?.toString() ?? errorBody['error']?.toString();
        if (serverMsg != null && serverMsg.isNotEmpty) {
          errorMessage = serverMsg;
        }
      } else if (e.response?.data is String &&
          (e.response!.data as String).isNotEmpty) {
        errorMessage = e.response!.data as String;
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }
      return ApiResponse.error(message: errorMessage);
    } catch (e, s) {
      debugPrint('Generic error getting cart details: $e');
      debugPrint('Stack trace for generic error: $s');
      return ApiResponse.error(
          message: 'Failed to load cart due to an unexpected error.');
    }
  }

  // 3. ✅ Update Cart Item Quantity
  Future<ApiResponse<CartModel>> updateCartQuantity({
    required int cartId,
    required int cartProductId,
    required int quantity,
    String type = 'delivery',
  }) async {
    try {
      // Convert pickup to takeaway for API compatibility
      final apiType = type == 'pickup' ? 'takeaway' : type;
      
      final headers = await _getHeaders();

      final response = await _apiService.post(
        ApiConstants.updateCart,
        data: {
          'cart_id': cartId,
          'cart_product_id': cartProductId,
          'quantity': quantity,
          'type': apiType,
        },
        headers: headers,
      );

      if (response.success) {
        if (response.data != null) {
          if (response.data is List && (response.data as List).isEmpty) {
            return ApiResponse.success(
              data: CartModel(products: []),
              message: response.message ?? 'Cart updated successfully',
            );
          } else if (response.data is Map<String, dynamic>) {
            final cartData = CartModel.fromJson(response.data);
            return ApiResponse.success(
              data: cartData,
              message: response.message ?? 'Cart updated successfully',
            );
          } else {
            return ApiResponse.error(
              message: 'Unexpected response format from server',
            );
          }
        } else {
          return ApiResponse.success(
            data: CartModel(products: []),
            message: response.message ?? 'Cart updated successfully',
          );
        }
      } else {
        String errorMessage = response.message ?? 'Failed to update cart';
        
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = _extractErrorMessage(response.data['message'], errorMessage);
        }
        
        return ApiResponse.error(
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(
          e.response?.data?['message'], 'Failed to update cart');
      return ApiResponse.error(
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to update cart',
      );
    }
  }

  // 4. ✅ Get Total Cart Items
  Future<ApiResponse<int>> getTotalCartItems({int? cartId}) async {
    try {
      final headers = await _getHeaders();

      int? finalCartId = cartId;
      if (finalCartId == null) {
        final cartResponse = await getCartDetail();
        if (!cartResponse.success || cartResponse.data?.id == null) {
          return ApiResponse.error(message: 'No active cart found');
        }
        finalCartId = cartResponse.data!.id;
      }

      final response = await _apiService.get(
        '${ApiConstants.cartTotalItems}?cart_id=$finalCartId',
        headers: headers,
      );

      if (response.success) {
        final count = response.data?['total_items'] ?? 0;
        return ApiResponse.success(
          data: count is int ? count : int.tryParse(count.toString()) ?? 0,
          message: response.message,
        );
      } else {
        return ApiResponse.error(
          message: response.message ?? 'Failed to get total items',
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _extractErrorMessage(
            e.response?.data?['message'], 'Failed to get total items'),
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get total items',
      );
    }
  }

  // 5. ✅ Get Promo Code List
  Future<ApiResponse<List<Map<String, dynamic>>>> getPromoCodeList({
    required int vendorId,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await _apiService.post(
        ApiConstants.promoCodeList,
        data: {
          'vendor_id': vendorId,
        },
        headers: headers,
      );

      if (response.success) {
        final List<dynamic> data = response.data ?? [];
        final promoCodes = data.map((e) => Map<String, dynamic>.from(e)).toList();
        return ApiResponse.success(
          data: promoCodes,
          message: response.message ?? 'Promo codes fetched successfully',
        );
      } else {
        return ApiResponse.error(
          message: response.message ?? 'Failed to get promo codes',
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _extractErrorMessage(
            e.response?.data?['message'], 'Failed to get promo codes'),
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get promo codes',
      );
    }
  }

  // 6. ✅ Check Vendor Slots
  Future<ApiResponse<Map<String, dynamic>>> checkVendorSlots({
    required int vendorId,
    dynamic delivery = 1,
    String? date,
    int? cartId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _getHeaders();

      final data = {
        'vendor_id': vendorId,
        'delivery': delivery,
      };

      if (date != null) {
        data['date'] = date;
      }
      if (cartId != null) {
        data['cart_id'] = cartId;
      }
      if (latitude != null) {
        data['latitude'] = latitude;
      }
      if (longitude != null) {
        data['longitude'] = longitude;
      }

      final response = await _apiService.post(
        ApiConstants.vendorSlots,
        data: data,
        headers: headers,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          data: Map<String, dynamic>.from(response.data),
          message: response.message ?? 'Vendor slots fetched successfully',
        );
      } else {
        return ApiResponse.error(
          message: response.message ?? 'Failed to get vendor slots',
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _extractErrorMessage(
            e.response?.data?['message'], 'Failed to get vendor slots'),
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get vendor slots',
      );
    }
  }

  // 7. ✅ Update Cart Checked Status
  Future<ApiResponse<bool>> updateCartCheckedStatus({
    required int cartId,
    required int cartProductId,
    required bool isChecked,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await _apiService.post(
        ApiConstants.updateCartCheckedStatus,
        data: {
          'cart_id': cartId,
          'cart_product_id': cartProductId,
          'is_cart_checked': isChecked ? 1 : 0,
        },
        headers: headers,
      );

      if (response.success) {
        return ApiResponse.success(
          data: true,
          message: response.message ?? 'Cart status updated successfully',
        );
      } else {
        return ApiResponse.error(
          message: response.message ?? 'Failed to update cart status',
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _extractErrorMessage(
            e.response?.data?['message'], 'Failed to update cart status'),
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to update cart status',
      );
    }
  }

  // 8. ✅ Get Last Added Product Variant
  Future<ApiResponse<Map<String, dynamic>>> getLastAddedProductVariant({
    required int cartId,
    required int productId,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await _apiService.post(
        ApiConstants.getLastAddedProductVariant,
        data: {
          'cart_id': cartId,
          'product_id': productId,
        },
        headers: headers,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          data: response.data as Map<String, dynamic>,
          message: response.message,
        );
      } else {
        return ApiResponse.error(
          message: response.message ?? 'Failed to get last added variant',
        );
      }
    } on DioException catch (e) {
      return ApiResponse.error(
        message: _extractErrorMessage(
            e.response?.data?['message'], 'Failed to get last added variant'),
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to get last added variant',
      );
    }
  }

  // 9. ✅ Remove Item from Cart
  Future<ApiResponse<CartModel>> removeFromCart({
    required int cartId,
    required int cartProductId,
    String type = 'delivery',
  }) async {
    try {
      // Convert pickup to takeaway for API compatibility
      final apiType = type == 'pickup' ? 'takeaway' : type;
      
      final headers = await _getHeaders();

      final response = await _apiService.post(
        ApiConstants.removeCartProducts,
        data: {
          'cart_id': cartId,
          'cart_product_id': cartProductId,
          'type': apiType,
        },
        headers: headers,
      );

      if (response.success) {
        if (response.data != null) {
          if (response.data is List && (response.data as List).isEmpty) {
            return ApiResponse.success(
              data: CartModel(products: []),
              message: response.message ?? 'Item removed from cart',
            );
          } else if (response.data is Map<String, dynamic>) {
            final cartData = CartModel.fromJson(response.data);
            return ApiResponse.success(
              data: cartData,
              message: response.message ?? 'Item removed successfully',
            );
          } else {
            return ApiResponse.error(
              message: 'Unexpected response format from server',
            );
          }
        } else {
          return ApiResponse.success(
            data: CartModel(products: []),
            message: response.message ?? 'Item removed from cart',
          );
        }
      } else {
        String errorMessage = response.message ?? 'Failed to remove from cart';
        
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = _extractErrorMessage(response.data['message'], errorMessage);
        }
        
        return ApiResponse.error(
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(
          e.response?.data?['message'], 'Failed to remove from cart');
      return ApiResponse.error(
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to remove from cart',
      );
    }
  }

  // 10. ✅ Empty Cart
  Future<ApiResponse<bool>> clearCart() async {
    try {
      final headers = await _getHeaders();

      final response = await _apiService.get(
        ApiConstants.clearCart,
        headers: headers,
      );

      // The clear cart endpoint returns 200 OK with just a message field
      // Check if we got a successful HTTP response
      if (response.success || 
          (response.data is Map && 
           response.data['message'] != null && 
           response.data['message'].toString().toLowerCase().contains('success'))) {
        return ApiResponse.success(
          data: true,
          message: response.message ?? response.data?['message'] ?? 'Cart cleared successfully',
        );
      } else {
        String errorMessage = response.message ?? 'Failed to clear cart';
        
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = _extractErrorMessage(response.data['message'], errorMessage);
        }
        
        return ApiResponse.error(
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      // Check if it's actually a success response (200 OK)
      if (e.response?.statusCode == 200) {
        final responseData = e.response?.data;
        if (responseData is Map && 
            responseData['message'] != null && 
            responseData['message'].toString().toLowerCase().contains('success')) {
          return ApiResponse.success(
            data: true,
            message: responseData['message'] ?? 'Cart cleared successfully',
          );
        }
      }
      
      final errorMessage = _extractErrorMessage(
          e.response?.data?['message'], 'Failed to clear cart');
      return ApiResponse.error(
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to clear cart',
      );
    }
  }

  // 11. ✅ Add with Scheduled Delivery (same as addToCart with schedule params)
  // This is handled by the addToCart method with scheduledDateTime, scheduleType, scheduleSlot params

  // 12. ✅ Authenticated User Cart Operations
  // This is handled by all methods when auth token is available

  // Additional helper methods
  Future<ApiResponse<CartModel>> applyPromoCode({
    required int vendorId,
    required int cartId,
    required String promoCode,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await _apiService.post(
        ApiConstants.verifyPromoCode,
        data: {
          'vendor_id': vendorId,
          'cart_id': cartId,
          'coupon_code': promoCode,
        },
        headers: headers,
      );

      if (response.success) {
        if (response.data != null) {
          if (response.data is List && (response.data as List).isEmpty) {
            return ApiResponse.success(
              data: CartModel(products: []),
              message: response.message ?? 'Promo code applied',
            );
          } else if (response.data is Map<String, dynamic>) {
            final cartData = CartModel.fromJson(response.data);
            return ApiResponse.success(
              data: cartData,
              message: response.message ?? 'Promo code applied successfully',
            );
          } else {
            return ApiResponse.error(
              message: 'Unexpected response format from server',
            );
          }
        } else {
          return ApiResponse.success(
            data: CartModel(products: []),
            message: response.message ?? 'Promo code applied',
          );
        }
      } else {
        String errorMessage = response.message ?? 'Failed to apply promo code';
        
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = _extractErrorMessage(response.data['message'], errorMessage);
        }
        
        return ApiResponse.error(
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(
          e.response?.data?['message'], 'Failed to apply promo code');
      return ApiResponse.error(
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to apply promo code',
      );
    }
  }

  Future<ApiResponse<CartModel>> removePromoCode({
    required int vendorId,
    required int cartId,
    required int couponId,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await _apiService.post(
        ApiConstants.removePromoCode,
        data: {
          'vendor_id': vendorId,
          'cart_id': cartId,
          'coupon_id': couponId,
        },
        headers: headers,
      );

      if (response.success) {
        if (response.data != null) {
          if (response.data is List && (response.data as List).isEmpty) {
            return ApiResponse.success(
              data: CartModel(products: []),
              message: response.message ?? 'Promo code removed',
            );
          } else if (response.data is Map<String, dynamic>) {
            final cartData = CartModel.fromJson(response.data);
            return ApiResponse.success(
              data: cartData,
              message: response.message ?? 'Promo code removed successfully',
            );
          } else {
            return ApiResponse.error(
              message: 'Unexpected response format from server',
            );
          }
        } else {
          return ApiResponse.success(
            data: CartModel(products: []),
            message: response.message ?? 'Promo code removed',
          );
        }
      } else {
        String errorMessage = response.message ?? 'Failed to remove promo code';
        
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = _extractErrorMessage(response.data['message'], errorMessage);
        }
        
        return ApiResponse.error(
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(
          e.response?.data?['message'], 'Failed to remove promo code');
      return ApiResponse.error(
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to remove promo code',
      );
    }
  }

  Future<ApiResponse<CartModel>> scheduleOrder({
    required String taskType,
    DateTime? scheduledDateTime,
  }) async {
    try {
      final headers = await _getHeaders();

      final data = {
        'task_type': taskType,
      };

      if (taskType != 'now' && scheduledDateTime != null) {
        data['schedule_dt'] = scheduledDateTime.toIso8601String();
      }

      final response = await _apiService.post(
        ApiConstants.scheduleOrder,
        data: data,
        headers: headers,
      );

      if (response.success) {
        if (response.data != null) {
          if (response.data is List && (response.data as List).isEmpty) {
            return ApiResponse.success(
              data: CartModel(products: []),
              message: response.message ?? 'Order scheduled',
            );
          } else if (response.data is Map<String, dynamic>) {
            final cartData = CartModel.fromJson(response.data);
            return ApiResponse.success(
              data: cartData,
              message: response.message ?? 'Order scheduled successfully',
            );
          } else {
            return ApiResponse.error(
              message: 'Unexpected response format from server',
            );
          }
        } else {
          return ApiResponse.success(
            data: CartModel(products: []),
            message: response.message ?? 'Order scheduled',
          );
        }
      } else {
        String errorMessage = response.message ?? 'Failed to schedule order';
        
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = _extractErrorMessage(response.data['message'], errorMessage);
        }
        
        return ApiResponse.error(
          message: errorMessage,
        );
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(
          e.response?.data?['message'], 'Failed to schedule order');
      return ApiResponse.error(
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to schedule order',
      );
    }
  }
}