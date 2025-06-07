import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/restaurant_model.dart';

class RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const RestaurantCard({
    Key? key,
    required this.restaurant,
    this.onTap,
    this.isHorizontal = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isHorizontal ? _buildHorizontalCard() : _buildVerticalCard(),
      ),
    );
  }

  Widget _buildHorizontalCard() {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestaurantImage(width: 80.w, height: 80.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRestaurantName(),
                SizedBox(height: 4.h),
                _buildRestaurantInfo(),
                SizedBox(height: 8.h),
                _buildRestaurantMeta(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            _buildRestaurantImage(width: double.infinity, height: 120.h),
            _buildStatusBadge(),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRestaurantName(),
              SizedBox(height: 4.h),
              _buildRestaurantInfo(),
              SizedBox(height: 8.h),
              _buildRestaurantMeta(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantImage({required double width, required double height}) {
    // Debug: Print the image URL
    print('Restaurant ${restaurant.name}: image=${restaurant.image}');
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: CachedNetworkImage(
        imageUrl: restaurant.image ?? '',
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.restaurant,
            color: Colors.grey[400],
            size: 32.sp,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.restaurant,
            color: Colors.grey[400],
            size: 32.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (restaurant.isOpen == null) return const SizedBox.shrink();
    
    return Positioned(
      top: 8.h,
      left: 8.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: restaurant.isOpen! ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          restaurant.isOpen! ? 'Open' : 'Closed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantName() {
    return Text(
      restaurant.name ?? 'Restaurant',
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRestaurantInfo() {
    final cuisines = restaurant.cuisines?.take(2).join(', ') ?? '';
    return Text(
      cuisines.isNotEmpty ? cuisines : restaurant.description ?? '',
      style: TextStyle(
        fontSize: 13.sp,
        color: Colors.grey[600],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRestaurantMeta() {
    return Row(
      children: [
        if (restaurant.rating != null) ...[
          Icon(
            Icons.star,
            color: Colors.orange,
            size: 14.sp,
          ),
          SizedBox(width: 2.w),
          Text(
            restaurant.rating!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          if (restaurant.reviewCount != null) ...[
            Text(
              ' (${restaurant.reviewCount})',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
          SizedBox(width: 8.w),
        ],
        if (restaurant.formattedDistance != null) ...[
          Icon(
            Icons.location_on,
            color: Colors.grey[600],
            size: 14.sp,
          ),
          SizedBox(width: 2.w),
          Text(
            restaurant.formattedDistance!,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8.w),
        ],
        if (restaurant.formattedDeliveryTime != null) ...[
          Icon(
            Icons.access_time,
            color: Colors.grey[600],
            size: 14.sp,
          ),
          SizedBox(width: 2.w),
          Text(
            restaurant.formattedDeliveryTime!,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
        const Spacer(),
        if (restaurant.deliveryFee != null) ...[
          Text(
            '\$${restaurant.deliveryFee!.toStringAsFixed(2)} delivery',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}