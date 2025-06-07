import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';

class OrderCardVendor extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onRepeatOrder;
  final VoidCallback? onReturnOrder;
  final VoidCallback? onReplaceOrder;
  final VoidCallback? onCancelOrder;
  final bool showRepeatOrderButton;
  final String? etaTime;
  final bool isDarkMode;

  const OrderCardVendor({
    super.key,
    required this.order,
    this.onTap,
    this.onRepeatOrder,
    this.onReturnOrder,
    this.onReplaceOrder,
    this.onCancelOrder,
    this.showRepeatOrderButton = false,
    this.etaTime,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showRepeatOrderButton) _buildRepeatOrderButton(),
            if (_shouldShowETA()) _buildETABanner(),
            _buildMainContent(),
            if (_shouldShowBottomActions()) _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatOrderButton() {
    return Container(
      padding: EdgeInsets.only(top: 10.h, right: 10.w),
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: onRepeatOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        child: Text(
          'REPEAT ORDER',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildETABanner() {
    final displayTime = etaTime ?? _getScheduledTime();
    if (displayTime == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      color: const Color(0xFF1E88E5),
      child: Text(
        'YOUR ORDER WILL ARRIVE BY $displayTime',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.all(8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVendorLogo(),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVendorName(),
                SizedBox(height: 4.h),
                _buildOrderInfo(),
                SizedBox(height: 8.h),
                _buildProductsList(),
                SizedBox(height: 8.h),
                _buildPaymentInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorLogo() {
    final logoUrl = order.vendor?.logo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.r),
      child: logoUrl != null
          ? CachedNetworkImage(
              imageUrl: logoUrl,
              width: 50.w,
              height: 50.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 50.w,
                height: 50.w,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => _buildDefaultLogo(),
            )
          : _buildDefaultLogo(),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.restaurant, size: 24.sp, color: Colors.grey[400]),
    );
  }

  Widget _buildVendorName() {
    return Text(
      order.vendor?.name ?? 'Unknown Restaurant',
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOrderInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Order ID: ${order.orderNumber ?? order.id}',
          style: TextStyle(
            fontSize: 12.sp,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        if (order.createdAt != null)
          Text(
            _formatOrderDate(order.createdAt!),
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildProductsList() {
    final totalItems = _getTotalItemsCount();
    final products = _getProducts();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Items: $totalItems',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        if (products.isNotEmpty) ...[
          SizedBox(height: 4.h),
          ...products.take(2).map((product) => Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  '${product.quantity}x ${product.productName}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
          if (products.length > 2)
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                '+${products.length - 2} more items',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              _getPaymentIcon(),
              size: 16.sp,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            SizedBox(width: 4.w),
            Text(
              _getPaymentMethodText(),
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        Text(
          'AED ${order.totalAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildStatusRow(),
          if (_shouldShowActionButtons()) ...[
            SizedBox(height: 8.h),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    final statusInfo = _getOrderStatusInfo();
    final isEdited = order.editRequestId != null;
    final hasTracking = _hasTrackingUrl();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Color(statusInfo['color']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                statusInfo['name'],
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(statusInfo['color']),
                ),
              ),
            ),
            if (hasTracking) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12.sp,
                      color: const Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isEdited) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Edited',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_canCancelOrder())
          TextButton(
            onPressed: onCancelOrder,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Cancel Order',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (order.isDelivered && onReturnOrder != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onReturnOrder,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                side: const BorderSide(color: Colors.grey),
              ),
              child: Text(
                'Return',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ),
        if (order.isDelivered && onReplaceOrder != null) ...[
          SizedBox(width: 8.w),
          Expanded(
            child: OutlinedButton(
              onPressed: onReplaceOrder,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                side: const BorderSide(color: Colors.grey),
              ),
              child: Text(
                'Replace',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _shouldShowETA() {
    return !order.isDelivered && 
           !order.isCancelled && 
           (etaTime != null || order.scheduledDateTime != null);
  }

  bool _shouldShowBottomActions() {
    return true; // Always show status row
  }

  bool _shouldShowActionButtons() {
    return order.isDelivered && (onReturnOrder != null || onReplaceOrder != null);
  }

  bool _canCancelOrder() {
    // Can cancel if order is pending or confirmed but not delivered/cancelled
    return onCancelOrder != null && 
           !order.isDelivered && 
           !order.isCancelled &&
           (order.statusId == 1 || order.statusId == 2);
  }

  String? _getScheduledTime() {
    if (order.scheduledDateTime == null) return null;
    try {
      final date = DateTime.parse(order.scheduledDateTime!);
      return DateFormat('MMM dd, HH:mm').format(date);
    } catch (e) {
      return null;
    }
  }

  int _getTotalItemsCount() {
    final products = _getProducts();
    return products.fold(0, (sum, product) => sum + product.quantity);
  }

  List<OrderProductModel> _getProducts() {
    // Get products from vendors array if available, otherwise from products array
    if (order.vendors?.isNotEmpty == true) {
      final vendor = order.vendors!.first;
      return vendor.products ?? [];
    }
    return order.products ?? [];
  }

  IconData _getPaymentIcon() {
    switch (order.paymentMethod?.toLowerCase()) {
      case '1':
      case 'cash':
      case 'cash_on_delivery':
        return Icons.money;
      case '2':
      case 'card':
        return Icons.credit_card;
      case '3':
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodText() {
    switch (order.paymentMethod?.toLowerCase()) {
      case '1':
      case 'cash':
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case '2':
      case 'card':
        return 'Card';
      case '3':
      case 'wallet':
        return 'Wallet';
      default:
        return order.paymentMethod ?? 'Unknown';
    }
  }

  Map<String, dynamic> _getOrderStatusInfo() {
    // Check if order has been edited
    if (order.editRequestId != null) {
      return {
        'name': 'Edited',
        'color': 0xFFFF9800,
      };
    }

    // Check for current status from order_status object
    final currentStatus = order.orderStatus?.currentStatus;
    if (currentStatus != null) {
      switch (currentStatus.id) {
        case 1:
          return {'name': 'Pending', 'color': 0xFFFF9800};
        case 2:
          return {'name': 'Accepted', 'color': 0xFF2196F3};
        case 3:
          return {'name': 'Processing', 'color': 0xFFFF5722};
        case 4:
          return {'name': 'Out for Delivery', 'color': 0xFF9C27B0};
        case 5:
          return {'name': 'Delivered', 'color': 0xFF4CAF50};
        case 6:
          return {'name': 'Cancelled', 'color': 0xFFF44336};
        case 7:
          return {'name': 'Rejected', 'color': 0xFFF44336};
        case 8:
          return {'name': 'Refunded', 'color': 0xFF607D8B};
      }
    }

    // Fallback to statusId
    switch (order.statusId) {
      case 1:
        return {'name': 'Pending', 'color': 0xFFFF9800};
      case 2:
        return {'name': 'Confirmed', 'color': 0xFF2196F3};
      case 3:
        return {'name': 'Cancelled', 'color': 0xFFF44336};
      case 4:
        return {'name': 'Preparing', 'color': 0xFFFF5722};
      case 5:
        return {'name': 'Ready', 'color': 0xFF9C27B0};
      case 6:
        return {'name': 'Delivered', 'color': 0xFF4CAF50};
      default:
        return {'name': 'Unknown', 'color': 0xFF9E9E9E};
    }
  }

  bool _hasTrackingUrl() {
    // Check if order has live tracking URL from vendors
    if (order.vendors?.isNotEmpty == true) {
      final vendor = order.vendors!.first;
      return vendor.dispatchTrakingUrl != null && 
             vendor.dispatchTrakingUrl!.isNotEmpty;
    }
    return false;
  }

  String _formatOrderDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} mins ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(date);
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }
}