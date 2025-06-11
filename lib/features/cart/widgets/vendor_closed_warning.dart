import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/cart_model.dart';

class VendorClosedWarning extends StatelessWidget {
  final CartVendorItem vendorCart;
  final bool isPickupMode;

  const VendorClosedWarning({
    Key? key,
    required this.vendorCart,
    this.isPickupMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if vendor is closed
    final isVendorClosed = vendorCart.vendor?.isVendorClosed == 1 ||
        vendorCart.vendor?.isVendorClosed == true;

    final closedStoreOrderScheduled =
        vendorCart.vendor?.closedStoreOrderScheduled == 1;

    // Don't show warning if vendor is open
    if (!isVendorClosed) {
      return const SizedBox.shrink();
    }

    // Determine the message based on scheduling availability
    String message;
    IconData icon;
    Color color;

    if (closedStoreOrderScheduled) {
      message =
          'We are not accepting orders right now. You can schedule this order for later.';
      icon = Icons.schedule;
      color = Colors.orange;
    } else {
      message = 'Vendor is not accepting orders right now.';
      icon = Icons.store_mall_directory_outlined;
      color = Colors.red;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.red.shade700,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
