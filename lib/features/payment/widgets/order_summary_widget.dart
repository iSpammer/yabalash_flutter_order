import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../cart/models/cart_model.dart';

class OrderSummaryWidget extends StatelessWidget {
  final CartModel cartData;
  final double? tipAmount;

  const OrderSummaryWidget({
    Key? key,
    required this.cartData,
    this.tipAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
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
          SizedBox(height: 12.h),
          
          // Items breakdown by vendor
          ...cartData.products.map((vendorCart) {
            // Calculate subtotal for vendor
            double vendorSubtotal = 0;
            for (var item in vendorCart.vendorProducts) {
              final itemPrice = item.variants?.quantityPrice ?? 
                               (item.product?.price ?? 0) * (item.quantity ?? 1);
              vendorSubtotal += itemPrice;
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vendorCart.vendor != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      vendorCart.vendor!.name ?? 'Restaurant',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                // Subtotal
                _buildSummaryRow(
                  'Subtotal',
                  currencyFormat.format(vendorSubtotal),
                ),
                
                // Discount
                if (vendorCart.discountAmount != null && vendorCart.discountAmount! > 0)
                  _buildSummaryRow(
                    'Discount',
                    '- ${currencyFormat.format(vendorCart.discountAmount)}',
                    isDiscount: true,
                  ),
                
                // Delivery charge
                if (vendorCart.deliverCharge != null && vendorCart.deliverCharge! > 0)
                  _buildSummaryRow(
                    'Delivery Fee',
                    currencyFormat.format(vendorCart.deliverCharge),
                  ),
                
                SizedBox(height: 8.h),
              ],
            );
          }),
          
          // Tip
          if (tipAmount != null && tipAmount! > 0)
            _buildSummaryRow(
              'Tip',
              currencyFormat.format(tipAmount),
            ),
          
          Divider(height: 16.h),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormat.format(cartData.totalPayableAmount ?? 0),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
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
      padding: EdgeInsets.symmetric(vertical: 4.h),
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