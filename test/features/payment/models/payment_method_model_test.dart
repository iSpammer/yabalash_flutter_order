import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/payment/models/payment_method_model.dart';

void main() {
  group('PaymentMethodModel', () {
    test('should create PaymentMethod from JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'title': 'Credit Card',
        'credentials': 'stripe_key',
        'code': 'stripe',
        'off_site': 0,
        'status': 1,
        'is_instant_booking': 0,
      };

      // Act
      final paymentMethod = PaymentMethod.fromJson(json);

      // Assert
      expect(paymentMethod.id, 1);
      expect(paymentMethod.title, 'Credit Card');
      expect(paymentMethod.credentials, 'stripe_key');
      expect(paymentMethod.code, 'stripe');
      expect(paymentMethod.offSite, 0);
      expect(paymentMethod.status, 1);
      expect(paymentMethod.isInstantBooking, 0);
    });

    test('should correctly identify off-site payment', () {
      // Arrange
      final offSitePayment = PaymentMethod(
        id: 1,
        title: 'PayPal',
        offSite: 1,
        status: 1,
      );

      final onSitePayment = PaymentMethod(
        id: 2,
        title: 'Credit Card',
        offSite: 0,
        status: 1,
      );

      // Assert
      expect(offSitePayment.isOffSite, true);
      expect(onSitePayment.isOffSite, false);
    });

    test('should correctly identify cash on delivery', () {
      // Arrange
      final codPayment = PaymentMethod(
        id: 1,
        title: 'Cash on Delivery',
        code: 'cod',
        status: 1,
      );

      final cashPayment = PaymentMethod(
        id: 2,
        title: 'Pay with Cash',
        status: 1,
      );

      final cardPayment = PaymentMethod(
        id: 3,
        title: 'Credit Card',
        code: 'stripe',
        status: 1,
      );

      // Assert
      expect(codPayment.isCashOnDelivery, true);
      expect(cashPayment.isCashOnDelivery, true);
      expect(cardPayment.isCashOnDelivery, false);
    });

    test('should correctly identify card payment', () {
      // Arrange
      final stripePayment = PaymentMethod(
        id: 1,
        title: 'Pay with Stripe',
        code: 'stripe',
        status: 1,
      );

      final cardPayment = PaymentMethod(
        id: 2,
        title: 'Credit Card',
        status: 1,
      );

      final cashPayment = PaymentMethod(
        id: 3,
        title: 'Cash',
        status: 1,
      );

      // Assert
      expect(stripePayment.isCard, true);
      expect(cardPayment.isCard, true);
      expect(cashPayment.isCard, false);
    });

    test('should correctly identify active payment method', () {
      // Arrange
      final activePayment = PaymentMethod(
        id: 1,
        title: 'Active Payment',
        status: 1,
      );

      final inactivePayment = PaymentMethod(
        id: 2,
        title: 'Inactive Payment',
        status: 0,
      );

      // Assert
      expect(activePayment.isActive, true);
      expect(inactivePayment.isActive, false);
    });
  });
}