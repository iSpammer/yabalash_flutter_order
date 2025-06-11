import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/cart_model.dart';

class DeliverableSection extends StatelessWidget {
  final CartVendorItem vendorCart;
  final bool isPickupMode;

  const DeliverableSection({
    Key? key,
    required this.vendorCart,
    this.isPickupMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show delivery validation for pickup mode
    if (isPickupMode) {
      return const SizedBox.shrink();
    }

    // Check if vendor is deliverable
    if (vendorCart.isDeliverable == true || vendorCart.isDeliverable == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red[700],
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'The specific items are not deliverable to this address. Please remove the items or change the address.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemDeliverableWarning extends StatelessWidget {
  final bool isDeliverable;

  const ItemDeliverableWarning({
    Key? key,
    required this.isDeliverable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDeliverable) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Text(
        'This item is not deliverable to your selected address',
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}