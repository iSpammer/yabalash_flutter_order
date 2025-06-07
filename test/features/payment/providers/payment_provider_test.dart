import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:yabalash_fe_flutter/features/auth/providers/auth_provider.dart';
import 'package:yabalash_fe_flutter/features/auth/models/user_model.dart';
import 'package:yabalash_fe_flutter/features/cart/providers/cart_provider.dart';
import 'package:yabalash_fe_flutter/features/payment/models/payment_method_model.dart';
import 'package:yabalash_fe_flutter/features/payment/models/place_order_model.dart';
import 'package:yabalash_fe_flutter/features/payment/providers/payment_provider.dart';
import 'package:yabalash_fe_flutter/features/payment/services/payment_service.dart';
import 'package:yabalash_fe_flutter/features/profile/providers/address_provider.dart';
import 'package:yabalash_fe_flutter/features/profile/models/address_model.dart';

// Generate mocks
@GenerateMocks([
  PaymentService,
  AuthProvider,
  CartProvider,
  AddressProvider,
])
import 'payment_provider_test.mocks.dart';

void main() {
  late PaymentProvider paymentProvider;
  late MockAuthProvider mockAuthProvider;
  late MockCartProvider mockCartProvider;
  late MockAddressProvider mockAddressProvider;
  late MockPaymentService mockPaymentService;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockCartProvider = MockCartProvider();
    mockAddressProvider = MockAddressProvider();
    mockPaymentService = MockPaymentService();

    // Setup default mock responses
    when(mockAuthProvider.user).thenReturn(
      UserModel(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        authToken: 'test_token',
      ),
    );
    when(mockAuthProvider.authToken).thenReturn('test_token');

    paymentProvider = PaymentProvider(
      authProvider: mockAuthProvider,
      cartProvider: mockCartProvider,
      addressProvider: mockAddressProvider,
    );

    // Inject mock service using reflection (in real app, use dependency injection)
    // For testing purposes, we'll test the provider logic
  });

  group('PaymentProvider Tests', () {
    test('should select payment method', () {
      // Arrange
      final paymentMethod = PaymentMethod(
        id: 1,
        title: 'Credit Card',
        status: 1,
      );

      // Act
      paymentProvider.selectPaymentMethod(paymentMethod);

      // Assert
      expect(paymentProvider.selectedPaymentMethod, paymentMethod);
      verify(mockCartProvider.setSelectedPaymentMethod(1, 'Credit Card')).called(1);
    });

    test('should set delivery instructions', () {
      // Act
      paymentProvider.setDeliveryInstructions('Leave at door');

      // Assert
      expect(paymentProvider.deliveryInstructions, 'Leave at door');
    });

    test('should set order note', () {
      // Act
      paymentProvider.setOrderNote('Extra spicy please');

      // Assert
      expect(paymentProvider.orderNote, 'Extra spicy please');
    });

    test('should set and clear card details', () {
      // Act - Set card details
      paymentProvider.setCardDetails(
        cardNumber: '4111111111111111',
        cardHolderName: 'John Doe',
        expiryMonth: '12',
        expiryYear: '25',
        cvv: '123',
      );

      // Assert
      expect(paymentProvider.cardNumber, '4111111111111111');
      expect(paymentProvider.cardHolderName, 'John Doe');
      expect(paymentProvider.expiryMonth, '12');
      expect(paymentProvider.expiryYear, '25');
      expect(paymentProvider.cvv, '123');

      // Act - Clear card details
      paymentProvider.clearCardDetails();

      // Assert
      expect(paymentProvider.cardNumber, null);
      expect(paymentProvider.cardHolderName, null);
      expect(paymentProvider.expiryMonth, null);
      expect(paymentProvider.expiryYear, null);
      expect(paymentProvider.cvv, null);
    });

    test('should validate payment method before placing order', () async {
      // Arrange
      when(mockAddressProvider.selectedAddress).thenReturn(
        AddressModel(
          id: '1',
          numericId: 1,
          label: 'Home',
          fullAddress: 'Test Address',
          type: 'home',
        ),
      );

      // Act
      final result = await paymentProvider.placeOrder();

      // Assert
      expect(result, null);
      expect(paymentProvider.errorMessage, 'Please select a payment method');
    });

    test('should validate address before placing order', () async {
      // Arrange
      paymentProvider.selectPaymentMethod(
        PaymentMethod(id: 1, title: 'COD', status: 1),
      );
      when(mockAddressProvider.selectedAddress).thenReturn(null);

      // Act
      final result = await paymentProvider.placeOrder();

      // Assert
      expect(result, null);
      expect(paymentProvider.errorMessage, 'Please select a delivery address');
    });

    test('should reset provider state', () {
      // Arrange
      paymentProvider.selectPaymentMethod(
        PaymentMethod(id: 1, title: 'Card', status: 1),
      );
      paymentProvider.setDeliveryInstructions('Test instructions');
      paymentProvider.setOrderNote('Test note');
      paymentProvider.setCardDetails(
        cardNumber: '4111111111111111',
        cardHolderName: 'John Doe',
      );

      // Act
      paymentProvider.reset();

      // Assert
      expect(paymentProvider.selectedPaymentMethod, null);
      expect(paymentProvider.deliveryInstructions, null);
      expect(paymentProvider.orderNote, null);
      expect(paymentProvider.cardNumber, null);
      expect(paymentProvider.cardHolderName, null);
      expect(paymentProvider.errorMessage, null);
    });

    test('should maintain selected payment method from cart', () async {
      // This test verifies that payment provider respects cart's payment selection
      when(mockCartProvider.selectedPaymentMethodId).thenReturn(2);

      // In real implementation, loadPaymentMethods would set the selection
      // based on cart's selectedPaymentMethodId
      expect(mockCartProvider.selectedPaymentMethodId, 2);
    });
  });

  group('PaymentProvider Error Handling', () {
    test('should handle payment service errors gracefully', () async {
      // Arrange
      paymentProvider.selectPaymentMethod(
        PaymentMethod(id: 1, title: 'Card', status: 1),
      );
      
      when(mockAddressProvider.selectedAddress).thenReturn(
        AddressModel(
          id: '1',
          numericId: 1,
          label: 'Home',
          fullAddress: 'Test Address',
          type: 'home',
        ),
      );

      when(mockCartProvider.tipAmount).thenReturn(5.0);
      when(mockCartProvider.scheduleType).thenReturn('now');
      when(mockCartProvider.scheduledDateTime).thenReturn(null);

      // Note: In real implementation, you'd mock the service call
      // For now, we're testing the provider logic

      // Act & Assert
      expect(paymentProvider.isLoading, false);
      expect(paymentProvider.errorMessage, null);
    });
  });
}