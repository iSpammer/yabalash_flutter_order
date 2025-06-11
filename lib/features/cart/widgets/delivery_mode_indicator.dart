import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/delivery_pickup_toggle.dart';

class DeliveryModeIndicator extends StatelessWidget {
  final DeliveryMode currentMode;

  const DeliveryModeIndicator({
    Key? key,
    required this.currentMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            currentMode == DeliveryMode.delivery
                ? Icons.delivery_dining
                : Icons.store,
            color: Colors.grey[600],
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            currentMode == DeliveryMode.delivery ? 'Delivery' : 'Takeaway',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'Mode',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
