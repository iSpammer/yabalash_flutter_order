import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/custom_button.dart';
import '../../cart/providers/cart_provider.dart';
import '../../payment/models/place_order_model.dart';

class OrderSuccessScreen extends StatefulWidget {
  final OrderData? orderData;

  const OrderSuccessScreen({
    super.key,
    this.orderData,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();

    // Clear cart after successful order
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().clearCart();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h), // Add some top padding
                        // Success Animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 160.w,
                            height: 160.w,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 50.sp,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // Success Message
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Order Placed Successfully!',
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 16.h),

                                Text(
                                  'Thank you for your order. We\'ll start preparing it right away!',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 24.h),

                                // Order Number
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Order Number',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        widget.orderData?.orderNumber ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Order Details
                                if (widget.orderData != null) ...[
                                  SizedBox(height: 24.h),
                                  _buildOrderDetails(),
                                ],

                                // Loyalty Points Info
                                if (widget.orderData != null &&
                                    (widget.orderData!.loyaltyPointsUsed !=
                                            null ||
                                        widget.orderData!.loyaltyPointsEarned !=
                                            null ||
                                        widget.orderData!.loyaltyAmountSaved !=
                                            null)) ...[
                                  SizedBox(height: 16.h),
                                  _buildLoyaltyInfo(),
                                ],

                                SizedBox(height: 24.h),

                                // Delivery Info
                                Container(
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                        child: Icon(
                                          Icons.access_time,
                                          color: Colors.white,
                                          size: 20.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Estimated Delivery',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                            Text(
                                              '30-45 minutes',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: Colors.blue[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 100,
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Track Your Order',
                          onPressed: () {
                            context.pushReplacement('/orders');
                          },
                        ),
                        SizedBox(height: 16.h),
                        TextButton(
                          onPressed: () {
                            context.pushReplacement('/dashboard');
                          },
                          child: Text(
                            'Continue Shopping',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    final currencyFormat =
        NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    final orderData = widget.orderData!;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          _buildDetailRow(
              'Subtotal', currencyFormat.format(orderData.totalAmount ?? 0)),
          if (orderData.totalDiscount != null && orderData.totalDiscount! > 0)
            _buildDetailRow('Discount',
                '-${currencyFormat.format(orderData.totalDiscount)}',
                isDiscount: true),
          if (orderData.taxableAmount != null && orderData.taxableAmount! > 0)
            _buildDetailRow(
                'Tax', currencyFormat.format(orderData.taxableAmount)),
          if (orderData.totalDeliveryFee != null &&
              orderData.totalDeliveryFee! > 0)
            _buildDetailRow('Delivery Fee',
                currencyFormat.format(orderData.totalDeliveryFee)),
          Divider(height: 16.h, color: Colors.grey[300]),
          _buildDetailRow(
            'Total Paid',
            currencyFormat.format(orderData.payableAmount ?? 0),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyInfo() {
    final orderData = widget.orderData!;
    final pointsFormat = NumberFormat('#,##0.00');
    final currencyFormat =
        NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.purple[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars_rounded,
                color: Colors.purple[600],
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Loyalty Rewards',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (orderData.loyaltyPointsUsed != null &&
              orderData.loyaltyPointsUsed! > 0)
            _buildLoyaltyRow(
              'Points Used',
              '-${pointsFormat.format(orderData.loyaltyPointsUsed)} pts',
              Colors.red[600]!,
            ),
          if (orderData.loyaltyAmountSaved != null &&
              orderData.loyaltyAmountSaved! > 0)
            _buildLoyaltyRow(
              'Amount Saved',
              currencyFormat.format(orderData.loyaltyAmountSaved),
              Colors.green[600]!,
            ),
          if (orderData.loyaltyPointsEarned != null &&
              orderData.loyaltyPointsEarned! > 0)
            _buildLoyaltyRow(
              'Points Earned',
              '+${pointsFormat.format(orderData.loyaltyPointsEarned)} pts',
              Colors.green[600]!,
            ),
          if (orderData.loyaltyMembershipId != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Membership ID: ${orderData.loyaltyMembershipId}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.purple[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isDiscount = false, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDiscount
                  ? Colors.green[600]
                  : (isBold ? Colors.black87 : Colors.grey[800]),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyRow(String label, String value, Color valueColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.purple[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
