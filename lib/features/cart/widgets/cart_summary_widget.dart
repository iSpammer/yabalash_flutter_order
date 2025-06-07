import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/cart_model.dart';

class CartSummaryWidget extends StatelessWidget {
  final CartModel cartData;
  final double? tipAmount;

  const CartSummaryWidget({
    Key? key,
    required this.cartData,
    this.tipAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    final finalAmount = (cartData.totalPayableAmount ?? 0) + (tipAmount ?? 0);

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          // Subtotal
          _buildSummaryRow(
            'Subtotal',
            currencyFormat.format(cartData.grossPayableAmount ?? 0),
          ),

          // Discount
          if (cartData.totalDiscount != null && cartData.totalDiscount! > 0)
            _buildSummaryRow(
              'Discount',
              '- ${currencyFormat.format(cartData.totalDiscount)}',
              isDiscount: true,
            ),

          // Delivery fee
          if (cartData.totalDeliveryFee != null && cartData.totalDeliveryFee! > 0)
            _buildSummaryRow(
              'Delivery Fee',
              currencyFormat.format(cartData.totalDeliveryFee),
            ),

          // Wallet amount
          if (cartData.walletAmountUsed != null && cartData.walletAmountUsed! > 0)
            _buildSummaryRow(
              'Wallet',
              '- ${currencyFormat.format(cartData.walletAmountUsed)}',
              isDiscount: true,
            ),

          // Loyalty amount
          if (cartData.loyaltyAmountUsed != null && cartData.loyaltyAmountUsed! > 0)
            _buildSummaryRow(
              'Loyalty',
              '- ${currencyFormat.format(cartData.loyaltyAmountUsed)}',
              isDiscount: true,
            ),

          // Subscription discount
          if (cartData.totalSubscriptionDiscount != null && 
              cartData.totalSubscriptionDiscount! > 0)
            _buildSummaryRow(
              'Subscription Discount',
              '- ${currencyFormat.format(cartData.totalSubscriptionDiscount)}',
              isDiscount: true,
            ),

          // Tax
          if (cartData.totalTax != null && cartData.totalTax! > 0)
            _buildSummaryRow(
              'Tax',
              currencyFormat.format(cartData.totalTax),
            ),

          // Tip
          if (tipAmount != null && tipAmount! > 0)
            _buildSummaryRow(
              'Tip',
              currencyFormat.format(tipAmount),
            ),

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currencyFormat.format(finalAmount),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDiscount ? Colors.green : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDiscount ? Colors.green : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}