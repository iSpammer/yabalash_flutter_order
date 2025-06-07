import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/dispatch_tracking_service.dart';
import '../services/order_tracking_service.dart';

class DriverDeliveryDetails extends StatelessWidget {
  final OrderTracking? orderTracking;
  final DriverLocationData? dispatchDriverData;

  const DriverDeliveryDetails({
    super.key,
    this.orderTracking,
    this.dispatchDriverData,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we have any delivery details to show
    bool hasDetails = (orderTracking?.estimatedTime != null || dispatchDriverData?.eta != null) ||
        dispatchDriverData?.vehicleTypeId != null ||
        dispatchDriverData?.actualDistance != null ||
        dispatchDriverData?.distanceFee != null ||
        dispatchDriverData?.basePrice != null;

    if (!hasDetails) {
      return const SizedBox.shrink();
    }

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
              Icon(
                Icons.local_shipping,
                size: 18.sp,
                color: const Color(0xFF2196F3),
              ),
              SizedBox(width: 8.w),
              Text(
                'Delivery Information',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Info Grid
          Wrap(
            spacing: 16.w,
            runSpacing: 12.h,
            children: [
              if (orderTracking?.estimatedTime != null || dispatchDriverData?.eta != null)
                _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: dispatchDriverData?.eta ?? orderTracking?.estimatedTime ?? '',
                  color: const Color(0xFF2196F3),
                ),
              if (dispatchDriverData?.vehicleTypeId != null)
                _buildInfoItem(
                  icon: Icons.two_wheeler,
                  label: 'Vehicle',
                  value: _getVehicleType(dispatchDriverData!.vehicleTypeId!),
                  color: Colors.orange,
                ),
              if (dispatchDriverData?.actualDistance != null)
                _buildInfoItem(
                  icon: Icons.route,
                  label: 'Distance',
                  value: '${dispatchDriverData!.actualDistance!.toStringAsFixed(1)} km',
                  color: Colors.green,
                ),
              if (dispatchDriverData?.deviceType != null)
                _buildInfoItem(
                  icon: dispatchDriverData!.deviceType!.toLowerCase().contains('ios') 
                      ? Icons.phone_iphone 
                      : Icons.phone_android,
                  label: 'Device',
                  value: dispatchDriverData!.deviceType!,
                  color: Colors.purple,
                ),
            ],
          ),
          
          // Pricing Details
          if (dispatchDriverData?.basePrice != null || dispatchDriverData?.distanceFee != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  if (dispatchDriverData?.basePrice != null)
                    _buildPriceRow('Base Fare', dispatchDriverData!.basePrice!),
                  if (dispatchDriverData?.distanceFee != null) ...[
                    SizedBox(height: 8.h),
                    _buildPriceRow('Distance Fee', dispatchDriverData!.distanceFee!),
                  ],
                  if (dispatchDriverData?.basePrice != null && dispatchDriverData?.distanceFee != null) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Divider(color: Colors.grey[300]),
                    ),
                    _buildPriceRow(
                      'Total Delivery',
                      (dispatchDriverData!.basePrice! + dispatchDriverData!.distanceFee!),
                      isTotal: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14.sp : 13.sp,
            color: isTotal ? Colors.black87 : Colors.grey[700],
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 14.sp : 13.sp,
            color: isTotal ? Colors.black87 : Colors.grey[700],
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _getVehicleType(int vehicleTypeId) {
    switch (vehicleTypeId) {
      case 1:
        return 'Bike';
      case 2:
        return 'Car';
      case 3:
        return 'Van';
      default:
        return 'Vehicle';
    }
  }

}