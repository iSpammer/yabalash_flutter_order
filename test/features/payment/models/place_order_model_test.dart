import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/payment/models/place_order_model.dart';

void main() {
  group('PlaceOrderRequest', () {
    test('should create JSON with all fields', () {
      // Arrange
      final request = PlaceOrderRequest(
        selectedAddressId: 123,
        paymentOptionId: 456,
        tip: 5.0,
        deliveryInstructions: 'Leave at door',
        orderNote: 'Extra spicy',
        scheduleType: 'schedule',
        scheduledDateTime: DateTime(2025, 6, 3, 12, 0),
        cardNumber: '4111111111111111',
        cardHolderName: 'John Doe',
        expiryMonth: '12',
        expiryYear: '25',
        cvv: '123',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['selectedAddressId'], 123);
      expect(json['payment_option_id'], 456);
      expect(json['tip'], 5.0);
      expect(json['comment_for_pickup_driver'], 'Leave at door');
      expect(json['comment_for_vendor'], 'Extra spicy');
      expect(json['schedule_type'], 'schedule');
      expect(json['scheduled_date_time'], '2025-06-03T12:00:00.000');
      expect(json['card_number'], '4111111111111111');
      expect(json['card_holder_name'], 'John Doe');
      expect(json['expiry_month'], '12');
      expect(json['expiry_year'], '25');
      expect(json['cvv'], '123');
      expect(json['action'], 'cart');
    });

    test('should create JSON with only required fields', () {
      // Arrange
      final request = PlaceOrderRequest(
        selectedAddressId: 123,
        paymentOptionId: 456,
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['selectedAddressId'], 123);
      expect(json['payment_option_id'], 456);
      expect(json['action'], 'cart');
      expect(json.containsKey('tip'), false);
      expect(json.containsKey('comment_for_pickup_driver'), false);
      expect(json.containsKey('comment_for_vendor'), false);
      expect(json.containsKey('schedule_type'), false);
    });

    test('should not include empty optional fields', () {
      // Arrange
      final request = PlaceOrderRequest(
        selectedAddressId: 123,
        paymentOptionId: 456,
        deliveryInstructions: '',
        orderNote: '',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json.containsKey('comment_for_pickup_driver'), false);
      expect(json.containsKey('comment_for_vendor'), false);
    });
  });

  group('PlaceOrderResponse', () {
    test('should parse successful order response', () {
      // Arrange
      final json = {
        'status': 200,
        'message': 'Order placed successfully',
        'data': {
          'order': {
            'id': 789,
            'order_number': 'ORD123456',
            'payable_amount': 50.0,
            'created_at': '2025-06-03T10:00:00Z',
          },
          'order_number': 'ORD123456',
          'order_id': 789,
        },
      };

      // Act
      final response = PlaceOrderResponse.fromJson(json);

      // Assert
      expect(response.status, 200);
      expect(response.message, 'Order placed successfully');
      expect(response.isSuccess, true);
      expect(response.requiresPayment, false);
      expect(response.data, isNotNull);
      expect(response.data!.orderId, 789);
      expect(response.data!.orderNumber, 'ORD123456');
      expect(response.data!.order!.id, 789);
      expect(response.data!.order!.orderNumber, 'ORD123456');
      expect(response.data!.order!.payableAmount, 50.0);
    });

    test('should parse response requiring payment', () {
      // Arrange
      final json = {
        'status': 200,
        'data': {
          'payment_required': true,
          'payment_url': 'https://payment.gateway.com/pay/123',
          'order_number': 'ORD123456',
        },
      };

      // Act
      final response = PlaceOrderResponse.fromJson(json);

      // Assert
      expect(response.requiresPayment, true);
      expect(response.paymentUrl, 'https://payment.gateway.com/pay/123');
      expect(response.orderNumber, 'ORD123456');
    });

    test('should handle error response', () {
      // Arrange
      final json = {
        'status': 400,
        'message': 'Invalid payment method',
      };

      // Act
      final response = PlaceOrderResponse.fromJson(json);

      // Assert
      expect(response.status, 400);
      expect(response.message, 'Invalid payment method');
      expect(response.isSuccess, false);
      expect(response.data, isNull);
    });

    test('should handle missing data gracefully', () {
      // Arrange
      final json = {
        'status': 200,
      };

      // Act
      final response = PlaceOrderResponse.fromJson(json);

      // Assert
      expect(response.status, 200);
      expect(response.message, isNull);
      expect(response.data, isNull);
      expect(response.requiresPayment, false);
      expect(response.paymentUrl, isNull);
    });
  });
}