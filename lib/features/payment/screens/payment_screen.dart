import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../profile/providers/address_provider.dart';
import '../providers/payment_provider.dart';
import '../models/payment_method_model.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/order_summary_widget.dart';
import '../widgets/card_input_widget.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_isInitialized) {
      _isInitialized = true;
      final paymentProvider = context.read<PaymentProvider>();
      await paymentProvider.loadPaymentMethods();
    }
  }

  Future<void> _handlePlaceOrder() async {
    final paymentProvider = context.read<PaymentProvider>();
    final cartProvider = context.read<CartProvider>();
    
    // Check if cart data is null
    if (cartProvider.cartData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Please add items to proceed.'),
          backgroundColor: Colors.orange,
        ),
      );
      context.go('/dashboard');
      return;
    }
    
    // Set delivery instructions and order note
    paymentProvider.setDeliveryInstructions(_instructionsController.text);
    paymentProvider.setOrderNote(_noteController.text);
    
    // Validate payment method
    if (paymentProvider.selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }
    
    // For card payments, validate card details
    if (paymentProvider.selectedPaymentMethod!.isCard && 
        !paymentProvider.selectedPaymentMethod!.isOffSite) {
      if (paymentProvider.cardNumber == null || 
          paymentProvider.cardHolderName == null ||
          paymentProvider.expiryMonth == null ||
          paymentProvider.expiryYear == null ||
          paymentProvider.cvv == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all card details')),
        );
        return;
      }
    }
    
    // Check if this is an online payment method
    final isOnlinePayment = paymentProvider.selectedPaymentMethod!.isOffSite;
    
    if (isOnlinePayment) {
      // For online payments, generate payment URL first
      final orderNumber = DateTime.now().millisecondsSinceEpoch.toString();
      final totalAmount = cartProvider.cartData?.totalPayableAmount ?? 0;
      
      final paymentUrl = await paymentProvider.generatePaymentUrl(
        paymentMethodKey: paymentProvider.selectedPaymentMethod!.code!,
        amount: totalAmount,
        paymentOptionId: paymentProvider.selectedPaymentMethod!.id,
        orderNumber: orderNumber,
      );
      
      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        if (!mounted) return;
        
        // Navigate to webview for payment
        final result = await context.push('/payment/webview', extra: {
          'paymentUrl': paymentUrl,
          'orderNumber': orderNumber,
          'paymentMethod': paymentProvider.selectedPaymentMethod!.code,
        });
        
        // If payment was successful, place the order with transaction ID
        if (result != null && result is Map<String, dynamic> && result['success'] == true) {
          final response = await paymentProvider.placeOrder(transactionId: orderNumber);
          
          if (response != null && response.isSuccess) {
            // Store order data before clearing cart
            final orderData = response.data?.toJson();
            
            if (!mounted) return;
            
            // Navigate to order success first
            context.go('/order/success', extra: {
              'orderData': orderData,
            });
            
            // Clear cart and reset payment provider after navigation
            // This prevents the "cart empty" screen from showing
            Future.delayed(const Duration(milliseconds: 500), () {
              cartProvider.clearCart();
              paymentProvider.reset();
            });
          } else {
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(paymentProvider.errorMessage ?? 'Failed to complete order after payment'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Payment was cancelled or failed
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment was cancelled or failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (!mounted) return;
        
        final errorMsg = paymentProvider.errorMessage ?? 'Failed to generate payment URL';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      // For cash on delivery or on-site card payments, place order directly
      final response = await paymentProvider.placeOrder();
      
      if (response != null && response.isSuccess) {
        // Store order data before clearing cart
        final orderData = response.data?.toJson();
        
        if (!mounted) return;
        
        // Navigate to order success first
        context.go('/order/success', extra: {
          'orderData': orderData,
        });
        
        // Clear cart and reset payment provider after navigation
        // This prevents the "cart empty" screen from showing
        Future.delayed(const Duration(milliseconds: 500), () {
          cartProvider.clearCart();
          paymentProvider.reset();
        });
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.errorMessage ?? 'Failed to place order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
      ),
      body: Consumer3<PaymentProvider, CartProvider, AddressProvider>(
        builder: (context, paymentProvider, cartProvider, addressProvider, _) {
          if (paymentProvider.isLoading && !_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if cart is empty or null
          if (cartProvider.cartData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Add items to your cart to proceed with payment',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    text: 'Go to Dashboard',
                    onPressed: () => context.go('/dashboard'),
                  ),
                ],
              ),
            );
          }

          if (paymentProvider.errorMessage != null && paymentProvider.paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    paymentProvider.errorMessage!,
                    style: TextStyle(fontSize: 16.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  CustomButton(
                    text: 'Retry',
                    onPressed: _loadData,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Delivery Address
                      _buildDeliveryAddress(addressProvider),
                      SizedBox(height: 24.h),

                      // Order Summary
                      if (cartProvider.cartData != null) ...[  
                        OrderSummaryWidget(
                          cartData: cartProvider.cartData!,
                          tipAmount: cartProvider.tipAmount,
                        ),
                        SizedBox(height: 24.h),
                      ],

                      // Delivery Instructions
                      Text(
                        'Delivery Instructions',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      CustomTextField(
                        controller: _instructionsController,
                        hintText: 'Add delivery instructions (optional)',
                        maxLines: 3,
                      ),
                      SizedBox(height: 16.h),

                      // Order Note
                      Text(
                        'Order Note',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      CustomTextField(
                        controller: _noteController,
                        hintText: 'Add note for restaurant (optional)',
                        maxLines: 2,
                      ),
                      SizedBox(height: 24.h),

                      // Payment Methods
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ...paymentProvider.paymentMethods.map((method) {
                        return PaymentMethodCard(
                          paymentMethod: method,
                          isSelected: paymentProvider.selectedPaymentMethod?.id == method.id,
                          onTap: () => paymentProvider.selectPaymentMethod(method),
                        );
                      }),

                      // Card Input (if card payment selected)
                      if (paymentProvider.selectedPaymentMethod != null &&
                          paymentProvider.selectedPaymentMethod!.isCard &&
                          !paymentProvider.selectedPaymentMethod!.isOffSite)
                        Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: CardInputWidget(
                            onCardDetailsChanged: (details) {
                              paymentProvider.setCardDetails(
                                cardNumber: details['cardNumber'],
                                cardHolderName: details['cardHolderName'],
                                expiryMonth: details['expiryMonth'],
                                expiryYear: details['expiryYear'],
                                cvv: details['cvv'],
                              );
                            },
                          ),
                        ),

                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),

              // Bottom Place Order Button
              _buildPlaceOrderButton(paymentProvider, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeliveryAddress(AddressProvider addressProvider) {
    final address = addressProvider.selectedAddress;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).primaryColor,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  address?.fullAddress ?? 'No address selected',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(PaymentProvider paymentProvider, CartProvider cartProvider) {
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    final totalAmount = cartProvider.cartData?.totalPayableAmount ?? 0;
    
    // If cart data is null, don't show the place order button
    if (cartProvider.cartData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currencyFormat.format(totalAmount),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomButton(
                text: paymentProvider.selectedPaymentMethod?.isCashOnDelivery == true
                    ? 'Place Order'
                    : 'Pay & Place Order',
                onPressed: paymentProvider.isLoading ? null : _handlePlaceOrder,
                isLoading: paymentProvider.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}