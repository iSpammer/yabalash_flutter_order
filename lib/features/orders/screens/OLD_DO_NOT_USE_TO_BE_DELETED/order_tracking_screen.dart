import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../../../core/widgets/custom_button.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    // Set up auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadOrderDetails(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadOrderDetails({bool showLoading = true}) {
    final orderProvider = context.read<OrderProvider>();
    final orderIdInt = int.tryParse(widget.orderId);
    
    if (orderIdInt != null) {
      // First try to find from cached orders to get correct IDs
      final cachedOrder = orderProvider.findOrderById(orderIdInt);
      if (cachedOrder != null) {
        final actualOrderId = cachedOrder.orderId ?? orderIdInt;
        final vendorId = cachedOrder.vendorId;
        
        orderProvider.loadOrderDetails(
          orderId: actualOrderId,
          vendorId: vendorId,
          showLoading: showLoading,
        );
      } else {
        // Fallback to direct load
        orderProvider.loadOrderDetails(orderId: orderIdInt, showLoading: showLoading);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Track Order',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => _loadOrderDetails(),
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoadingOrderDetails) {
            return _buildLoadingView();
          }

          if (orderProvider.orderDetailsError != null) {
            return _buildErrorView(orderProvider.orderDetailsError!);
          }

          final order = orderProvider.currentOrderDetails;
          if (order == null) {
            return _buildNotFoundView();
          }

          return _buildTrackingContent(order);
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            'Loading tracking info...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'Unable to track order',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Try Again',
              onPressed: () => _loadOrderDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'Order Not Found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'The requested order could not be found.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Go Back',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent(OrderModel order) {
    // Get the first vendor's tracking details
    final vendorDetail = order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    
    return RefreshIndicator(
      onRefresh: () async => _loadOrderDetails(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(order),
            SizedBox(height: 24.h),
            if (vendorDetail != null) ...[
              _buildTrackingProgress(vendorDetail),
              SizedBox(height: 24.h),
              _buildMapTrackingCard(order),
              SizedBox(height: 16.h),
              if (vendorDetail.dispatchTrakingUrl != null)
                _buildExternalTrackingCard(vendorDetail.dispatchTrakingUrl!),
            ],
            _buildDeliveryDetails(order),
            SizedBox(height: 16.h),
            _buildRestaurantInfo(order),
            SizedBox(height: 16.h),
            _buildOrderItems(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ${order.orderNumber ?? '#${order.id}'}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Total: AED ${order.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingProgress(OrderVendorDetailModel vendorDetail) {
    final currentStatus = vendorDetail.dispatcherStatusOptionId ?? 1;
    final statusIcons = vendorDetail.dispatcherStatusIcons ?? [];
    final statusCount = vendorDetail.vendorDispatcherStatusCount;
    
    // Ensure status is within valid range
    final validStatus = currentStatus.clamp(1, statusCount);
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Progress',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20.h),
          _buildStepIndicator(validStatus, statusCount, statusIcons),
          SizedBox(height: 16.h),
          if (vendorDetail.vendorDispatcherStatus?.isNotEmpty == true)
            Text(
              vendorDetail.vendorDispatcherStatus!.last.statusData?.driverStatus ?? 
              _getStatusMessage(validStatus),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int currentStatus, int totalSteps, List<String> icons) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              // This is a line between steps
              final stepIndex = index ~/ 2;
              final isCompleted = currentStatus > stepIndex + 1;
              return Expanded(
                child: Container(
                  height: 2.h,
                  color: isCompleted 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[300],
                ),
              );
            } else {
              // This is a step
              final stepIndex = index ~/ 2;
              final isCompleted = currentStatus > stepIndex + 1;
              final isActive = currentStatus == stepIndex + 1;
              
              return _buildStepCircle(
                stepIndex + 1,
                isCompleted,
                isActive,
                icons.length > stepIndex ? icons[stepIndex] : null,
              );
            }
          }),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            return Expanded(
              child: Text(
                _getStepTitle(index + 1),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: currentStatus >= index + 1 
                      ? Colors.black87 
                      : Colors.grey[500],
                  fontWeight: currentStatus == index + 1 
                      ? FontWeight.w600 
                      : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool isCompleted, bool isActive, String? iconUrl) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        border: Border.all(
          color: isActive 
              ? Theme.of(context).primaryColor 
              : Colors.transparent,
          width: 3.w,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: 20.sp,
              )
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildMapTrackingCard(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.map,
                color: Colors.green,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Track on Map',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'View real-time order tracking on map',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12.h),
          CustomButton(
            text: 'Open Map View',
            onPressed: () => context.push('/order-tracking-map/${order.id}'),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildExternalTrackingCard(String trackingUrl) {
    final order = context.read<OrderProvider>().currentOrderDetails;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF1E88E5).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: const Color(0xFF1E88E5),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Live Driver Tracking Available',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Track your driver\'s live location',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Track Driver',
                  onPressed: () => _openTrackingUrl(trackingUrl),
                  backgroundColor: const Color(0xFF1E88E5),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: CustomButton(
                  text: 'In-App Tracking',
                  onPressed: () {
                    final url = Uri.encodeComponent(trackingUrl);
                    context.push('/order-tracking-webview/${order?.id ?? widget.orderId}?url=$url');
                  },
                  backgroundColor: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails(OrderModel order) {
    if (order.address == null) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            order.address!.address,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (order.address!.city != null || order.address!.state != null) ...[
            SizedBox(height: 4.h),
            Text(
              [order.address!.city, order.address!.state]
                  .where((s) => s != null)
                  .join(', '),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo(OrderModel order) {
    final vendor = order.vendors?.isNotEmpty == true 
        ? order.vendors!.first 
        : order.vendor;
        
    if (vendor == null) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (vendor is OrderVendorDetailModel && vendor.logo != null || 
              vendor is OrderVendorModel && vendor.logo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: vendor is OrderVendorDetailModel 
                    ? vendor.logo! 
                    : (vendor as OrderVendorModel).logo!,
                width: 48.w,
                height: 48.w,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 48.w,
                  height: 48.w,
                  color: Colors.grey[200],
                  child: Icon(Icons.restaurant, size: 24.sp),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 48.w,
                  height: 48.w,
                  color: Colors.grey[200],
                  child: Icon(Icons.restaurant, size: 24.sp),
                ),
              ),
            )
          else
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.restaurant, size: 24.sp),
            ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor is OrderVendorDetailModel 
                      ? vendor.vendorName ?? 'Unknown Restaurant'
                      : (vendor as OrderVendorModel).name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (vendor is OrderVendorModel && vendor.address != null)
                  Text(
                    vendor.address!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(OrderModel order) {
    final products = order.vendors?.isNotEmpty == true && order.vendors!.first.products != null
        ? order.vendors!.first.products!
        : order.products ?? [];
        
    if (products.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          ...products.map((product) => _buildOrderItem(product)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderProductModel product) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Center(
              child: Text(
                '${product.quantity}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              product.productName ?? 'Unknown Item',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            'AED ${(product.price * product.quantity).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Accepted';
      case 2:
        return 'Driver\nAssigned';
      case 3:
        return 'Heading to\nRestaurant';
      case 4:
        return 'Arrived at\nRestaurant';
      case 5:
        return 'Order\nPicked Up';
      case 6:
        return 'Delivered';
      default:
        return '';
    }
  }

  String _getStatusMessage(int status) {
    switch (status) {
      case 1:
        return 'Your order has been accepted and is being prepared';
      case 2:
        return 'A driver has been assigned to deliver your order';
      case 3:
        return 'The driver is heading to the restaurant';
      case 4:
        return 'The driver has arrived at the restaurant';
      case 5:
        return 'Your order has been picked up and is on the way';
      case 6:
        return 'Your order has been delivered successfully';
      default:
        return 'Tracking your order...';
    }
  }

  Future<void> _openTrackingUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open tracking link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening tracking link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}