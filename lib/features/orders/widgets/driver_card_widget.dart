import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/dispatch_tracking_service.dart';
import '../services/order_tracking_service.dart';

class DriverCardWidget extends StatelessWidget {
  final OrderTracking? orderTracking;
  final DriverLocationData? dispatchDriverData;

  const DriverCardWidget({
    super.key,
    this.orderTracking,
    this.dispatchDriverData,
  });

  @override
  Widget build(BuildContext context) {
    final driverInfo = orderTracking?.driverInfo;
    final driverName = dispatchDriverData?.driverName ?? driverInfo?.name ?? 'Your Driver';
    final driverPhoto = dispatchDriverData?.driverPhoto ?? driverInfo?.photo;
    final driverRating = dispatchDriverData?.driverRating ?? driverInfo?.rating;
    final profilePictureUrl = dispatchDriverData?.fullProfilePictureUrl ?? driverPhoto;

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
      child: Row(
        children: [
          // Driver Photo
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28.w,
              backgroundColor: Colors.grey[100],
              backgroundImage: profilePictureUrl != null ? NetworkImage(profilePictureUrl) : null,
              child: profilePictureUrl == null
                  ? Icon(Icons.person, size: 28.w, color: Colors.grey[400])
                  : null,
            ),
          ),
          SizedBox(width: 12.w),
          
          // Driver Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (driverRating != null)
                  SizedBox(height: 4.h),
                if (driverRating != null)
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < driverRating.round() ? Icons.star : Icons.star_border,
                          size: 12.w,
                          color: Colors.amber[700],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        driverRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Active Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}