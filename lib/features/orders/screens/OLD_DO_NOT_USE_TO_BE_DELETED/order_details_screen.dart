import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';

import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../widgets/driver_info_widget.dart';
import '../widgets/order_status_timeline.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/custom_button.dart';

/// Flutter implementation of React Native OrderDetail.js
/// Shows order details with real-time driver tracking on Google Maps
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final int? vendorId;
  final Map<String, dynamic>? orderDetail;
  final bool fromActive;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.vendorId,
    this.orderDetail,
    this.fromActive = false,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
  
  // State variables matching React Native exactly
  bool isLoading = true;
  bool orderDetailLoader = true;
  bool isRefreshing = false;
  bool showTaxFeeArea = false;
  bool arrowUp = false;
  
  // Driver tracking data
  Map<String, dynamic>? driverStatus;
  Map<String, dynamic>? driverTrackingData;
  
  // Google Maps
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  
  // Order data
  OrderModel? orderData;
  List<OrderVendorDetailModel>? cartItems;
  Map<String, dynamic>? cartData;
  Map<String, dynamic>? dispatcherStatus;
  
  // UI state
  int? currentPosition;
  String? lalaMoveUrl;
  String? trackingUrl;
  List<String> labels = [
    'Accepted',
    'Processing', 
    'Out For Delivery',
    'Delivered'
  ];
  
  // Timers
  Timer? _pollingTimer;
  Timer? _driverTrackingTimer;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Load order details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getOrderDetailScreen();
    });
    
    // Start 5-second polling for active orders (matching React Native)
    if (widget.fromActive) {
      _startPolling();
    }
  }
  
  @override
  void dispose() {
    _pollingTimer?.cancel();
    _driverTrackingTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  /// Start 5-second polling for real-time updates (matching React Native useInterval)
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && widget.fromActive) {
        _getOrderDetailScreen(silent: true);
      }
    });
  }
  
  /// Get order details from API (matching React Native _getOrderDetailScreen)
  Future<void> _getOrderDetailScreen({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        orderDetailLoader = true;
      });
    }
    
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      // Load order details with vendor_id
      await orderProvider.loadOrderDetails(
        orderId: int.parse(widget.orderId),
        vendorId: widget.vendorId,
      );
      
      final order = orderProvider.currentOrderDetails;
      if (order != null) {
        setState(() {
          orderData = order;
          cartItems = order.vendors;
          cartData = {'order_number': order.orderNumber};
          
          // Extract driver status from order data
          if (order.vendors?.isNotEmpty == true) {
            final vendor = order.vendors!.first;
            driverStatus = {
              'agent_location': {
                'lat': vendor.agentLocation?['lat'],
                'long': vendor.agentLocation?['long'],
                'heading_angle': vendor.agentLocation?['heading_angle'],
              },
              'order': vendor.dispatchTrakingUrl != null ? {} : null,
            };
            
            // Set dispatcher status
            dispatcherStatus = {
              'dispatch_traking_url': vendor.dispatchTrakingUrl,
              'dispatcher_status_option_id': vendor.dispatcherStatusOptionId,
              'vendor_dispatcher_status': vendor.vendorDispatcherStatus,
              'order_status': order.orderStatus,
            };
            
            // Set tracking URL
            trackingUrl = vendor.dispatchTrakingUrl;
            
            // Calculate current position for step indicator
            _calculateCurrentPosition(order);
          }
          
          isLoading = false;
          orderDetailLoader = false;
          isRefreshing = false;
        });
        
        // Update map markers if driver location available
        _updateMapMarkers();
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        orderDetailLoader = false;
        isRefreshing = false;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order: $error')),
        );
      }
    }
  }
  
  /// Calculate current position for step indicator
  void _calculateCurrentPosition(OrderModel order) {
    if (order.orderStatus?.currentStatus?.title != null) {
      final status = order.orderStatus!.currentStatus!.title!;
      
      // Match React Native logic for position calculation
      if (order.luxuryOptionName != 'Delivery') {
        // For pickup orders, different step sequence
        labels = ['Accepted', 'Processing', 'Order Prepared', 'Delivered'];
      }
      
      // Find position in labels array
      final position = labels.indexWhere((label) => 
        label.toLowerCase() == status.toLowerCase()
      );
      
      if (position != -1) {
        currentPosition = position;
      }
    }
  }
  
  /// Update Google Maps markers based on driver location
  void _updateMapMarkers() {
    if (orderData?.vendors?.isNotEmpty != true) return;
    
    final vendor = orderData!.vendors!.first;
    Set<Marker> newMarkers = {};
    
    // Add restaurant marker
    if (vendor.vendor?.latitude != null && vendor.vendor?.longitude != null) {
      final restLat = double.tryParse(vendor.vendor!.latitude!);
      final restLng = double.tryParse(vendor.vendor!.longitude!);
      
      if (restLat != null && restLng != null) {
        newMarkers.add(Marker(
          markerId: const MarkerId('restaurant'),
          position: LatLng(restLat, restLng),
          infoWindow: InfoWindow(
            title: vendor.vendor?.name ?? 'Restaurant',
            snippet: 'Pickup Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));
      }
    }
    
    // Add delivery location marker
    if (orderData?.address?.latitude != null && orderData?.address?.longitude != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(orderData!.address!.latitude!, orderData!.address!.longitude!),
        infoWindow: const InfoWindow(
          title: 'Delivery Location',
          snippet: 'Your Address',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    
    // Add driver marker if location available
    if (driverStatus?['agent_location']?['lat'] != null && 
        driverStatus?['agent_location']?['long'] != null) {
      final lat = double.tryParse(driverStatus!['agent_location']['lat']?.toString() ?? '');
      final lng = double.tryParse(driverStatus!['agent_location']['long']?.toString() ?? '');
      
      if (lat != null && lng != null) {
        newMarkers.add(Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(
            title: 'Driver',
            snippet: 'Live Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: double.tryParse(driverStatus!['agent_location']['heading_angle']?.toString() ?? '0') ?? 0,
        ));
      }
    }
    
    setState(() {
      markers = newMarkers;
    });
    
    // Fit map to show all markers
    if (markers.isNotEmpty && mapController != null) {
      _fitMapToMarkers();
    }
  }
  
  /// Fit map camera to show all markers
  void _fitMapToMarkers() {
    if (markers.isEmpty || mapController == null) return;
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final marker in markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }
    
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }
  
  /// Handle refresh (matching React Native)
  Future<void> _handleRefresh() async {
    setState(() {
      isRefreshing = true;
    });
    await _getOrderDetailScreen();
  }
  
  /// Dial phone number (matching React Native Communications.phonecall)
  Future<void> _dialCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  /// Navigate to chat screen (matching React Native)
  void _createRoom(Map<String, dynamic> item, String type) {
    // TODO: Implement chat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat functionality not implemented yet')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Order ${orderData?.orderNumber ?? widget.orderId}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: isLoading && orderDetailLoader
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Main content container (matching React Native bordered style)
                    Container(
                      margin: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Google Maps tracking widget (large embedded map matching React Native)
                          if (_shouldShowMap()) _buildLargeMapWidget(),
                          
                          // Driver info section (matching React Native UserDetail)
                          if (_shouldShowDriverInfo()) _buildDriverInfoSection(),
                          
                          // Vendor/Restaurant info section
                          if (orderData?.vendors?.isNotEmpty == true) _buildVendorSection(),
                          
                          // LaLaMove WebView section
                          if (lalaMoveUrl != null) _buildLaLaMoveSection(),
                          
                          // Order status and tracking
                          if (dispatcherStatus != null) _buildOrderStatusSection(),
                          
                          // Expandable order status list (matching React Native)
                          if (driverStatus != null) _buildExpandableStatusList(),
                          
                          // Order items
                          if (orderData?.vendors?.isNotEmpty == true) _buildOrderItemsSection(),
                          
                          // Order summary
                          if (orderData != null) _buildOrderSummarySection(),
                        ],
                      ),
                    ),
                    
                    // Footer with order information (matching React Native getFooter)
                    _buildOrderFooter(),
                  ],
                ),
              ),
            ),
    );
  }
  
  /// Check if map should be shown (matching React Native logic)
  bool _shouldShowMap() {
    return driverStatus?['order'] != null && 
           driverStatus?['agent_location']?['lat'] != null &&
           orderData?.orderStatus?.currentStatus?.title != 'Delivered';
  }
  
  /// Check if driver info should be shown
  bool _shouldShowDriverInfo() {
    return driverStatus?['order'] != null;
  }
  
  /// Build large embedded Google Maps widget (matching React Native height/2.2)
  Widget _buildLargeMapWidget() {
    return Container(
      height: MediaQuery.of(context).size.height / 2.2,
      width: double.infinity,
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
          _updateMapMarkers();
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(30.7173, 76.8035), // Default position
          zoom: 14.0,
        ),
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
  
  /// Build driver info section (matching React Native UserDetail for driver)
  Widget _buildDriverInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: DriverInfoWidget(
        order: orderData,
        vendor: orderData?.vendors?.first,
        driverData: driverStatus,
        agentLocation: driverStatus?['agent_location'],
      ),
    );
  }
  
  /// Build vendor/restaurant section (matching React Native)
  Widget _buildVendorSection() {
    final vendor = orderData!.vendors!.first;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Vendor logo
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: ImageUtils.buildImageUrl(vendor.vendor?.logo) ?? '',
              width: 50.w,
              height: 50.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 50.w,
                height: 50.w,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant),
              ),
              errorWidget: (context, url, error) => Container(
                width: 50.w,
                height: 50.w,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant),
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
                  vendor.vendor?.name ?? 'Restaurant',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (vendor.vendor?.address != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    vendor.vendor!.address!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Contact buttons
          if (vendor.vendor?.phone != null) ...[
            IconButton(
              onPressed: () => _dialCall(vendor.vendor!.phone!),
              icon: const Icon(Icons.phone, color: Colors.green),
            ),
            IconButton(
              onPressed: () => _createRoom({'id': vendor.id}, 'vendor_to_user'),
              icon: const Icon(Icons.chat, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build LaLaMove WebView section (matching React Native)
  Widget _buildLaLaMoveSection() {
    return Container(
      height: 300.h,
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: const Center(
          child: Text('LaLaMove Tracking WebView'),
        ),
      ),
    );
  }
  
  /// Build order status section with step indicators (matching React Native)
  Widget _buildOrderStatusSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Step indicators
          if (currentPosition != null)
            _buildStepIndicators(),
          
          SizedBox(height: 16.h),
          
          // Current status message
          if (dispatcherStatus?['vendor_dispatcher_status'] != null &&
              (dispatcherStatus!['vendor_dispatcher_status'] as List).isNotEmpty)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                (dispatcherStatus!['vendor_dispatcher_status'] as List).last['status_data']['driver_status'] ?? 
                'Order is being processed',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          // ETA information
          if (orderData?.eta != null || orderData?.scheduledDateTime != null)
            Container(
              margin: EdgeInsets.only(top: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Your order will arrive by ${orderData?.eta ?? orderData?.scheduledDateTime}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build step indicators widget
  Widget _buildStepIndicators() {
    return Row(
      children: List.generate(labels.length, (index) {
        final isCompleted = index < currentPosition!;
        final isCurrent = index == currentPosition;
        
        return Expanded(
          child: Row(
            children: [
              // Step circle
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isCurrent 
                      ? AppColors.primaryColor 
                      : Colors.grey[300],
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16.sp,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey[600],
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              // Connecting line (except for last step)
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2.h,
                    color: isCompleted 
                        ? AppColors.primaryColor 
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
  
  /// Build expandable order status list (matching React Native)
  Widget _buildExpandableStatusList() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Toggle button
          InkWell(
            onTap: () => setState(() => arrowUp = !arrowUp),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Status Details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Transform.rotate(
                    angle: arrowUp ? 0 : 3.14159, // 180 degrees
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          if (arrowUp) 
            OrderStatusTimeline(
              statuses: (dispatcherStatus?['vendor_dispatcher_status'] as List<dynamic>?)
                ?.cast<DispatcherStatusModel>() ?? [],
            ),
        ],
      ),
    );
  }
  
  /// Build order items section
  Widget _buildOrderItemsSection() {
    final vendor = orderData!.vendors!.first;
    final products = vendor.products ?? [];
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          ...products.map((product) => _buildOrderItem(product)),
        ],
      ),
    );
  }
  
  /// Build individual order item
  Widget _buildOrderItem(OrderProductModel product) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: ImageUtils.buildImageUrl(product.productImage) ?? '',
              width: 60.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 60.w,
                height: 60.w,
                color: Colors.grey[300],
                child: const Icon(Icons.fastfood),
              ),
              errorWidget: (context, url, error) => Container(
                width: 60.w,
                height: 60.w,
                color: Colors.grey[300],
                child: const Icon(Icons.fastfood),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Product',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Qty: ${product.quantity} x \$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Price
          Text(
            '\$${(product.price * product.quantity).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build order summary section
  Widget _buildOrderSummarySection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          _buildSummaryRow('Subtotal', '\$${orderData?.subtotalAmount?.toStringAsFixed(2) ?? orderData?.totalAmount.toStringAsFixed(2)}'),
          if (orderData?.totalDeliveryFee != null)
            _buildSummaryRow('Delivery Fee', '\$${orderData!.totalDeliveryFee!.toStringAsFixed(2)}'),
          if (orderData?.taxableAmount != null)
            _buildSummaryRow('Tax', '\$${orderData!.taxableAmount!.toStringAsFixed(2)}'),
          if (orderData?.discountAmount != null)
            _buildSummaryRow('Discount', '-\$${orderData!.discountAmount!.toStringAsFixed(2)}', isDiscount: true),
          
          Divider(height: 24.h),
          
          _buildSummaryRow(
            'Total', 
            '\$${orderData!.totalAmount.toStringAsFixed(2)}', 
            isTotal: true,
          ),
        ],
      ),
    );
  }
  
  /// Build summary row helper
  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isDiscount 
                  ? Colors.green 
                  : isTotal 
                      ? Colors.black 
                      : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build order footer with address and actions (matching React Native getFooter)
  Widget _buildOrderFooter() {
    return Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery address
          if (orderData?.address != null) _buildDeliveryAddressSection(),
          
          // Order information
          _buildOrderInformationSection(),
          
          // Action buttons
          SizedBox(height: 20.h),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  /// Build delivery address section with small map
  Widget _buildDeliveryAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Address',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        
        SizedBox(height: 8.h),
        
        Row(
          children: [
            // Small map preview (matching React Native 60x60)
            if (orderData?.address?.latitude != null && orderData?.address?.longitude != null)
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        orderData!.address!.latitude!,
                        orderData!.address!.longitude!,
                      ),
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('delivery_small'),
                        position: LatLng(
                          orderData!.address!.latitude!,
                          orderData!.address!.longitude!,
                        ),
                      ),
                    },
                    zoomGesturesEnabled: false,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                ),
              )
            else
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Icon(Icons.location_on),
              ),
            
            SizedBox(width: 12.w),
            
            // Address text
            Expanded(
              child: Text(
                '${orderData?.address?.houseNumber ?? ''} ${orderData?.address?.address ?? ''} ${orderData?.address?.pincode ?? ''}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),
      ],
    );
  }
  
  /// Build order information section
  Widget _buildOrderInformationSection() {
    return Column(
      children: [
        _buildInfoRow('Order Number', '#${orderData?.orderNumber ?? 'N/A'}'),
        _buildInfoRow('Payment Method', _getPaymentMethodText(orderData?.paymentMethod)),
        _buildInfoRow('Placed On', _formatDate(orderData?.createdAt)),
        if (orderData?.scheduledDateTime != null)
          _buildInfoRow('Scheduled For', orderData!.scheduledDateTime!),
      ],
    );
  }
  
  /// Build info row helper
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build action buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Track Order button
        CustomButton(
          text: 'Track Order',
          onPressed: () {
            context.push('/order-tracking/${widget.orderId}');
          },
          backgroundColor: AppColors.primaryColor,
          textColor: Colors.white,
        ),
        
        SizedBox(height: 12.h),
        
        // Track on Map button (if driver available)
        if (_shouldShowMap())
          CustomButton(
            text: 'Track on Map',
            onPressed: () {
              context.push('/order-tracking-map/${widget.orderId}');
            },
            backgroundColor: Colors.green,
            textColor: Colors.white,
          ),
        
        SizedBox(height: 12.h),
        
        // Live Tracking button (if tracking URL available)
        if (trackingUrl != null)
          CustomButton(
            text: 'Live Tracking',
            onPressed: () {
              context.push('/order-tracking-webview/${widget.orderId}?url=${Uri.encodeComponent(trackingUrl!)}');
            },
            backgroundColor: Colors.purple,
            textColor: Colors.white,
          ),
      ],
    );
  }
  
  /// Get payment method text
  String _getPaymentMethodText(String? method) {
    switch (method?.toLowerCase()) {
      case '1':
      case 'cash':
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case '2':
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Wallet';
      default:
        return method ?? 'N/A';
    }
  }
  
  /// Format date string
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}