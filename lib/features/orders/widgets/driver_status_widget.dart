import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/dispatch_tracking_service.dart';
import '../services/order_tracking_service.dart';

class DriverStatusWidget extends StatelessWidget {
  final OrderTracking? orderTracking;
  final DriverLocationData? dispatchDriverData;

  const DriverStatusWidget({
    super.key,
    this.orderTracking,
    this.dispatchDriverData,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = dispatchDriverData?.status ?? orderTracking?.statusText;
    
    if (statusText == null || statusText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withValues(alpha: 0.1),
            const Color(0xFF2196F3).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              _getStatusIcon(statusText),
              size: 20.sp,
              color: const Color(0xFF2196F3),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (dispatchDriverData?.updatedAt != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.update,
                    size: 12.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Just now',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('heading') || lowerStatus.contains('on the way')) {
      return Icons.directions_bike;
    } else if (lowerStatus.contains('arrived')) {
      return Icons.location_on;
    } else if (lowerStatus.contains('picked')) {
      return Icons.shopping_bag;
    } else if (lowerStatus.contains('delivered')) {
      return Icons.check_circle;
    } else {
      return Icons.local_shipping;
    }
  }
}