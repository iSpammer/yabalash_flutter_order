import 'package:flutter/foundation.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/api_response.dart';
import '../models/order_model.dart';
import '../models/order_response_model.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  /// Get user orders with optional type filter
  /// Types: 'active', 'past', 'pending', 'schedule'
  Future<ApiResponse<List<OrderModel>>> getUserOrders({
    String type = 'past',
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/orders',
        queryParameters: {
          'type': type,
          'limit': limit,
          'page': page,
        },
      );

      if (response.success && response.data != null) {
        // Handle paginated response structure
        dynamic ordersData;

        // Check if response has pagination structure
        if (response.data!['data'] is Map &&
            response.data!['data']['data'] is List) {
          // Paginated response: data.data contains the orders array
          ordersData = response.data!['data']['data'];
        } else if (response.data!['data'] is List) {
          // Direct array response
          ordersData = response.data!['data'];
        } else {
          ordersData = response.data!;
        }

        debugPrint('=== Orders Service Debug ===');
        debugPrint('Orders data type: ${ordersData.runtimeType}');
        debugPrint('=====================================');

        List<OrderModel> orders = [];

        if (ordersData is List) {
          orders = ordersData.map((orderJson) {
            try {
              debugPrint('\n=== Processing Order ===');
              debugPrint('Order ID: ${orderJson['id']}');
              debugPrint('Order Number: ${orderJson['order_number']}');
              debugPrint('Dispatch Tracking URL: ${orderJson['dispatch_traking_url']}');
              debugPrint('Order data keys: ${orderJson.keys.toList()}');

              // Log specific fields that might cause issues
              debugPrint('Field types:');
              debugPrint('  - id: ${orderJson['id']?.runtimeType}');
              debugPrint('  - order_id: ${orderJson['order_id']?.runtimeType}');
              debugPrint(
                  '  - vendor_id: ${orderJson['vendor_id']?.runtimeType}');
              debugPrint('  - user_id: ${orderJson['user_id']?.runtimeType}');
              debugPrint('  - status: ${orderJson['status']?.runtimeType}');
              debugPrint(
                  '  - order_status_option_id: ${orderJson['order_status_option_id']?.runtimeType}');
              debugPrint(
                  '  - delivery_fee: ${orderJson['delivery_fee']?.runtimeType}');
              debugPrint(
                  '  - payable_amount: ${orderJson['payable_amount']?.runtimeType}');
              debugPrint('  - type: ${orderJson['type']?.runtimeType}');
              debugPrint(
                  '  - courier_id: ${orderJson['courier_id']?.runtimeType}');
              debugPrint('  - dispatch_traking_url: ${orderJson['dispatch_traking_url']?.runtimeType}');

              // First try to parse as OrderResponseModel (matches API structure)
              final responseModel = OrderResponseModel.fromJson(orderJson);
              return responseModel.toOrderModel();
            } catch (e, stackTrace) {
              // Fallback to direct OrderModel parsing
              debugPrint('OrderResponseModel parsing failed: $e');
              debugPrint('Stack trace: $stackTrace');
              try {
                debugPrint('Trying direct OrderModel parsing...');
                return OrderModel.fromJson(orderJson);
              } catch (e2, stackTrace2) {
                debugPrint('Direct OrderModel parsing also failed: $e2');
                debugPrint('Stack trace: $stackTrace2');
                rethrow;
              }
            }
          }).toList();
        } else if (ordersData is Map && ordersData['orders'] != null) {
          final ordersList = ordersData['orders'] as List;
          orders = ordersList.map((orderJson) {
            try {
              debugPrint('\n=== Processing Order (from Map) ===');
              debugPrint('Order ID: ${orderJson['id']}');
              debugPrint('Order data keys: ${orderJson.keys.toList()}');

              // Log specific fields that might cause issues
              debugPrint('Field types:');
              debugPrint('  - id: ${orderJson['id']?.runtimeType}');
              debugPrint('  - order_id: ${orderJson['order_id']?.runtimeType}');
              debugPrint(
                  '  - vendor_id: ${orderJson['vendor_id']?.runtimeType}');
              debugPrint('  - user_id: ${orderJson['user_id']?.runtimeType}');
              debugPrint('  - status: ${orderJson['status']?.runtimeType}');
              debugPrint(
                  '  - order_status_option_id: ${orderJson['order_status_option_id']?.runtimeType}');
              debugPrint(
                  '  - delivery_fee: ${orderJson['delivery_fee']?.runtimeType}');
              debugPrint(
                  '  - payable_amount: ${orderJson['payable_amount']?.runtimeType}');
              debugPrint('  - type: ${orderJson['type']?.runtimeType}');
              debugPrint(
                  '  - courier_id: ${orderJson['courier_id']?.runtimeType}');

              // First try to parse as OrderResponseModel (matches API structure)
              final responseModel = OrderResponseModel.fromJson(orderJson);
              return responseModel.toOrderModel();
            } catch (e, stackTrace) {
              // Fallback to direct OrderModel parsing
              debugPrint('OrderResponseModel parsing failed: $e');
              debugPrint('Stack trace: $stackTrace');
              try {
                debugPrint('Trying direct OrderModel parsing...');
                return OrderModel.fromJson(orderJson);
              } catch (e2, stackTrace2) {
                debugPrint('Direct OrderModel parsing also failed: $e2');
                debugPrint('Stack trace: $stackTrace2');
                rethrow;
              }
            }
          }).toList();
        }

        debugPrint('Loaded ${orders.length} orders of type: $type');
        return ApiResponse.success(data: orders);
      }

      return ApiResponse.error(
          message: response.message ?? 'Failed to load orders');
    } catch (e) {
      debugPrint('Error loading orders: $e');
      return ApiResponse.error(message: 'Failed to load orders: $e');
    }
  }

  /// Check if user can review a specific product
  /// Returns the order context needed for review submission
  Future<ApiResponse<Map<String, dynamic>?>> checkProductReviewEligibility({
    required int productId,
  }) async {
    try {
      // Get user's past (delivered) orders
      final ordersResponse = await getUserOrders(type: 'past');

      if (!ordersResponse.success || ordersResponse.data == null) {
        return ApiResponse.error(message: 'Failed to load order history');
      }

      final orders = ordersResponse.data!;

      // Look for this product in delivered orders
      for (final order in orders) {
        // Check if order is delivered (status 6)
        if (order.statusId != 6) continue;

        // Check if order contains the product
        OrderProductModel? orderProduct;
        try {
          orderProduct = order.products?.firstWhere(
            (product) => product.productId == productId,
          );
        } catch (e) {
          // Product not found in this order
          orderProduct = null;
        }

        if (orderProduct != null) {
          // User can review this product
          return ApiResponse.success(data: {
            'canReview': true,
            'orderId': order.id,
            'orderVendorProductId': orderProduct.id,
            'orderDate': order.createdAt,
          });
        }
      }

      // User hasn't ordered this product or order not delivered
      return ApiResponse.success(data: {
        'canReview': false,
        'reason': 'Product not ordered or order not delivered yet',
      });
    } catch (e) {
      debugPrint('Error checking review eligibility: $e');
      return ApiResponse.error(
          message: 'Failed to check review eligibility: $e');
    }
  }

  /// Get driver tracking details for an order
  Future<ApiResponse<Map<String, dynamic>>> getDriverTrackingDetails({
    required int orderId,
    String? trackingUrl,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'order_id': orderId,
      };

      if (trackingUrl != null && trackingUrl.isNotEmpty) {
        requestData['new_dispatch_traking_url'] = trackingUrl;
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        '/pickup-delivery/order-tracking-details',
        data: requestData,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] ?? response.data!;

        debugPrint('=== Driver Tracking Response ===');
        debugPrint('Has agent_location: ${data['agent_location'] != null}');
        if (data['agent_location'] != null) {
          debugPrint('Agent location: ${data['agent_location']}');
        }
        debugPrint('Has agent_image: ${data['agent_image'] != null}');
        debugPrint('Has tasks: ${data['tasks'] != null}');
        debugPrint('=====================================');

        return ApiResponse.success(data: data);
      }

      return ApiResponse.error(
          message: response.message ?? 'Failed to load driver tracking');
    } catch (e) {
      debugPrint('Error loading driver tracking: $e');
      return ApiResponse.error(message: 'Failed to load driver tracking: $e');
    }
  }

  /// Get order details by ID (alias for backward compatibility)
  Future<ApiResponse<OrderModel>> getOrderDetail(Map<String, dynamic> data) async {
    final orderId = data['order_id'] as int;
    final vendorId = data['vendor_id'] as int?;
    return getOrderDetails(orderId: orderId, vendorId: vendorId);
  }

  /// Get raw order details JSON (for compatibility with existing screens)
  Future<ApiResponse<Map<String, dynamic>>> getOrderDetailRaw(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/order-detail',
        data: data,
      );

      if (response.success && response.data != null) {
        // Return the raw nested structure
        Map<String, dynamic> orderData;
        if (response.data!['data'] != null &&
            response.data!['data']['order'] != null) {
          // API returns: { data: { order: {...} } }
          orderData = response.data!['data']['order'];
        } else if (response.data!['order'] != null) {
          // API returns: { order: {...} }
          orderData = response.data!['order'];
        } else if (response.data!['data'] != null) {
          // API returns: { data: {...} }
          orderData = response.data!['data'];
        } else {
          // Direct response
          orderData = response.data!;
        }

        return ApiResponse.success(data: orderData);
      }

      return ApiResponse.error(
          message: response.message ?? 'Failed to load order details');
    } catch (e) {
      debugPrint('Error loading order details: $e');
      return ApiResponse.error(message: 'Failed to load order details: $e');
    }
  }

  /// Get order details by ID
  Future<ApiResponse<OrderModel>> getOrderDetails({
    required int orderId,
    int? vendorId,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/order-detail',
        data: {
          'order_id': orderId,
          if (vendorId != null) 'vendor_id': vendorId,
        },
      );

      if (response.success && response.data != null) {
        // The order detail API returns data in a nested structure
        Map<String, dynamic> orderData;
        if (response.data!['data'] != null &&
            response.data!['data']['order'] != null) {
          // API returns: { data: { order: {...} } }
          orderData = response.data!['data']['order'];
        } else if (response.data!['order'] != null) {
          // API returns: { order: {...} }
          orderData = response.data!['order'];
        } else if (response.data!['data'] != null) {
          // API returns: { data: {...} }
          orderData = response.data!['data'];
        } else {
          // Direct response
          orderData = response.data!;
        }

        debugPrint('=== Order Detail Response ===');
        debugPrint('Order ID: ${orderData['id']}');
        debugPrint('Has vendors array: ${orderData['vendors'] != null}');
        debugPrint(
            'Raw dispatch_traking_url: ${orderData['dispatch_traking_url']}');
        if (orderData['vendors'] != null) {
          debugPrint('Vendors count: ${(orderData['vendors'] as List).length}');
          final firstVendor = (orderData['vendors'] as List).first;
          debugPrint('First vendor keys: ${firstVendor.keys.toList()}');
          debugPrint(
              'First vendor dispatch_traking_url: ${firstVendor['dispatch_traking_url']}');
          debugPrint(
              'First vendor dispatcher_status_option_id: ${firstVendor['dispatcher_status_option_id']}');
          debugPrint(
              'First vendor has vendor object: ${firstVendor['vendor'] != null}');
          if (firstVendor['vendor'] != null) {
            debugPrint(
                'Vendor object keys: ${firstVendor['vendor'].keys.toList()}');
          }
        }
        debugPrint('Order data keys: ${orderData.keys.toList()}');
        debugPrint('=====================================');

        debugPrint('About to parse OrderModel from orderData...');
        try {
          final order = OrderModel.fromJson(orderData);
          debugPrint('Successfully parsed OrderModel');
          return ApiResponse.success(data: order);
        } catch (parseError, stackTrace) {
          debugPrint('ERROR parsing OrderModel: $parseError');
          debugPrint('Stack trace: $stackTrace');
          rethrow;
        }
      }

      return ApiResponse.error(
          message: response.message ?? 'Failed to load order details');
    } catch (e) {
      debugPrint('Error loading order details: $e');
      return ApiResponse.error(message: 'Failed to load order details: $e');
    }
  }

  /// Cancel an order - matches React Native implementation exactly
  Future<ApiResponse<Map<String, dynamic>>> cancelOrder({
    required int orderId,
    required int vendorId,
    required String rejectReason,
    int? cancelReasonId,
    int? statusOptionId,
  }) async {
    try {
      // Match React Native API call exactly
      final response = await _apiService.post<Map<String, dynamic>>(
        '/return-order/vendor-order-for-cancel',
        data: {
          'order_id': orderId,
          'vendor_id': vendorId,
          'reject_reason': rejectReason,
          if (cancelReasonId != null) 'cancel_reason_id': cancelReasonId,
          if (statusOptionId != null) 'status_option_id': statusOptionId,
        },
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'currency': '63', // As specified in the requirements
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return ApiResponse.error(message: 'Error cancelling order: $e');
    }
  }

  /// Get cancellation reasons
  Future<ApiResponse<List<Map<String, dynamic>>>>
      getCancellationReasons() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/cancellation-reason',
      );

      if (response.success && response.data != null) {
        final List<dynamic> reasons = response.data!['data'] ?? [];
        return ApiResponse.success(
          data: reasons.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }

      return ApiResponse.error(message: 'Failed to load cancellation reasons');
    } catch (e) {
      debugPrint('Error loading cancellation reasons: $e');
      return ApiResponse.error(
          message: 'Error loading cancellation reasons: $e');
    }
  }

  /// Repeat an order
  Future<ApiResponse<Map<String, dynamic>>> repeatOrder({
    required int orderVendorId,
    required int cartId,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/repeatOrder',
        data: {
          'order_vendor_id': orderVendorId,
          'cart_id': cartId,
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error repeating order: $e');
      return ApiResponse.error(message: 'Error repeating order: $e');
    }
  }

  /// Get return order details
  Future<ApiResponse<Map<String, dynamic>>> getReturnOrderDetails({
    required int orderId,
    required int vendorId,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/return-order/get-order-data-in-model',
        queryParameters: {
          'id': orderId,
          'vendor_id': vendorId,
        },
      );

      return response;
    } catch (e) {
      debugPrint('Error loading return order details: $e');
      return ApiResponse.error(
          message: 'Error loading return order details: $e');
    }
  }

  /// Get products for replace
  Future<ApiResponse<List<Map<String, dynamic>>>> getProductsForReplace({
    required int orderId,
    required int vendorId,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/return-order/get-products-for-replace',
        queryParameters: {
          'id': orderId,
          'vendor_id': vendorId,
        },
      );

      if (response.success && response.data != null) {
        final List<dynamic> products = response.data!['data'] ?? [];
        return ApiResponse.success(
          data: products.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }

      return ApiResponse.error(message: 'Failed to load products for replace');
    } catch (e) {
      debugPrint('Error loading products for replace: $e');
      return ApiResponse.error(
          message: 'Error loading products for replace: $e');
    }
  }

}
