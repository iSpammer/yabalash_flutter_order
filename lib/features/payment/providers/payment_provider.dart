import 'package:flutter/material.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/payment_method_model.dart';
import '../models/place_order_model.dart';
import '../services/payment_service.dart';
import '../../cart/providers/cart_provider.dart';
import '../../profile/providers/address_provider.dart';
import '../../dashboard/widgets/delivery_pickup_toggle.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final AuthProvider authProvider;
  final CartProvider cartProvider;
  final AddressProvider addressProvider;

  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = false;
  String? _errorMessage;

  // For card payments
  String? _cardNumber;
  String? _cardHolderName;
  String? _expiryMonth;
  String? _expiryYear;
  String? _cvv;

  // Order details
  String? _deliveryInstructions;
  String? _orderNote;

  PaymentProvider({
    required this.authProvider,
    required this.cartProvider,
    required this.addressProvider,
  });

  List<PaymentMethod> get paymentMethods => _paymentMethods;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get deliveryInstructions => _deliveryInstructions;
  String? get orderNote => _orderNote;

  // Card details getters
  String? get cardNumber => _cardNumber;
  String? get cardHolderName => _cardHolderName;
  String? get expiryMonth => _expiryMonth;
  String? get expiryYear => _expiryYear;
  String? get cvv => _cvv;

  void setDeliveryInstructions(String? instructions) {
    _deliveryInstructions = instructions;
    notifyListeners();
  }

  void setOrderNote(String? note) {
    _orderNote = note;
    notifyListeners();
  }

  void setCardDetails({
    String? cardNumber,
    String? cardHolderName,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
  }) {
    _cardNumber = cardNumber;
    _cardHolderName = cardHolderName;
    _expiryMonth = expiryMonth;
    _expiryYear = expiryYear;
    _cvv = cvv;
    notifyListeners();
  }

  void clearCardDetails() {
    _cardNumber = null;
    _cardHolderName = null;
    _expiryMonth = null;
    _expiryYear = null;
    _cvv = null;
    notifyListeners();
  }

  Future<void> loadPaymentMethods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final methods = await _paymentService.getPaymentMethods(
        authToken: authProvider.authToken!,
      );
      _paymentMethods = methods;

      // If a payment method was previously selected in cart, maintain that selection
      if (cartProvider.selectedPaymentMethodId != null) {
        _selectedPaymentMethod = _paymentMethods.firstWhere(
          (method) => method.id == cartProvider.selectedPaymentMethodId,
          orElse: () => _paymentMethods.first,
        );
      } else if (_paymentMethods.isNotEmpty) {
        // Default to first payment method
        _selectedPaymentMethod = _paymentMethods.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    // Update cart provider with selected payment method
    cartProvider.setSelectedPaymentMethod(method.id, method.title);
    notifyListeners();
  }

  Future<PlaceOrderResponse?> placeOrder({String? transactionId}) async {
    if (_selectedPaymentMethod == null) {
      _errorMessage = 'Please select a payment method';
      notifyListeners();
      return null;
    }

    // Only require address for delivery orders
    if (cartProvider.deliveryMode == DeliveryMode.delivery &&
        addressProvider.selectedAddress == null) {
      _errorMessage = 'Please select a delivery address';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // For takeaway orders, use a default address ID (0 or vendor's address ID)
      final addressId = cartProvider.deliveryMode == DeliveryMode.delivery
          ? (addressProvider.selectedAddress?.numericId ?? 0)
          : 0; // Use 0 for takeaway orders

      final request = PlaceOrderRequest(
        selectedAddressId: addressId,
        paymentOptionId: _selectedPaymentMethod!.id,
        paymentOptionCode: _selectedPaymentMethod!.code,
        tip: cartProvider.tipAmount,
        deliveryInstructions: _deliveryInstructions,
        orderNote: _orderNote,
        scheduleType: cartProvider.scheduleType,
        scheduledDateTime: cartProvider.scheduledDateTime,
        cardNumber: _cardNumber,
        cardHolderName: _cardHolderName,
        expiryMonth: _expiryMonth,
        expiryYear: _expiryYear,
        cvv: _cvv,
        transactionId: transactionId,
        orderType: cartProvider.deliveryMode == DeliveryMode.delivery
            ? 'delivery'
            : 'takeaway',
      );

      final response = await _paymentService.placeOrder(
        authToken: authProvider.authToken!,
        request: request,
      );

      // Clear card details after successful order
      if (response.isSuccess) {
        clearCardDetails();
      }

      return response;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generatePaymentUrl({
    required String paymentMethodKey,
    required double amount,
    required int paymentOptionId,
    required String orderNumber,
  }) async {
    try {
      return await _paymentService.generatePaymentUrl(
        authToken: authProvider.authToken!,
        paymentMethodKey: paymentMethodKey,
        amount: amount,
        paymentOptionId: paymentOptionId,
        orderNumber: orderNumber,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _selectedPaymentMethod = null;
    _deliveryInstructions = null;
    _orderNote = null;
    clearCardDetails();
    _errorMessage = null;
    notifyListeners();
  }
}
