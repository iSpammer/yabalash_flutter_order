import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/orders/widgets/driver_info_widget.dart';
import '../theme/app_colors.dart';

// User detail widget matching React Native UserDetail component
class UserDetailWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type;
  final BoxDecoration? containerStyle;

  const UserDetailWidget({
    super.key,
    required this.data,
    required this.type,
    this.containerStyle,
  });

  @override
  Widget build(BuildContext context) {
    // For driver type, use the existing DriverInfoWidget
    if (type.toLowerCase() == 'driver') {
      return Container(
        decoration: containerStyle,
        child: DriverInfoWidget(
          order: null,
          vendor: null,
          driverData: data,
        ),
      );
    }

    // For vendor type
    return Container(
      decoration: containerStyle ??
          BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Vendor logo
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: data['logo'] ?? '',
              width: 50.w,
              height: 50.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.store,
                  color: Colors.grey[400],
                  size: 24.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          // Vendor details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Unknown Vendor',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (data['address'] != null)
                  Text(
                    data['address'],
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Call button if phone available
          if (data['phone'] != null)
            IconButton(
              icon: Icon(
                Icons.phone,
                color: AppColors.primaryColor,
              ),
              onPressed: () => _makePhoneCall(data['phone']),
            ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}