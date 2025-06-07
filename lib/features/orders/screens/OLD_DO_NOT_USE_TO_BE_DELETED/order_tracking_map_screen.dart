import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';

class OrderTrackingMapScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingMapScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingMapScreen> createState() => _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState extends State<OrderTrackingMapScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Map configuration
  static const double _defaultZoom = 14.0;

  // Abu Dhabi default location
  static const LatLng _defaultLocation = LatLng(24.4539, 54.3773);

  // Marker icons
  BitmapDescriptor? _vendorIcon;
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _driverIcon;

  // Route information
  String _distance = '';
  String _duration = '';
  List<LatLng> _routePoints = [];

  // Driver simulation (remove in production when real driver API is available)
  int _driverSimulationIndex = 0;
  Timer? _driverAnimationTimer;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _loadOrderDetails();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _driverAnimationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 10 seconds for real-time tracking
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadOrderDetails(showLoading: false);
      _updateDriverLocation(); // Update driver position
    });
  }

  Future<void> _loadCustomMarkers() async {
    // Load custom marker icons
    _vendorIcon = await _createCustomMarkerBitmap(
      Icons.restaurant,
      Colors.orange,
      'Restaurant',
    );
    _userIcon = await _createCustomMarkerBitmap(
      Icons.home,
      Colors.green,
      'Delivery',
    );
    _driverIcon = await _createCustomMarkerBitmap(
      Icons.two_wheeler, // Motorcycle/bike icon
      Colors.blue,
      'Driver',
    );
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    IconData icon,
    Color color,
    String label,
  ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 150.0;

    // Draw circle background
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw white circle inside
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 10, paint);

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 70,
        fontFamily: icon.fontFamily,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  void _loadOrderDetails({bool showLoading = true}) {
    final orderProvider = context.read<OrderProvider>();
    final orderIdInt = int.tryParse(widget.orderId);

    if (orderIdInt != null) {
      final cachedOrder = orderProvider.findOrderById(orderIdInt);
      if (cachedOrder != null) {
        final actualOrderId = cachedOrder.orderId ?? orderIdInt;
        final vendorId = cachedOrder.vendorId;

        orderProvider
            .loadOrderDetails(
          orderId: actualOrderId,
          vendorId: vendorId,
          showLoading: showLoading,
        )
            .then((_) {
          if (orderProvider.currentOrderDetails != null) {
            _updateMapWithOrderData(orderProvider.currentOrderDetails!);
          }
        });
      } else {
        orderProvider.loadOrderDetails(
            orderId: orderIdInt, showLoading: showLoading);
      }
    }
  }

  void _updateMapWithOrderData(OrderModel order) {
    if (!mounted) return;

    final markers = <Marker>{};
    final bounds = <LatLng>[];

    // Get vendor details
    final vendorDetail =
        order.vendors?.isNotEmpty == true ? order.vendors!.first : null;
    final vendor = vendorDetail?.vendor ?? order.vendor;

    // Add vendor marker
    if (vendor != null && vendor.latitude != null && vendor.longitude != null) {
      final vendorLocation = LatLng(
        double.parse(vendor.latitude!),
        double.parse(vendor.longitude!),
      );

      markers.add(Marker(
        markerId: const MarkerId('vendor'),
        position: vendorLocation,
        icon: _vendorIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: vendor.name,
          snippet: vendor.address ?? 'Restaurant',
        ),
      ));
      bounds.add(vendorLocation);
    }

    // Add user/delivery marker
    if (order.address != null &&
        order.address!.latitude != null &&
        order.address!.longitude != null) {
      final userLocation = LatLng(
        order.address!.latitude!,
        order.address!.longitude!,
      );

      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: userLocation,
        icon: _userIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Delivery Location',
          snippet: order.address!.address,
        ),
      ));
      bounds.add(userLocation);
    }

    // Add driver marker if available
    if (vendorDetail?.driverId != null &&
        vendorDetail!.dispatcherStatusOptionId != null) {
      // First check if we have real driver location from tracking API
      LatLng? driverLocation;

      // TODO: Call driver tracking API here
      // For now, use mock location
      if (bounds.length >= 2) {
        final driverLat = (bounds[0].latitude + bounds[1].latitude) / 2;
        final driverLng = (bounds[0].longitude + bounds[1].longitude) / 2;
        driverLocation = LatLng(driverLat, driverLng);
      }

      if (driverLocation != null) {
        markers.add(Marker(
          markerId: const MarkerId('driver'),
          position: driverLocation,
          icon: _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Delivery Executive',
            snippet: _getDriverStatus(vendorDetail.dispatcherStatusOptionId!),
          ),
        ));
        bounds.add(driverLocation);
      }
    }

    // Update markers
    setState(() {
      _markers = markers;
    });

    // Animate camera to show all markers
    if (bounds.isNotEmpty && _mapController != null) {
      _fitMapToBounds(bounds);
    }

    // Draw route polyline with distance calculation
    if (bounds.length >= 2) {
      _drawRouteWithDistance(bounds);
    }
  }

  void _fitMapToBounds(List<LatLng> bounds) {
    if (bounds.isEmpty || _mapController == null) return;

    if (bounds.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(bounds.first, _defaultZoom),
      );
    } else {
      double minLat = bounds.first.latitude;
      double maxLat = bounds.first.latitude;
      double minLng = bounds.first.longitude;
      double maxLng = bounds.first.longitude;

      for (final point in bounds) {
        minLat = minLat > point.latitude ? point.latitude : minLat;
        maxLat = maxLat < point.latitude ? point.latitude : maxLat;
        minLng = minLng > point.longitude ? point.longitude : minLng;
        maxLng = maxLng < point.longitude ? point.longitude : maxLng;
      }

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.w, // padding
        ),
      );
    }
  }

  String _getDriverStatus(int statusId) {
    switch (statusId) {
      case 1:
        return 'Order Accepted';
      case 2:
        return 'Driver Assigned';
      case 3:
        return 'Heading to Restaurant';
      case 4:
        return 'Arrived at Restaurant';
      case 5:
        return 'Order Picked Up';
      case 6:
        return 'Order Delivered';
      default:
        return 'In Progress';
    }
  }

  void _updateDriverLocation() {
    // This simulates driver movement for demo purposes
    // In production, this would use real driver location from API
    if (!mounted || _markers.isEmpty) return;

    final vendor =
        context.read<OrderProvider>().currentOrderDetails?.vendors?.first;
    if (vendor == null || vendor.dispatcherStatusOptionId == null) return;

    // Find vendor and user markers
    Marker? vendorMarker;
    Marker? userMarker;

    for (final marker in _markers) {
      if (marker.markerId.value == 'vendor') vendorMarker = marker;
      if (marker.markerId.value == 'user') userMarker = marker;
    }

    if (vendorMarker == null || userMarker == null) return;

    // Calculate simulated driver position based on status
    final progress = (vendor.dispatcherStatusOptionId! - 1) / 5.0;
    final lat = vendorMarker.position.latitude +
        (userMarker.position.latitude - vendorMarker.position.latitude) *
            progress;
    final lng = vendorMarker.position.longitude +
        (userMarker.position.longitude - vendorMarker.position.longitude) *
            progress;

    final driverPosition = LatLng(lat, lng);

    // Update driver marker
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPosition,
          icon: _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Delivery Executive',
            snippet: _getDriverStatus(vendor.dispatcherStatusOptionId!),
          ),
          anchor: const Offset(0.5, 0.5),
        ),
      );

      // Update route
      _drawRouteWithDistance([driverPosition, userMarker!.position]);
    });
  }

  void _drawRouteWithDistance(List<LatLng> points) {
    if (points.length < 2) return;

    // Calculate distance
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDistance(points[i], points[i + 1]);
    }

    setState(() {
      _distance = '${(totalDistance / 1000).toStringAsFixed(1)} km';
      _duration =
          '${(totalDistance / 1000 * 2.5).toStringAsFixed(0)} min'; // Rough estimate
      _routePoints = points;

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primaryColor,
          width: 5,
          patterns: [],
        ),
      };
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // meters
    double lat1Rad = start.latitude * (math.pi / 180);
    double lat2Rad = end.latitude * (math.pi / 180);
    double deltaLatRad = (end.latitude - start.latitude) * (math.pi / 180);
    double deltaLngRad = (end.longitude - start.longitude) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  Future<void> _openExternalTracking(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open tracking URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => _loadOrderDetails(),
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoadingOrderDetails) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = orderProvider.currentOrderDetails;
          if (order == null) {
            return _buildNoOrderView();
          }

          final vendorDetail =
              order.vendors?.isNotEmpty == true ? order.vendors!.first : null;

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _defaultLocation,
                  zoom: _defaultZoom,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _updateMapWithOrderData(order);
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                compassEnabled: true,
                mapType: MapType.normal,
                buildingsEnabled: true,
                trafficEnabled: false,
                indoorViewEnabled: false,
                tiltGesturesEnabled: true,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                liteModeEnabled: false,
              ),

              // Order status card
              Positioned(
                top: 16.h,
                left: 16.w,
                right: 16.w,
                child: _buildOrderStatusCard(order, vendorDetail),
              ),

              // Bottom action sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomSheet(order, vendorDetail),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoOrderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Order not found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: 'Go Back',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(
      OrderModel order, OrderVendorDetailModel? vendorDetail) {
    final hasDriver = vendorDetail?.driverId != null;
    final statusMessage = vendorDetail?.vendorDispatcherStatus?.isNotEmpty ==
            true
        ? vendorDetail!.vendorDispatcherStatus!.last.statusData?.driverStatus
        : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   children: [
            //     Icon(
            //       hasDriver ? Icons.two_wheeler : Icons.schedule,
            //       color: hasDriver ? Colors.green : Colors.orange,
            //       size: 24.sp,
            //     ),
            //     SizedBox(width: 8.w),
            //     Expanded(
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             hasDriver
            //                 ? 'Driver on the way'
            //                 : 'Looking for delivery partner',
            //             style: TextStyle(
            //               fontSize: 16.sp,
            //               fontWeight: FontWeight.w600,
            //               color: Colors.black87,
            //             ),
            //           ),
            //           if (hasDriver && (_distance.isNotEmpty || _duration.isNotEmpty)) ...[
            //             SizedBox(height: 4.h),
            //             Row(
            //               children: [
            //                 if (_distance.isNotEmpty) ...[
            //                   Icon(
            //                     Icons.straighten,
            //                     size: 14.sp,
            //                     color: Colors.grey[600],
            //                   ),
            //                   SizedBox(width: 4.w),
            //                   Text(
            //                     _distance,
            //                     style: TextStyle(
            //                       fontSize: 12.sp,
            //                       color: Colors.grey[600],
            //                     ),
            //                   ),
            //                 ],
            //                 if (_distance.isNotEmpty && _duration.isNotEmpty)
            //                   SizedBox(width: 12.w),
            //                 if (_duration.isNotEmpty) ...[
            //                   Icon(
            //                     Icons.access_time,
            //                     size: 14.sp,
            //                     color: Colors.grey[600],
            //                   ),
            //                   SizedBox(width: 4.w),
            //                   Text(
            //                     _duration,
            //                     style: TextStyle(
            //                       fontSize: 12.sp,
            //                       color: Colors.grey[600],
            //                     ),
            //                   ),
            //                 ],
            //               ],
            //             ),
            //           ],
            //         ],
            //       ),
            //     ),
            //   ],
            // ),

            if (statusMessage != null) ...[
              SizedBox(height: 8.h),
              Text(
                statusMessage,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
            SizedBox(height: 12.h),
            LinearProgressIndicator(
              value: _getProgressValue(vendorDetail?.dispatcherStatusOptionId),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getProgressValue(int? statusId) {
    if (statusId == null) return 0.1;
    return (statusId / 6).clamp(0.1, 1.0);
  }

  Widget _buildBottomSheet(
      OrderModel order, OrderVendorDetailModel? vendorDetail) {
    final vendorName =
        vendorDetail?.vendorName ?? order.vendor?.name ?? 'Restaurant';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order info
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
                    Text(
                      'AED ${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Restaurant info
                if (order.vendor != null || vendorDetail != null) ...[
                  _buildInfoRow(
                    Icons.restaurant,
                    'Restaurant',
                    vendorName,
                  ),
                  SizedBox(height: 12.h),
                ],

                // Delivery address
                if (order.address != null) ...[
                  _buildInfoRow(
                    Icons.location_on,
                    'Delivery to',
                    order.address!.address,
                  ),
                  SizedBox(height: 12.h),
                ],

                // Estimated time
                _buildInfoRow(
                  Icons.access_time,
                  'Estimated time',
                  _duration.isNotEmpty ? _duration : '30-40 minutes',
                ),

                SizedBox(height: 20.h),

                // Action buttons
                if (vendorDetail?.driverId != null) ...[
                  CustomButton(
                    text: 'Contact Driver',
                    onPressed: () {
                      // In production, this would open driver contact options
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driver contact feature coming soon'),
                        ),
                      );
                    },
                    icon: Icon(Icons.phone, size: 20.sp),
                    backgroundColor: AppColors.primaryColor,
                    textColor: Colors.white,
                  ),
                  SizedBox(height: 12.h),
                ],

                // Contact driver button (when driver is assigned)
                if (vendorDetail?.driverId != null) ...[
                  OutlinedButton(
                    onPressed: () {
                      // Contact driver functionality
                      // In production, this would initiate a call or chat with the driver
                      // For now, show a message that the feature is being implemented
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Contact driver feature will be available soon'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Contact Driver',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: Colors.grey[600],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
