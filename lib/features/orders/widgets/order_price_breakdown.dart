import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/order_model.dart';

class OrderPriceBreakdown extends StatelessWidget {
  final OrderModel order;

  const OrderPriceBreakdown({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.attach_money,
                  size: 20.sp,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Price Breakdown',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Subtotal
          if (order.subtotalAmount != null)
            _buildPriceRow('Subtotal', order.subtotalAmount!),
          
          // Delivery Fee
          if (order.totalDeliveryFee != null && order.totalDeliveryFee! > 0)
            _buildPriceRow('Delivery Fee', order.totalDeliveryFee!),
          
          // Service Fee
          if (order.totalServiceFee != null && order.totalServiceFee! > 0)
            _buildPriceRow('Service Fee', order.totalServiceFee!),
          
          // Tax
          if (order.taxableAmount != null && order.taxableAmount! > 0)
            _buildPriceRow('Tax', order.taxableAmount!),
          
          // Discount
          if (order.discountAmount != null && order.discountAmount! > 0)
            _buildPriceRow(
              'Discount',
              -order.discountAmount!,
              isDiscount: true,
            ),
          
          // Coupon Discount
          if (order.couponDiscount != null && order.couponDiscount! > 0)
            _buildPriceRow(
              'Coupon (${order.couponCode ?? 'Applied'})',
              -order.couponDiscount!,
              isDiscount: true,
            ),
          
          // Loyalty Points
          if (order.loyaltyAmountSaved != null && order.loyaltyAmountSaved! > 0)
            _buildPriceRow(
              'Loyalty Points',
              -order.loyaltyAmountSaved!,
              isDiscount: true,
            ),
          
          // Tip
          if (order.tipAmount != null && order.tipAmount! > 0)
            _buildPriceRow('Tip', order.tipAmount!),
          
          // Divider
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
          ),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _formatCurrency(order.totalAmount),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isDiscount)
                Icon(
                  Icons.discount,
                  size: 14.sp,
                  color: Colors.green[600],
                ),
              if (isDiscount) SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDiscount ? Colors.green[700] : Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 14.sp,
              color: isDiscount ? Colors.green[700] : Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    return '${isNegative ? '-' : ''}\$${absAmount.toStringAsFixed(2)}';
  }
}