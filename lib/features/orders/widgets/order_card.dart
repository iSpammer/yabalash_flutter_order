import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(),
              SizedBox(height: 12.h),
              _buildVendorInfo(),
              SizedBox(height: 12.h),
              _buildOrderItems(),
              SizedBox(height: 12.h),
              _buildOrderFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    final statusInfo = _getOrderStatusInfo();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Order #${order.id}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 6.h,
          ),
          decoration: BoxDecoration(
            color: Color(statusInfo['color']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconData(statusInfo['icon']),
                size: 14.sp,
                color: Color(statusInfo['color']),
              ),
              SizedBox(width: 4.w),
              Text(
                statusInfo['name'],
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(statusInfo['color']),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorInfo() {
    return Row(
      children: [
        if (order.vendor?.logo != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: order.vendor!.logo!,
              width: 32.w,
              height: 32.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 32.w,
                height: 32.w,
                color: Colors.grey[200],
                child: Icon(Icons.restaurant, size: 16.sp),
              ),
              errorWidget: (context, url, error) => Container(
                width: 32.w,
                height: 32.w,
                color: Colors.grey[200],
                child: Icon(Icons.restaurant, size: 16.sp),
              ),
            ),
          )
        else
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.restaurant, size: 16.sp),
          ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.vendor?.name ?? 'Unknown Restaurant',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              if (order.createdAt != null)
                Text(
                  _formatOrderDate(order.createdAt!),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    if (order.products == null || order.products!.isEmpty) {
      return Text(
        'No items',
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      );
    }

    final displayProducts = order.products!.take(2).toList();
    final remainingCount = order.products!.length - displayProducts.length;

    return Column(
      children: [
        ...displayProducts.map((product) => _buildProductItem(product)),
        if (remainingCount > 0)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              '+$remainingCount more item${remainingCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductItem(OrderProductModel product) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Center(
              child: Text(
                '${product.quantity}',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              product.productName ?? 'Unknown Item',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'AED ${product.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total: AED ${order.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E88E5),
          ),
        ),
        if (order.isActive)
          Text(
            'Tap to track',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          )
        else if (order.isDelivered)
          Text(
            'Tap to reorder',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF1E88E5),
            ),
          ),
      ],
    );
  }

  Map<String, dynamic> _getOrderStatusInfo() {
    switch (order.statusId) {
      case 1:
        return {
          'name': 'Pending',
          'color': 0xFFFF9800,
          'icon': 'schedule',
        };
      case 2:
        return {
          'name': 'Confirmed',
          'color': 0xFF2196F3,
          'icon': 'check_circle',
        };
      case 3:
        return {
          'name': 'Cancelled',
          'color': 0xFFF44336,
          'icon': 'cancel',
        };
      case 4:
        return {
          'name': 'Preparing',
          'color': 0xFFFF5722,
          'icon': 'restaurant',
        };
      case 5:
        return {
          'name': 'Ready',
          'color': 0xFF9C27B0,
          'icon': 'done_all',
        };
      case 6:
        return {
          'name': 'Delivered',
          'color': 0xFF4CAF50,
          'icon': 'verified',
        };
      default:
        return {
          'name': 'Unknown',
          'color': 0xFF9E9E9E,
          'icon': 'help',
        };
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'schedule':
        return Icons.schedule;
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      case 'restaurant':
        return Icons.restaurant;
      case 'done_all':
        return Icons.done_all;
      case 'verified':
        return Icons.verified;
      case 'help':
      default:
        return Icons.help;
    }
  }

  String _formatOrderDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(date);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(date);
      } else {
        return DateFormat('MMM dd').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }
}