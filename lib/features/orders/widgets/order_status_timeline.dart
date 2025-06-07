import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/order_model.dart';

class OrderStatusTimeline extends StatefulWidget {
  final List<DispatcherStatusModel> statuses;
  final List<OrderStatusHistoryModel>? allStatus;

  const OrderStatusTimeline({
    super.key,
    required this.statuses,
    this.allStatus,
  });

  @override
  State<OrderStatusTimeline> createState() => _OrderStatusTimelineState();
}

class _OrderStatusTimelineState extends State<OrderStatusTimeline> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Order Updates',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            SizedBox(height: 16.h),
            ...widget.statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isLast = index == widget.statuses.length - 1;
              
              return _buildTimelineItem(status, isLast);
            }),
            
            // Show order status history if available
            if (widget.allStatus != null && widget.allStatus!.isNotEmpty) ...[
              Divider(height: 24.h),
              Text(
                'Order Status History',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12.h),
              ...widget.allStatus!.map((status) => _buildOrderStatusItem(status)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(DispatcherStatusModel status, bool isLast) {
    final statusText = status.statusData?.driverStatus ?? _getStatusText(status);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 40.h,
                color: AppColors.primaryColor.withAlpha(102), // 0.4 * 255
              ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _getRelativeTime(status),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (status.type == '1')
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Store',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else if (status.type == '2')
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Delivery',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderStatusItem(OrderStatusHistoryModel status) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status.status?.currentStatus?.title),
            size: 16.sp,
            color: _getStatusColor(status.status?.currentStatus?.title),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              status.status?.currentStatus?.title ?? 'Unknown',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            DateFormat('h:mm a').format(
              DateTime.parse(status.createdAt ?? DateTime.now().toString()),
            ),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(DispatcherStatusModel status) {
    switch (status.dispatcherStatusOptionId) {
      case 1:
        return 'Order Accepted';
      case 2:
        return 'Delivery Executive Assigned';
      case 3:
        return status.type == '1' 
            ? 'Executive heading to store' 
            : 'Executive heading to you';
      case 4:
        return status.type == '1'
            ? 'Executive arrived at store'
            : 'Executive arrived at your location';
      case 5:
        return 'Order picked up';
      case 6:
        return 'Order delivered';
      default:
        return 'Order in progress';
    }
  }

  String _getRelativeTime(DispatcherStatusModel status) {
    // In production, you would use the actual timestamp from the status
    // For now, using a simple "X minutes ago" format
    return '${(status.dispatcherStatusOptionId * 5)} minutes ago';
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'placed':
        return Icons.shopping_bag_outlined;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.restaurant;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.radio_button_checked;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'processing':
      case 'accepted':
        return Colors.orange;
      default:
        return AppColors.primaryColor;
    }
  }
}