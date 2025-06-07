import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:math' as math;

import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/step_indicator.dart';
import '../widgets/rating_modal.dart';
import '../widgets/driver_info_widget.dart';
import '../widgets/order_status_timeline.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';

// Exactly matching React Native OrderDetail.js
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final int? vendorId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.vendorId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
  // State matching React Native
  bool isLoading = true;
  bool orderDetailLoader = true;
  bool isRefreshing = false;
  bool showTaxFeeArea = false;
  bool arrowUp = false;

  // Driver tracking
  Timer? _driverTrackingTimer;
  Map<String, dynamic>? _driverTrackingData;

  // Google Maps controller
  gmaps.GoogleMapController? _mapController;
  bool _mapReady = false;

  List<String> labels = [
    'Accepted',
    'Processing',
    'Out For Delivery',
    'Delivered'
  ];

  int? currentPosition;
  Map<String, dynamic>? driverStatus;
  Timer? _timer;

  String? lalaMoveUrl;
  String? trackingUrl;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // WebView controller
  WebViewController? _webViewController;

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

    // Load order details matching React Native
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getOrderDetailScreen();
    });

    // Set up timer for auto refresh like React Native useInterval
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !isRefreshing) {
        _getOrderDetailScreen(silent: true);
      }
    });

    // Start driver tracking if needed
    _startDriverTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _driverTrackingTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    // Safely dispose map controller
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  // Matching React Native _getOrderDetailScreen
  Future<void> _getOrderDetailScreen({bool silent = false}) async {
    if (!silent) {
      setState(() {
        orderDetailLoader = true;
      });
    }

    final orderProvider = context.read<OrderProvider>();
    final orderIdInt = int.tryParse(widget.orderId);

    if (orderIdInt == null) return;

    // Prepare data matching React Native
    Map<String, dynamic> data = {
      'order_id': widget.orderId,
    };

    if (widget.vendorId != null) {
      data['vendor_id'] = widget.vendorId;
    }

    // Find cached order to get correct IDs
    final cachedOrder = orderProvider.findOrderById(orderIdInt);
    if (cachedOrder != null) {
      data['order_id'] = cachedOrder.orderId ?? orderIdInt;
      data['vendor_id'] = cachedOrder.vendorId ?? widget.vendorId;
    }

    try {
      await orderProvider.loadOrderDetails(
        orderId: data['order_id'],
        vendorId: data['vendor_id'],
        showLoading: !silent,
      );

      if (!mounted) return;

      setState(() {
        orderDetailLoader = false;
        isLoading = false;
        isRefreshing = false;
      });

      // Update tracking info if available
      final order = orderProvider.currentOrderDetails;
      if (order != null && order.vendors?.isNotEmpty == true) {
        final vendor = order.vendors!.first;

        // Debug vendor information
        debugPrint('=== Order Tracking URLs Debug ===');
        debugPrint('Vendor ID: ${vendor.id}');
        debugPrint('Dispatch Tracking URL: ${vendor.dispatchTrakingUrl}');

        // Check for tracking URLs
        if (vendor.dispatchTrakingUrl != null &&
            vendor.dispatchTrakingUrl!.isNotEmpty) {
          setState(() {
            lalaMoveUrl = vendor.dispatchTrakingUrl;
            trackingUrl = vendor.dispatchTrakingUrl;
          });

          // Initialize or update WebView if tracking URL exists
          if (_webViewController == null) {
            _webViewController = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(
                NavigationDelegate(
                  onPageStarted: (String url) {
                    debugPrint('WebView started loading: $url');
                  },
                  onPageFinished: (String url) {
                    debugPrint('WebView finished loading: $url');
                  },
                  onWebResourceError: (WebResourceError error) {
                    debugPrint('WebView error: ${error.description}');
                  },
                ),
              )
              ..loadRequest(Uri.parse(vendor.dispatchTrakingUrl!));
          } else {
            // Update URL if it changed
            _webViewController!
                .loadRequest(Uri.parse(vendor.dispatchTrakingUrl!));
          }
        }

        // Update labels for non-delivery orders
        if (order.luxuryOptionName != 'Delivery') {
          setState(() {
            labels = ['Accepted', 'Processing', 'Order Prepared', 'Delivered'];
          });
        }

        // Start driver tracking if this is an active delivery order
        if (_shouldShowMap(order)) {
          _startDriverTracking();
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        orderDetailLoader = false;
        isLoading = false;
        isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading order details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      isRefreshing = true;
    });

    await _getOrderDetailScreen();
  }

  // Start driver tracking for active orders
  void _startDriverTracking() {
    debugPrint('=== Starting driver tracking ===');
    
    // Cancel existing timer if any
    _driverTrackingTimer?.cancel();

    // Start polling every 5 seconds for driver location
    _driverTrackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !isRefreshing) {
        debugPrint('Driver tracking timer tick...');
        _fetchDriverLocation();
      }
    });
  }

  // Fetch driver location from API
  Future<void> _fetchDriverLocation() async {
    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrderDetails;

    if (order == null) {
      debugPrint('No order details available for tracking');
      return;
    }

    // Only track if order is active and has driver assigned
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    
    debugPrint('=== _fetchDriverLocation Debug ===');
    debugPrint('Order ID: ${order.id}');
    debugPrint('Vendor exists: ${vendor != null}');
    debugPrint('Driver ID: ${vendor?.driverId}');
    debugPrint('Dispatcher Status: ${vendor?.dispatcherStatusOptionId}');
    debugPrint('Tracking URL: ${vendor?.dispatchTrakingUrl}');
    
    if (vendor == null) {
      debugPrint('No vendor found, skipping tracking');
      return;
    }

    // Don't track if order is completed
    if (vendor.dispatcherStatusOptionId == 6) {
      debugPrint('Order is completed, stopping tracking');
      _driverTrackingTimer?.cancel();
      return;
    }

    try {
      final orderService = OrderService();
      
      // Call order details API to get latest data including agent_location
      final response = await orderService.getOrderDetails(
        orderId: order.orderId ?? order.id,
        vendorId: vendor.vendorId ?? vendor.id,
      );

      if (response.success && response.data != null) {
        final updatedOrder = response.data!;
        final updatedVendor = updatedOrder.vendors?.isNotEmpty == true 
            ? updatedOrder.vendors!.first 
            : null;
        
        // Check if the response has agent_location data
        debugPrint('=== Driver Tracking Response ===');
        debugPrint('Updated order has vendors: ${updatedOrder.vendors?.length ?? 0}');
        
        // Try to get agent_location from vendor data
        if (updatedVendor != null) {
          // Create tracking data structure
          final trackingData = <String, dynamic>{};
          
          // Add agent location if available
          if (updatedVendor.agentLocation != null) {
            trackingData['agent_location'] = updatedVendor.agentLocation;
            debugPrint('Found agent_location in vendor: ${updatedVendor.agentLocation}');
          }
          
          // Add tasks if available
          if (updatedVendor.tasks != null) {
            trackingData['tasks'] = updatedVendor.tasks;
          }
          
          // Update state with tracking data
          if (trackingData.isNotEmpty) {
            setState(() {
              _driverTrackingData = trackingData;
            });
            debugPrint('Driver tracking data updated: $trackingData');
          } else {
            debugPrint('No tracking data found in response');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching driver location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrderDetails;
    final isLoadingDetails = orderProvider.isLoadingOrderDetails;

    if (orderDetailLoader || isLoadingDetails) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: _buildLoaderView(),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: _buildEmptyView(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: RefreshControl(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Order status section
              _buildOrderStatusSection(order),

              // Driver info section - matches React Native UserDetail in header
              if (_shouldShowDriverInfo(order))
                DriverInfoWidget(
                  order: order,
                  vendor: order.vendors?.isNotEmpty == true
                      ? order.vendors!.first
                      : null,
                ),

              // Map section for driver tracking - matches React Native large MapView
              if (_shouldShowMap(order)) _buildMapSection(order),

              // LaLaMove WebView section - matches React Native lalaMoveUrl WebView
              if (lalaMoveUrl != null) _buildLalaMoveWebView(),

              // Step indicators for current status - matches React Native StepIndicators
              if (_shouldShowStepIndicators(order)) _buildStepIndicators(order),

              // Order Status expandable section - matches React Native arrowUp section
              if (_shouldShowOrderStatus(order)) _buildOrderStatusList(order),

              // Main order content
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    // Vendor info section - matches React Native vendor header
                    _buildVendorSection(order),

                    // Order items - matches React Native product list
                    _buildOrderItemsSection(order),

                    // Bottom section with address (includes small map) and payment
                    _buildBottomSection(order),
                  ],
                ),
              ),

              // Action buttons
              _buildActionButtons(order),

              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Order Details',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (trackingUrl != null)
          IconButton(
            icon: Icon(Icons.map_outlined, color: AppColors.primaryColor),
            onPressed: () => _openTrackingUrl(),
          ),
      ],
    );
  }

  Widget _buildLoaderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading.json',
            width: 200.w,
            height: 200.h,
          ),
          SizedBox(height: 20.h),
          Text(
            'Loading order details...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 100.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20.h),
          Text(
            'Order not found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Please check your order ID and try again',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusSection(OrderModel order) {
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final orderStatus = vendor?.orderStatus ?? order.orderStatus;
    final dispatcherStatus = vendor?.dispatcherStatusOptionId;

    // Determine current position based on status
    int position = 0;
    int? statusId;
    String? statusTitle;

    if (orderStatus is OrderStatusModel) {
      statusId = orderStatus.currentStatus?.id;
      statusTitle = orderStatus.currentStatus?.title;
    } else if (orderStatus is OrderStatusDetailModel) {
      statusId = orderStatus.currentStatus?.id;
      statusTitle = orderStatus.currentStatus?.title;
    }

    if (statusId == 2 || dispatcherStatus == 1) position = 1;
    if (statusId == 3 || dispatcherStatus == 3) position = 2;
    if (statusId == 4 || dispatcherStatus == 5) position = 3;
    if (statusId == 5 || dispatcherStatus == 6) position = 4;

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(statusTitle).withAlpha(26), // 0.1 * 255
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    statusTitle ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(statusTitle),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(
                DateTime.parse(order.createdAt ?? DateTime.now().toString()),
              ),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            if (order.paymentMethod != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    _getPaymentIcon(order.paymentMethod!),
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    order.paymentMethod!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            // Step indicator matching React Native
            if (position > 0) ...[
              SizedBox(height: 20.h),
              StepIndicatorWidget(
                labels: labels,
                currentPosition: position - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVendorSection(OrderModel order) {
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final vendorInfo = vendor?.vendor ?? order.vendor;

    if (vendorInfo == null) return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        color: Colors.white,
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetworkImage(
                imageUrl: ImageUtils.buildVendorLogoUrl(vendorInfo.logo) ?? '',
                width: 60.w,
                height: 60.w,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.store,
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
                    vendorInfo.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (vendorInfo.address != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      vendorInfo.address!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (vendorInfo.phone != null)
              IconButton(
                icon: Icon(
                  Icons.phone_outlined,
                  color: AppColors.primaryColor,
                ),
                onPressed: () => _callVendor(vendorInfo.phone!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(OrderModel order) {
    // Matches React Native's large MapView for driver tracking
    if (!mounted) return const SizedBox.shrink();

    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    
    // Show map for active delivery orders
    if (vendor == null) {
      return const SizedBox.shrink();
    }

    debugPrint('=== _buildMapSection Debug ===');
    debugPrint('Building map for order: ${order.id}');
    debugPrint('Vendor exists: ${vendor != null}');
    debugPrint('Dispatch URL: ${vendor.dispatchTrakingUrl}');
    debugPrint('==============================');

    // Get locations from order
    final vendorLocation = vendor.vendor;
    final deliveryAddress = order.address;

    // Build markers list
    final Set<gmaps.Marker> markers = {};
    
    // Add vendor/restaurant marker
    if (vendorLocation != null && 
        vendorLocation.latitude != null && 
        vendorLocation.longitude != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('vendor'),
          position: gmaps.LatLng(
            double.parse(vendorLocation.latitude!),
            double.parse(vendorLocation.longitude!),
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueOrange,
          ),
          infoWindow: gmaps.InfoWindow(
            title: vendorLocation.name,
            snippet: 'Restaurant',
          ),
        ),
      );
    }

    // Add delivery address marker
    if (deliveryAddress != null &&
        deliveryAddress.latitude != null &&
        deliveryAddress.longitude != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('delivery'),
          position: gmaps.LatLng(
            deliveryAddress.latitude!,
            deliveryAddress.longitude!,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen,
          ),
          infoWindow: gmaps.InfoWindow(
            title: 'Delivery Location',
            snippet: deliveryAddress.address,
          ),
        ),
      );
    }

    // Add driver marker if location available
    gmaps.LatLng? driverLocation;
    if (_driverTrackingData != null &&
        _driverTrackingData!['agent_location'] != null) {
      final agentLocation = _driverTrackingData!['agent_location'];
      if (agentLocation['lat'] != null && agentLocation['lng'] != null) {
        driverLocation = gmaps.LatLng(
          double.tryParse(agentLocation['lat'].toString()) ?? 0,
          double.tryParse(agentLocation['lng'].toString()) ?? 0,
        );

        markers.add(
          gmaps.Marker(
            markerId: const gmaps.MarkerId('driver'),
            position: driverLocation,
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueBlue,
            ),
            infoWindow: const gmaps.InfoWindow(
              title: 'Delivery Driver',
              snippet: 'On the way',
            ),
            rotation: double.tryParse(
                _driverTrackingData!['agent_location']['heading_angle']?.toString() ?? '0') ?? 0,
          ),
        );
      }
    }

    // Initial region - center on vendor or delivery location
    final initialLat = vendorLocation?.latitude != null
        ? double.parse(vendorLocation!.latitude!)
        : deliveryAddress?.latitude ?? 0;
    final initialLng = vendorLocation?.longitude != null
        ? double.parse(vendorLocation!.longitude!)
        : deliveryAddress?.longitude ?? 0;

    return Container(
      height: MediaQuery.of(context).size.height / 2.2,  // Match React Native height
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(initialLat, initialLng),
                zoom: 13,
              ),
              markers: markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapType: gmaps.MapType.normal,
              onMapCreated: (controller) {
                _mapController = controller;
                _mapReady = true;
                // Fit map to show all markers
                _fitMapToMarkers(markers);
              },
              polylines: _buildPolylines(vendorLocation, deliveryAddress, driverLocation),
            ),
            // Status overlay
            if (vendor.dispatcherStatusOptionId != null)
              Positioned(
                top: 16.h,
                left: 16.w,
                right: 16.w,
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        color: AppColors.primaryColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _getDriverStatusText(vendor.dispatcherStatusOptionId),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDriverStatusText(int? statusId) {
    switch (statusId) {
      case 1:
        return 'Order Accepted';
      case 2:
        return 'Driver Assigned';
      case 3:
        return 'Driver heading to restaurant';
      case 4:
        return 'Driver arrived at restaurant';
      case 5:
        return 'Order picked up';
      case 6:
        return 'Order delivered';
      default:
        return 'Processing order';
    }
  }

  Set<gmaps.Polyline> _buildPolylines(
    OrderVendorModel? vendorLocation,
    OrderAddressModel? deliveryAddress,
    gmaps.LatLng? driverLocation,
  ) {
    final Set<gmaps.Polyline> polylines = {};
    
    // Add polyline from vendor to delivery
    if (vendorLocation != null &&
        vendorLocation.latitude != null &&
        vendorLocation.longitude != null &&
        deliveryAddress != null &&
        deliveryAddress.latitude != null &&
        deliveryAddress.longitude != null) {
      
      final List<gmaps.LatLng> points = [];
      
      // Add vendor location
      points.add(gmaps.LatLng(
        double.parse(vendorLocation.latitude!),
        double.parse(vendorLocation.longitude!),
      ));
      
      // Add driver location if available
      if (driverLocation != null) {
        points.add(driverLocation);
      }
      
      // Add delivery location
      points.add(gmaps.LatLng(
        deliveryAddress.latitude!,
        deliveryAddress.longitude!,
      ));
      
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points: points,
          color: AppColors.primaryColor,
          width: 3,
        ),
      );
    }
    
    return polylines;
  }

  void _fitMapToMarkers(Set<gmaps.Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;
    
    // Calculate bounds
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;
    
    for (final marker in markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }
    
    _mapController!.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(
        gmaps.LatLngBounds(
          southwest: gmaps.LatLng(minLat, minLng),
          northeast: gmaps.LatLng(maxLat, maxLng),
        ),
        100.w, // padding
      ),
    );
  }

  Widget _buildOrderItemsSection(OrderModel order) {
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final products = vendor?.products ?? order.products ?? [];

    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(16.w),
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
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: ImageUtils.buildImageUrl(product.productImage) ?? '',
              width: 60.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.image,
                  color: Colors.grey[400],
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
                  product.productName ?? 'Unknown Item',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                // Skip variant options and addons for now as they're not in the model
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AED ${product.price.toStringAsFixed(2)} x ${product.quantity}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'AED ${(product.price * product.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(OrderModel order) {
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
                showTaxFeeArea = !showTaxFeeArea;
                arrowUp = !arrowUp;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  arrowUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),

          if (showTaxFeeArea) ...[
            SizedBox(height: 16.h),

            // Subtotal
            _buildPriceRow(
                'Subtotal', order.subtotalAmount ?? order.totalAmount),

            // Delivery fee
            if ((order.totalDeliveryFee ?? 0) > 0)
              _buildPriceRow('Delivery Fee', order.totalDeliveryFee!),

            // Service fee
            if ((order.totalServiceFee ?? 0) > 0)
              _buildPriceRow('Service Fee', order.totalServiceFee!),

            // Tax
            if ((order.taxableAmount ?? 0) > 0)
              _buildPriceRow('Tax', order.taxableAmount!),

            // Discount
            if ((order.discountAmount ?? 0) > 0)
              _buildPriceRow(
                'Discount ${order.couponCode != null ? "(${order.couponCode})" : ""}',
                -order.discountAmount!,
                color: Colors.green,
              ),

            // Tip
            if ((order.tipAmount ?? 0) > 0)
              _buildPriceRow('Tip', order.tipAmount!),

            // Skip wallet for now as it's not in the model

            // Loyalty
            if ((order.loyaltyAmountSaved ?? 0) > 0)
              _buildPriceRow('Loyalty', -order.loyaltyAmountSaved!,
                  color: Colors.green),

            Divider(height: 24.h),
          ],

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                'AED ${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}AED ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(OrderModel order) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery address with small map - matches React Native
          if (order.address != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Small map preview - matches React Native 60x60 map
                if (order.address!.latitude != null && 
                    order.address!.longitude != null)
                  Container(
                    width: 60.w,
                    height: 60.w,
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: gmaps.GoogleMap(
                        initialCameraPosition: gmaps.CameraPosition(
                          target: gmaps.LatLng(
                            order.address!.latitude!,
                            order.address!.longitude!,
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          gmaps.Marker(
                            markerId: const gmaps.MarkerId('delivery'),
                            position: gmaps.LatLng(
                              order.address!.latitude!,
                              order.address!.longitude!,
                            ),
                          ),
                        },
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        order.address!.address,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],

          // Special instructions
          if (order.specificInstructions?.isNotEmpty == true ||
              order.commentForVendor?.isNotEmpty == true) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.note_outlined,
                  color: AppColors.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Special Instructions',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (order.commentForVendor?.isNotEmpty == true)
                        Text(
                          'For Restaurant: ${order.commentForVendor}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (order.specificInstructions?.isNotEmpty == true)
                        Text(
                          'For Delivery: ${order.specificInstructions}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],

          // Loyalty points
          if ((order.loyaltyPointsEarned ?? 0) > 0 ||
              (order.loyaltyPointsUsed ?? 0) > 0) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.stars,
                    color: Colors.purple,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loyalty Points',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[900],
                          ),
                        ),
                        if ((order.loyaltyPointsUsed ?? 0) > 0)
                          Text(
                            'Used: ${order.loyaltyPointsUsed} points',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.purple[700],
                            ),
                          ),
                        if ((order.loyaltyPointsEarned ?? 0) > 0)
                          Text(
                            'Earned: ${order.loyaltyPointsEarned} points',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.purple[700],
                            ),
                          ),
                      ],
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

  Widget _buildActionButtons(OrderModel order) {
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final orderStatus = vendor?.orderStatus ?? order.orderStatus;
    final currentStatus =
        orderStatus is OrderStatusModel ? orderStatus.currentStatus : null;
    final isDelivered = currentStatus?.title == 'Delivered';
    final isActive = !isDelivered && currentStatus?.title != 'Cancelled';

    // return Text("${isActive} and ${isDelivered} and ${currentStatus}");
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Track order button (show when no dispatcher tracking URL)
          if (isActive && vendor?.dispatchTrakingUrl == null)
            CustomButton(
              text: 'Track Order',
              onPressed: () =>
                  context.push('/order-tracking/${widget.orderId}'),
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
              icon: Icon(Icons.location_on_outlined, color: Colors.white),
            ),

          // Track on map button
          if (isActive && _shouldShowMap(order))
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: CustomButton(
                text: 'Track on Map',
                onPressed: () =>
                    context.push('/order-tracking-map/${widget.orderId}'),
                backgroundColor: Colors.green,
                textColor: Colors.white,
                icon: Icon(Icons.map_outlined, color: Colors.white),
              ),
            ),

          // External tracking button
          if (lalaMoveUrl != null)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: CustomButton(
                text: 'Open LaLaMove Tracking',
                onPressed: () => _openUrl(lalaMoveUrl!),
                backgroundColor: Colors.orange,
                textColor: Colors.white,
                icon: Icon(Icons.open_in_new, color: Colors.white),
              ),
            ),

          // Rate order button
          if (isDelivered && vendor?.products?.isNotEmpty == true)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: CustomButton(
                text: 'Rate Your Order',
                onPressed: () => _showRatingModal(order),
                backgroundColor: Colors.amber,
                textColor: Colors.white,
                icon: Icon(Icons.star_outline, color: Colors.white),
              ),
            ),

          // Generate invoice button
          if (isDelivered)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: CustomButton(
                text: 'Generate Invoice',
                onPressed: () => _generateInvoice(order),
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                icon: Icon(Icons.receipt_long_outlined, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  bool _shouldShowMap(OrderModel order) {
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final hasDriver = vendor?.driverId != null;
    final isDelivery = order.luxuryOptionName == 'Delivery' || 
                       order.luxuryOptionName == 'delivery' ||
                       order.luxuryOptionName == null; // Show for null as well
    final dispatcherStatus = vendor?.dispatcherStatusOptionId ?? 0;
    final hasDispatchUrl = vendor?.dispatchTrakingUrl != null && vendor!.dispatchTrakingUrl!.isNotEmpty;

    // Debug logging
    debugPrint('=== _shouldShowMap Debug ===');
    debugPrint('Order ID: ${order.id}');
    debugPrint('Is Delivery: $isDelivery (luxuryOptionName: ${order.luxuryOptionName})');
    debugPrint('Has Driver: $hasDriver (driverId: ${vendor?.driverId})');
    debugPrint('Dispatcher Status: $dispatcherStatus');
    debugPrint('Dispatch URL: ${vendor?.dispatchTrakingUrl}');
    debugPrint('Has Dispatch URL: $hasDispatchUrl');
    
    // Check order status
    final orderStatus = vendor?.orderStatus ?? order.orderStatus;
    String? statusTitle;
    if (orderStatus is OrderStatusModel) {
      statusTitle = orderStatus.currentStatus?.title;
    } else if (orderStatus is OrderStatusDetailModel) {
      statusTitle = orderStatus.currentStatus?.title;
    }
    debugPrint('Order Status: $statusTitle');
    
    // Show map for active orders with dispatch URL or dispatcher status
    final shouldShow = isDelivery && (hasDispatchUrl || dispatcherStatus >= 2 || hasDriver);
    debugPrint('Should show map: $shouldShow');
    debugPrint('===========================');

    return shouldShow;
  }

  bool _shouldShowDriverInfo(OrderModel order) {
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final orderStatus = vendor?.orderStatus ?? order.orderStatus;
    final currentStatus =
        orderStatus is OrderStatusModel ? orderStatus.currentStatus : null;
    final isDelivered = currentStatus?.title == 'Delivered';
    final isActive = !isDelivered && currentStatus?.title != 'Cancelled';
    final isDelivery = order.luxuryOptionName == 'Delivery';
    final hasDispatcherStatus = vendor?.dispatcherStatusOptionId != null &&
        vendor!.dispatcherStatusOptionId! > 0;

    // Show driver info for active delivery orders that have been accepted
    return isActive &&
        isDelivery &&
        (hasDispatcherStatus || vendor?.driverId != null);
  }

  bool _shouldShowOrderTimeline(OrderModel order) {
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    // Show timeline if we have dispatcher status updates or order status history
    return (vendor?.vendorDispatcherStatus?.isNotEmpty ?? false) ||
        (vendor?.allStatus?.isNotEmpty ?? false);
  }

  bool _shouldShowStepIndicators(OrderModel order) {
    // Show step indicators if order is not placed/rejected and has dispatch URL
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final orderStatus = vendor?.orderStatus ?? order.orderStatus;
    final currentStatus =
        orderStatus is OrderStatusModel ? orderStatus.currentStatus : null;
    
    return currentStatus?.title != 'Rejected' &&
        currentStatus?.title != 'Placed' &&
        vendor?.dispatchTrakingUrl != null;
  }

  bool _shouldShowOrderStatus(OrderModel order) {
    // Show expandable order status list like React Native
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    return vendor?.dispatchTrakingUrl != null && 
           _driverTrackingData != null &&
           _driverTrackingData!['tasks'] != null;
  }

  bool _shouldShowWebView(OrderModel order) {
    final vendor =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final orderStatus = vendor?.orderStatus ?? order.orderStatus;
    final currentStatus =
        orderStatus is OrderStatusModel ? orderStatus.currentStatus : null;
    final isDelivered = currentStatus?.title == 'Delivered';
    final isActive = !isDelivered && currentStatus?.title != 'Cancelled';

    // Show WebView section for active orders (even if URL is not yet available)
    debugPrint(
        'Should show WebView section: $isActive, URL: ${vendor?.dispatchTrakingUrl}');
    return isActive;
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

  IconData _getPaymentIcon(String paymentMethod) {
    if (paymentMethod.toLowerCase().contains('cash')) {
      return Icons.money;
    } else if (paymentMethod.toLowerCase().contains('card')) {
      return Icons.credit_card;
    } else if (paymentMethod.toLowerCase().contains('wallet')) {
      return Icons.account_balance_wallet;
    }
    return Icons.payment;
  }

  void _callVendor(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openTrackingUrl() async {
    if (trackingUrl == null) return;

    final Uri url = Uri.parse(trackingUrl!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showRatingModal(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingModal(
        order: order,
        onSubmit: (rating, review) {
          // Submit rating
          _submitRating(order, rating, review);
        },
      ),
    );
  }

  void _submitRating(OrderModel order, int rating, String review) async {
    // TODO: Implement rating submission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateInvoice(OrderModel order) async {
    // TODO: Implement invoice generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice will be sent to your email'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Build LaLaMove WebView - matches React Native
  Widget _buildLalaMoveWebView() {
    return Container(
      height: MediaQuery.of(context).size.height / 1.8,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(lalaMoveUrl!)),
      ),
    );
  }

  // Build Step Indicators - matches React Native StepIndicators component
  Widget _buildStepIndicators(OrderModel order) {
    final vendor = order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    if (vendor == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.h),
      child: StepIndicatorWidget(
        labels: [],  // Empty labels like React Native
        currentPosition: currentPosition ?? 0,
      ),
    );
  }

  // Build Order Status List - matches React Native expandable order status
  Widget _buildOrderStatusList(OrderModel order) {
    final tasks = _driverTrackingData?['tasks'] as List?;
    if (tasks == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => arrowUp = !arrowUp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORDER STATUS',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Transform.rotate(
                  angle: arrowUp ? 0 : 3.14159,
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (arrowUp) ...[
            SizedBox(height: 16.h),
            ...tasks.map((task) => _buildTaskStatusItem(task)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskStatusItem(Map<String, dynamic> task) {
    final isCompleted = task['task_status'] == '4';
    final tasks = _driverTrackingData?['tasks'] as List?;
    final isLastItem = tasks != null && tasks.indexOf(task) >= tasks.length - 1;
    
    return Column(
      children: [
        Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? AppColors.primaryColor : Colors.grey,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['address'] ?? '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black87,
                    ),
                  ),
                  if (task['task_status'] != '0') 
                    Text(
                      _getTaskStatusTitle(task),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
            if ((task['task_status'] == '1' && task['task_type_id'] == 1) || 
                task['task_status'] == '4')
              Text(
                DateFormat.jm().format(DateTime.parse(task['updated_at'])),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
        if (!isLastItem)
          Container(
            margin: EdgeInsets.only(left: 8.w),
            height: 20.h,
            width: 2.w,
            color: isCompleted ? AppColors.primaryColor : Colors.grey[300],
          ),
      ],
    );
  }

  String _getTaskStatusTitle(Map<String, dynamic> task) {
    // Match React Native orderStatusTitle function
    switch (task['task_type_id']) {
      case 1:
        return 'Pickup';
      case 2:
        return 'Delivery';
      default:
        return '';
    }
  }
}

// Extension for RefreshControl widget
class RefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RefreshControl({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}
