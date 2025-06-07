import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? orderData;

  const OrderSuccessScreen({
    Key? key,
    this.orderData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Success Animation and Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30.r),
                      bottomRight: Radius.circular(30.r),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
                    child: Column(
                      children: [
                        // Success Icon with Animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 60.sp,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'Order Placed Successfully!',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Thank you for your order',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Order Details
                if (orderData != null) ...[
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      children: [
                        // Order Number Card
                        _buildInfoCard(context,
                          icon: Icons.receipt_long,
                          title: 'Order Number',
                          value: '#${orderData!['order_number'] ?? 'N/A'}',
                          color: Colors.blue,
                        ),
                        SizedBox(height: 16.h),

                        // Payment Info
                        _buildDetailCard(context,
                          title: 'Payment Details',
                          icon: Icons.payment,
                          children: [
                            _buildDetailRow(context, 'Subtotal', currencyFormat.format(
                              double.tryParse(orderData!['total_amount']?.toString() ?? '0') ?? 0
                            )),
                            if ((double.tryParse(orderData!['total_delivery_fee']?.toString() ?? '0') ?? 0) > 0)
                              _buildDetailRow(context, 'Delivery Fee', currencyFormat.format(
                                double.tryParse(orderData!['total_delivery_fee']?.toString() ?? '0') ?? 0
                              )),
                            if ((double.tryParse(orderData!['taxable_amount']?.toString() ?? '0') ?? 0) > 0)
                              _buildDetailRow(context, 'Tax', currencyFormat.format(
                                double.tryParse(orderData!['taxable_amount']?.toString() ?? '0') ?? 0
                              )),
                            if ((double.tryParse(orderData!['tip_amount']?.toString() ?? '0') ?? 0) > 0)
                              _buildDetailRow(context, 'Tip', currencyFormat.format(
                                double.tryParse(orderData!['tip_amount']?.toString() ?? '0') ?? 0
                              )),
                            if ((double.tryParse(orderData!['total_discount']?.toString() ?? '0') ?? 0) > 0)
                              _buildDetailRow(context, 'Discount', '- ${currencyFormat.format(
                                double.tryParse(orderData!['total_discount']?.toString() ?? '0') ?? 0
                              )}', isDiscount: true),
                            const Divider(),
                            _buildDetailRow(context,
                              'Total Amount',
                              currencyFormat.format(
                                double.tryParse(orderData!['payable_amount']?.toString() ?? '0') ?? 0
                              ),
                              isBold: true,
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // Vendor Information
                        if (orderData!['vendors'] != null && (orderData!['vendors'] as List).isNotEmpty) ...[
                          _buildVendorCard(context, orderData!['vendors'][0]),
                          SizedBox(height: 16.h),
                        ],

                        // Loyalty Points Card (if earned)
                        if ((double.tryParse(orderData!['loyalty_points_earned']?.toString() ?? '0') ?? 0) > 0)
                          _buildInfoCard(context,
                            icon: Icons.card_giftcard,
                            title: 'Loyalty Points Earned',
                            value: '${orderData!['loyalty_points_earned']} points',
                            color: Colors.purple,
                          ),
                        SizedBox(height: 16.h),

                        // Order Time
                        if (orderData!['created_at'] != null)
                          _buildInfoCard(context,
                            icon: Icons.access_time,
                            title: 'Order Placed At',
                            value: _formatDateTime(orderData!['created_at']),
                            color: Colors.orange,
                          ),
                        SizedBox(height: 16.h),

                        // Estimated Delivery Time
                        _buildInfoCard(context,
                          icon: Icons.delivery_dining,
                          title: 'Estimated Delivery',
                          value: '30-45 minutes',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      // Track Order Button
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: () {
                            if (orderData != null && orderData!['id'] != null) {
                              // For now, just go to orders list since we don't have tracking ID
                              context.go('/orders');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Track Order',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      
                      // View All Orders Button
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: OutlinedButton(
                          onPressed: () {
                            context.go('/orders');
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'View All Orders',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      
                      // Back to Home Button
                      TextButton(
                        onPressed: () {
                          context.go('/dashboard');
                        },
                        child: Text(
                          'Continue Shopping',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: Theme.of(context).primaryColor),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isBold = false, bool isDiscount = false}) {
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
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDiscount ? Colors.green : Colors.black87,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, Map<String, dynamic> vendorData) {
    final vendor = vendorData['vendor'] ?? {};
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, size: 20.sp, color: Theme.of(context).primaryColor),
              SizedBox(width: 8.w),
              Text(
                'Restaurant',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              if (vendor['logo'] != null && vendor['logo']['image_s3_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    vendor['logo']['image_s3_url'],
                    width: 50.w,
                    height: 50.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50.w,
                        height: 50.w,
                        color: Colors.grey[200],
                        child: Icon(Icons.store, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor['name'] ?? 'Restaurant',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (vendor['address'] != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        vendor['address'],
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (vendor['phone_no'] != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14.sp, color: Colors.grey[600]),
                          SizedBox(width: 4.w),
                          Text(
                            vendor['phone_no'],
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy at hh:mm a').format(dateTime.toLocal());
    } catch (e) {
      return dateTimeStr;
    }
  }
}