import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../models/order_model.dart';

class DriverInfoWidget extends StatelessWidget {
  final OrderModel? order;
  final OrderVendorDetailModel? vendor;
  final Map<String, dynamic>? driverData;
  final Map<String, dynamic>? agentLocation; // Real-time driver location

  const DriverInfoWidget({
    super.key,
    this.order,
    this.vendor,
    this.driverData,
    this.agentLocation,
  });

  @override
  Widget build(BuildContext context) {
    // For now, we'll use mock driver data since the API doesn't return driver details
    // In production, this would come from a separate driver API endpoint
    final mockDriverData = _getMockDriverData();

    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: AppColors.primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Delivery Executive',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              // Driver photo
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: mockDriverData['photo'] ?? '',
                  width: 60.w,
                  height: 60.w,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[400],
                      size: 30.sp,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[400],
                      size: 30.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mockDriverData['name'] ?? 'Driver Name',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          mockDriverData['rating'] ?? '4.5',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          mockDriverData['vehicle'] ?? 'Bike',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (mockDriverData['vehicleNumber'] != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        mockDriverData['vehicleNumber']!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Contact buttons
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.phone,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: () => _callDriver(mockDriverData['phone'] ?? ''),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.message,
                      color: Colors.green,
                    ),
                    onPressed: () =>
                        _messageDriver(mockDriverData['phone'] ?? ''),
                  ),
                ],
              ),
            ],
          ),
          // Driver status
          if (vendor?.vendorDispatcherStatus?.isNotEmpty == true ||
              agentLocation != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      _getCurrentDriverStatus(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Real-time location info (matching React Native agent_location display)
          if (agentLocation != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.withAlpha(51)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Driver is on the way • Last updated: ${_getLastUpdateTime()}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, String> _getMockDriverData() {
    // In production, this would come from the API
    // For now, using mock data to match React Native app
    return {
      'name': 'Ahmed Al Rashid',
      'photo': 'https://i.pravatar.cc/150?img=3',
      'rating': '4.8',
      'vehicle': 'Motorcycle',
      'vehicleNumber': 'DXB 1234',
      'phone': '+971501234567',
    };
  }

  String _getCurrentDriverStatus() {
    // First check if we have real-time agent status from the React Native tracking API
    if (agentLocation != null && agentLocation!.containsKey('driver_status')) {
      return agentLocation!['driver_status'];
    }

    if (vendor?.vendorDispatcherStatus?.isEmpty ?? true) {
      return agentLocation != null
          ? 'Driver is on the way'
          : 'Looking for driver...';
    }

    // Get the latest status
    final latestStatus = vendor!.vendorDispatcherStatus!.last;
    final statusData = latestStatus.statusData;

    if (statusData != null && statusData.driverStatus != null) {
      return statusData.driverStatus!;
    }

    debugPrint("====DISPATCHER DRIVER INFO======");
    debugPrint("${latestStatus.toJson()}");

    // Fallback based on dispatcher status ID (matching React Native logic)
    switch (latestStatus.dispatcherStatusOptionId) {
      case 1:
        return 'Order Accepted';
      case 2:
        return 'Driver Assigned';
      case 3:
        return latestStatus.type == '1'
            ? 'Heading to Restaurant'
            : 'Heading to You';
      case 4:
        return latestStatus.type == '1'
            ? 'Arrived at Restaurant'
            : 'Arrived at Your Location';
      case 5:
        return 'Order Picked Up';
      case 6:
        return 'Order Delivered';
      default:
        return 'In Progress';
    }
  }

  String _getLastUpdateTime() {
    if (agentLocation == null) return 'Unknown';

    // In React Native, this would show relative time like "2 mins ago"
    // For now, showing "Just now" since we're polling every 5 seconds
    return 'Just now';
  }

  void _callDriver(String phone) async {
    if (phone.isEmpty) return;

    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _messageDriver(String phone) async {
    if (phone.isEmpty) return;

    // Try WhatsApp first
    final whatsappUrl = Uri.parse('https://wa.me/${phone.replaceAll('+', '')}');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to SMS
      final Uri smsUrl = Uri(scheme: 'sms', path: phone);
      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
      }
    }
  }
}
