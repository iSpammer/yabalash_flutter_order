import '../../../core/api/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/payment_method_model.dart';
import '../models/place_order_model.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  Future<List<PaymentMethod>> getPaymentMethods({
    required String authToken,
  }) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        ApiConstants.paymentOptions,
        headers: {'Authorization': 'Bearer $authToken'},
        fromJsonT: (json) {
          if (json is List) {
            return json;
          }
          return [];
        },
      );

      if (response.success && response.data != null) {
        final List<dynamic> methodsJson = response.data ?? [];
        return methodsJson
            .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
            .where((method) => method.isActive)
            .toList();
      } else {
        throw Exception(response.message ?? 'Failed to load payment methods');
      }
    } catch (e) {
      throw Exception('Failed to load payment methods: $e');
    }
  }

  Future<PlaceOrderResponse> placeOrder({
    required String authToken,
    required PlaceOrderRequest request,
  }) async {
    try {
      final response = await _apiService.postDirect<Map<String, dynamic>>(
        ApiConstants.placeOrder,
        data: request.toJson(),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      // Use postDirect which gives us the full response
      final responseData = response.data ?? {};
      
      // If the response doesn't have a status field, add the HTTP status code
      if (!responseData.containsKey('status') && response.statusCode != null) {
        responseData['status'] = response.statusCode.toString();
      }
      
      final placeOrderResponse = PlaceOrderResponse.fromJson(responseData);

      // Remove the unnecessary exception throwing - let the provider handle success/failure
      return placeOrderResponse;
    } catch (e) {
      // Only throw if there's an actual error in the API call or parsing
      if (e.toString().contains('Failed to place order:')) {
        throw e;
      }
      throw Exception('Failed to place order: $e');
    }
  }

  Future<String> generatePaymentUrl({
    required String authToken,
    required String paymentMethodKey,
    required double amount,
    required int paymentOptionId,
    required String orderNumber,
  }) async {
    try {
      // Generate payment URL for online payment methods
      final requestData = {
        'amount': amount,
        'order_number': orderNumber,
        'action': 'cart',
        'payment_from': 'cart',
        'returnUrl': '/payment-success',
      };

      final response = await _apiService.postDirect<String>(
        '${ApiConstants.getWebUrl}/$paymentMethodKey',
        data: requestData,
        headers: {'Authorization': 'Bearer $authToken'},
        extractField: 'payment_url',
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
      
      throw Exception(response.message ?? 'Failed to generate payment URL');
    } catch (e) {
      throw Exception('Failed to generate payment URL: $e');
    }
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String authToken,
    required String orderNumber,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.orderAfterPayment,
        data: {
          'order_number': orderNumber,
          ...paymentData,
        },
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.success) {
        return response.data ?? {};
      } else {
        throw Exception(response.message ?? 'Failed to confirm payment');
      }
    } catch (e) {
      throw Exception('Failed to confirm payment: $e');
    }
  }
}
