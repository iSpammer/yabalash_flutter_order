import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/payment/models/place_order_model.dart';

void main() {
  group('PaymentService Unit Tests', () {
    test('PlaceOrderRequest should generate correct JSON for cash payment', () {
      // Arrange
      final request = PlaceOrderRequest(
        selectedAddressId: 123,
        paymentOptionId: 1,
        tip: 5.0,
        deliveryInstructions: 'Ring doorbell',
        orderNote: 'No onions please',
        scheduleType: 'now',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['address_id'], 123);
      expect(json['payment_option_id'], 1);
      expect(json['tip_amount'], 5.0);
      expect(json['comment_for_pickup_driver'], 'Ring doorbell');
      expect(json['comment_for_vendor'], 'No onions please');
      expect(json['order_type'], 'delivery');
      expect(json.containsKey('card_number'), false);
    });

    test('PlaceOrderRequest should generate correct JSON for card payment', () {
      // Arrange
      final request = PlaceOrderRequest(
        selectedAddressId: 456,
        paymentOptionId: 2,
        cardNumber: '4111111111111111',
        cardHolderName: 'John Doe',
        expiryMonth: '12',
        expiryYear: '25',
        cvv: '123',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['address_id'], 456);
      expect(json['payment_option_id'], 2);
      expect(json['card_number'], '4111111111111111');
      expect(json['card_holder_name'], 'John Doe');
      expect(json['expiry_month'], '12');
      expect(json['expiry_year'], '25');
      expect(json['cvv'], '123');
    });

    test('PlaceOrderRequest should handle scheduled delivery', () {
      // Arrange
      final scheduledTime = DateTime(2025, 6, 3, 14, 30);
      final request = PlaceOrderRequest(
        selectedAddressId: 789,
        paymentOptionId: 1,
        scheduleType: 'schedule',
        scheduledDateTime: scheduledTime,
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['schedule_type'], 'schedule');
      expect(json['scheduled_date_time'], '2025-06-03T14:30:00.000');
    });

    test('PlaceOrderResponse should handle different response scenarios', () {
      // Test successful order response with 200 status
      final successResponse = PlaceOrderResponse(
        status: '200',
        message: 'Order placed successfully',
        data: OrderData(
          id: 123,
          orderNumber: 'ORD123',
        ),
      );

      expect(successResponse.isSuccess, true);
      expect(successResponse.requiresPayment, false);

      // Test successful order response with 201 status
      final createdResponse = PlaceOrderResponse(
        status: '201',
        message: 'Order created successfully',
        data: OrderData(
          id: 456,
          orderNumber: 'ORD456',
        ),
      );

      expect(createdResponse.isSuccess, true);
      expect(createdResponse.requiresPayment, false);

      // Test payment required response
      final paymentRequiredResponse = PlaceOrderResponse(
        status: '200',
        requiresPayment: true,
        paymentUrl: 'https://payment.gateway.com/pay',
      );

      expect(paymentRequiredResponse.isSuccess, true);
      expect(paymentRequiredResponse.requiresPayment, true);
      expect(paymentRequiredResponse.paymentUrl, 'https://payment.gateway.com/pay');

      // Test error response
      final errorResponse = PlaceOrderResponse(
        status: '400',
        message: 'Invalid payment method',
      );

      expect(errorResponse.isSuccess, false);
      expect(errorResponse.requiresPayment, false);
    });
  });
}