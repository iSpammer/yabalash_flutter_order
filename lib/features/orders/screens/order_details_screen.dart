import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../services/order_tracking_service.dart';
import '../services/google_maps_service.dart';
import '../services/dispatch_tracking_service.dart';
import '../widgets/driver_card_widget.dart';
import '../widgets/driver_contact_actions.dart';
import '../widgets/driver_delivery_details.dart';
import '../widgets/driver_status_widget.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/order_price_breakdown.dart';

// Simple utility class for formatting - matching React Native tokenConverterPlusCurrencyNumberFormater
class AppUtils {
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}


class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final String trackingId;

  const OrderDetailsScreen(
      {super.key, required this.orderId, required this.trackingId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
  // Services
  final OrderTrackingService _trackingService = OrderTrackingService();
  final DispatchTrackingService _dispatchService = DispatchTrackingService();

  // Match React Native state variables
  late Timer _refreshTimer;
  GoogleMapController? _mapController;

  // State variables matching React Native OrderDetail.js
  bool _isLoading = true;
  bool _arrowUp = false; // Match React Native arrowUp state
  String? _lalaMoveUrl;
  Map<String, dynamic>?
      _driverStatus; // Matches React Native driverStatus from order_data
  OrderTracking? _orderTracking; // Real-time tracking data
  DriverLocationData? _dispatchDriverData; // Real-time dispatch GPS data
  String? _currentTrackingUrl; // Store current tracking URL

  // Map markers and polylines
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Driver animation - matching React Native animateDriver
  LatLng? _currentDriverPosition;
  double _driverHeading = 0.0;

  // Custom markers
  BitmapDescriptor? _driverIcon;

  @override
  void initState() {
    super.initState();

    // Decode the tracking URL if provided
    if (widget.trackingId != 'none' && widget.trackingId.isNotEmpty) {
      try {
        _currentTrackingUrl = Uri.decodeComponent(widget.trackingId);
        debugPrint('=== Tracking URL from Route ===');
        debugPrint('Encoded: ${widget.trackingId}');
        debugPrint('Decoded: $_currentTrackingUrl');

        // Validate it's a dispatch URL
        if (_currentTrackingUrl != null &&
            _currentTrackingUrl!
                .contains('dispatch.yabalash.com/order/tracking/')) {
          debugPrint('✅ Valid dispatch tracking URL provided');
        }
      } catch (e) {
        debugPrint('Error decoding tracking URL: $e');
      }
    }

    _loadOrderDetails();
    _startRealTimeUpdates();
    _loadCustomMarkers();

    // If we have a tracking URL from the route, fetch driver location immediately
    if (_currentTrackingUrl != null && _currentTrackingUrl!.isNotEmpty) {
      debugPrint('🚗 Fetching driver location from provided URL...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _fetchDispatchDriverLocation();
      });
    }
  }

  Future<void> _loadCustomMarkers() async {
    try {
      // Load custom motorcycle marker
      _driverIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/motorcycle_marker.png',
      );
      debugPrint('✅ Custom motorcycle marker loaded');
    } catch (e) {
      debugPrint('Error loading custom markers: $e');
      // Fallback to default blue marker
      _driverIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  // Match React Native useInterval with 5-second polling
  void _startRealTimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _getOrders();
      }
    });
  }

  // Match React Native getOrders function - Only update driver location, not entire page
  void _getOrders() {
    debugPrint('\n=== Periodic Update (5 seconds) ===');
    debugPrint('Current tracking URL: $_currentTrackingUrl');
    debugPrint('Has driver position: ${_currentDriverPosition != null}');

    // Don't reload order details - just update driver location
    // This prevents the entire page from refreshing

    // Fetch dispatch GPS data only
    if (_currentTrackingUrl != null) {
      debugPrint('🚗 Fetching real-time driver location...');
      _fetchDispatchDriverLocation();
    } else {
      debugPrint('⚠️ No tracking URL available for real-time updates');
    }
  }

  // Match React Native _getOrderDetailScreen function logic
  Future<void> _loadOrderDetails({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final orderProvider = context.read<OrderProvider>();
      final orderIdInt = int.tryParse(widget.orderId) ?? 0;

      // Match React Native ID mapping logic
      final cachedOrder = orderProvider.findOrderById(orderIdInt);
      if (cachedOrder != null) {
        final actualOrderId = cachedOrder.orderId ?? orderIdInt;
        final vendorId = cachedOrder.vendorId;

        debugPrint(
            'Loading order details: orderId=$actualOrderId, vendorId=$vendorId');

        await orderProvider.loadOrderDetails(
          orderId: actualOrderId,
          vendorId: vendorId,
        );

        // Also fetch real-time tracking data
        final trackingResponse = await _trackingService.getOrderTracking(
          actualOrderId,
          vendorId ?? 0,
        );

        if (trackingResponse.success && trackingResponse.data != null) {
          setState(() {
            _orderTracking = trackingResponse.data;
          });
        }

        final order = orderProvider.currentOrderDetails;
        if (order?.vendors?.isNotEmpty == true) {
          final vendor = order!.vendors!.first;

          // Enhanced debug logging
          debugPrint('=== Order Details Loaded ===');
          debugPrint('Order Number: ${order.orderNumber}');
          debugPrint('Order loaded with ${order.vendors!.length} vendors');
          debugPrint('Vendor: ${vendor.vendorName}');
          debugPrint(
              'Vendor Location: lat=${vendor.vendor?.latitude}, lng=${vendor.vendor?.longitude}');
          debugPrint(
              'Delivery Location: lat=${order.address?.latitude}, lng=${order.address?.longitude}');
          debugPrint('Agent Location: ${vendor.agentLocation}');
          debugPrint('Tasks: ${vendor.tasks}');
          debugPrint('Dispatcher Status: ${vendor.dispatcherStatusOptionId}');
          debugPrint('Tracking URL: ${vendor.dispatchTrakingUrl}');

          // Store tracking URL for dispatch tracking (only if not already set from route)
          if (_currentTrackingUrl == null || _currentTrackingUrl!.isEmpty) {
            _currentTrackingUrl = vendor.dispatchTrakingUrl;
            debugPrint(
                '📍 Using tracking URL from order data: $_currentTrackingUrl');
          } else {
            debugPrint(
                '📍 Using tracking URL from route parameter: $_currentTrackingUrl');
          }

          // Enhanced tracking URL logging
          debugPrint('=== Tracking URL Analysis ===');
          debugPrint('Current tracking URL: $_currentTrackingUrl');
          debugPrint(
              'Tracking URL available: ${_currentTrackingUrl != null && _currentTrackingUrl!.isNotEmpty}');
          if (_currentTrackingUrl != null && _currentTrackingUrl!.isNotEmpty) {
            debugPrint('✅ Order has live tracking capability');
            // Test if this matches the Python script pattern
            if (_currentTrackingUrl!
                .contains('dispatch.yabalash.com/order/tracking/')) {
              debugPrint(
                  '✅ Tracking URL matches expected pattern for dispatch API');
              final convertedUrl = _currentTrackingUrl!
                  .replaceFirst('/order/tracking/', '/order-details/tracking/');
              debugPrint('Converted API URL: $convertedUrl');

              // Immediately fetch driver location (only if not already fetched from route)
              if (widget.trackingId == 'none' || widget.trackingId.isEmpty) {
                debugPrint(
                    '🚗 Fetching initial driver location from order data...');
                _fetchDispatchDriverLocation();
              }
            } else {
              debugPrint(
                  '⚠️ Tracking URL has different pattern: $_currentTrackingUrl');
            }
          } else {
            debugPrint('❌ No tracking URL available for this order');
          }
          debugPrint('=============================');

          // Use tracking data if available
          if (_orderTracking != null) {
            debugPrint('=== Real-time Tracking Data ===');
            debugPrint(
                'Driver Location: lat=${_orderTracking!.driverLat}, lng=${_orderTracking!.driverLng}');
            debugPrint('Driver Heading: ${_orderTracking!.driverHeading}');
            debugPrint('Status: ${_orderTracking!.statusText}');
            debugPrint('ETA: ${_orderTracking!.estimatedTime}');
          }

          // Check driver status (matches React Native driverStatus logic from order_data)
          // In React Native: driverStatus = res?.data?.order_data
          // Since order_data is not in our model, we use vendor data with agent_location
          if (vendor.agentLocation != null ||
              _orderTracking?.hasDriver == true) {
            setState(() {
              _driverStatus = {
                'agent_location':
                    vendor.agentLocation ?? _orderTracking?.agentLocation,
                'tasks': vendor.tasks ?? _orderTracking?.tasks,
                'order': {'id': order.id, 'order_number': order.orderNumber},
              };
            });

            // Update driver position from tracking data if available
            if (_orderTracking?.hasDriver == true) {
              _updateDriverPositionFromTracking();
            } else if (vendor.agentLocation != null) {
              _updateDriverPosition(vendor.agentLocation!);
            }
          }

          // Update markers after order is loaded
          _updateMapMarkers();

          // Check for LaLaMove URL (matches React Native lalaMoveUrl logic)
          // Note: These fields might not exist in current model, using placeholders
          // if (vendor.lalamoveTrackingUrl != null && vendor.shippingDeliveryType == 'L') {
          //   setState(() {
          //     _lalaMoveUrl = vendor.lalamoveTrackingUrl;
          //   });
          // }
        }
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
    } finally {
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Match React Native animate function
  void _updateDriverPosition(Map<String, dynamic> agentLocation) {
    debugPrint('=== Updating Driver Position ===');
    debugPrint('Agent location data: $agentLocation');

    final lat = double.tryParse(agentLocation['lat']?.toString() ?? '');
    final lng = double.tryParse(agentLocation['lng']?.toString() ?? '') ??
        double.tryParse(agentLocation['long']?.toString() ?? '');
    final heading =
        double.tryParse(agentLocation['heading_angle']?.toString() ?? '0') ??
            0.0;

    debugPrint('Parsed values: lat=$lat, lng=$lng, heading=$heading');

    if (lat != null && lng != null) {
      final newPosition = LatLng(lat, lng);

      if (mounted) {
        setState(() {
          _currentDriverPosition = newPosition;
          _driverHeading = heading;
        });

        _updateMapMarkers();

        // Auto-center map on driver if this is the first position update
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(newPosition),
          );
        }
      }
    } else {
      debugPrint('Failed to parse driver location');
    }
  }

  // Update driver position from real-time tracking data
  void _updateDriverPositionFromTracking() {
    if (_orderTracking == null || !_orderTracking!.hasDriver) return;

    debugPrint('=== Updating Driver Position from Tracking ===');
    debugPrint(
        'Driver lat: ${_orderTracking!.driverLat}, lng: ${_orderTracking!.driverLng}');
    debugPrint('Driver heading: ${_orderTracking!.driverHeading}');

    final newPosition =
        LatLng(_orderTracking!.driverLat!, _orderTracking!.driverLng!);

    if (mounted) {
      setState(() {
        _currentDriverPosition = newPosition;
        _driverHeading = _orderTracking!.driverHeading ?? 0.0;
      });

      _updateMapMarkers();

      // Animate map to show driver
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(newPosition),
        );
      }
    }
  }

  // Fetch real-time GPS data from dispatch tracking URL
  Future<void> _fetchDispatchDriverLocation() async {
    if (_currentTrackingUrl == null) return;

    try {
      debugPrint('=== Fetching Dispatch Driver Location ===');
      debugPrint('Current tracking URL: $_currentTrackingUrl');

      final dispatchData =
          await _dispatchService.getDriverLocation(_currentTrackingUrl);

      if (dispatchData != null) {
        debugPrint('Dispatch data received: ${dispatchData.keys.toList()}');

        // Check for agent_location in the response
        if (dispatchData['agent_location'] != null) {
          final agentLocation =
              dispatchData['agent_location'] as Map<String, dynamic>;
          debugPrint('Agent location found: $agentLocation');

          // Parse coordinates directly from agent_location
          final lat = double.tryParse(agentLocation['lat']?.toString() ?? '');
          final lng =
              double.tryParse(agentLocation['long']?.toString() ?? '') ??
                  double.tryParse(agentLocation['lng']?.toString() ?? '');

          if (lat != null && lng != null) {
            debugPrint('=== Dispatch GPS Data Parsed ===');
            debugPrint('Driver lat: $lat, lng: $lng');
            debugPrint('Updated at: ${agentLocation['updated_at']}');
            debugPrint('Battery: ${agentLocation['battery_level']}%');
            debugPrint('all info: ${dispatchData}');

            // Parse the full dispatch data using the service method
            _dispatchDriverData = DispatchTrackingService.parseDriverLocation(dispatchData);
            
            setState(() {
              _currentDriverPosition = LatLng(lat, lng);
            });

            // Update markers after setting position
            _updateMapMarkers();

            // Don't animate camera every update - it's jarring
            // Only animate on first driver location or if driver moved significantly
            bool shouldAnimateCamera = false;
            if (_dispatchDriverData == null) {
              // First driver location
              shouldAnimateCamera = true;
            } else if (_dispatchDriverData!.lat != null &&
                _dispatchDriverData!.lng != null) {
              // Check if driver moved more than ~100 meters
              final prevLat = _dispatchDriverData!.lat!;
              final prevLng = _dispatchDriverData!.lng!;
              final distance = _calculateDistance(prevLat, prevLng, lat, lng);
              if (distance > 0.1) {
                // 0.1 km = 100 meters
                shouldAnimateCamera = true;
              }
            }

            if (_mapController != null && shouldAnimateCamera) {
              await _mapController!.animateCamera(
                CameraUpdate.newLatLng(_currentDriverPosition!),
              );
            }

            debugPrint('✅ Driver marker should now be visible on map');
          } else {
            debugPrint('❌ Failed to parse coordinates from agent_location');
          }
        } else {
          debugPrint('❌ No agent_location in dispatch response');
        }
      } else {
        debugPrint('❌ No data received from dispatch API');
      }
    } catch (e) {
      debugPrint('❌ Error in _fetchDispatchDriverLocation: $e');
      // Continue without dispatch data - use regular order data
    }
  }

  // Match React Native marker update logic
  void _updateMapMarkers() {
    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrderDetails;

    if (order?.vendors?.isNotEmpty != true) {
      debugPrint('No vendors available for markers');
      return;
    }

    final vendor = order!.vendors!.first;
    Set<Marker> newMarkers = {};

    debugPrint('=== Updating Map Markers ===');
    debugPrint('Order ID: ${order.id}');
    debugPrint('Vendor: ${vendor.vendor?.name}');
    debugPrint('Order Address: ${order.address?.toString()}');

    // Check if we have tasks data like React Native
    final tasks = _driverStatus?['tasks'] ?? vendor.tasks;
    debugPrint('Tasks data: ${tasks?.length ?? 0} tasks');
    if (tasks != null) {
      for (int i = 0; i < tasks.length; i++) {
        debugPrint('Task $i: ${tasks[i]}');
      }
    }

    // Add pickup location marker (matches React Native tasks[0])
    if (tasks != null && tasks.isNotEmpty && tasks[0] != null) {
      final task0 = tasks[0];
      final lat = double.tryParse(task0['latitude']?.toString() ?? '');
      final lng = double.tryParse(task0['longitude']?.toString() ?? '');
      debugPrint('Task 0 (Pickup) location: lat=$lat, lng=$lng');
      if (lat != null && lng != null) {
        newMarkers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(lat, lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: task0['address'] ?? 'Pickup Location',
          ),
        ));
      }
    } else if (vendor.vendor?.latitude != null &&
        vendor.vendor?.longitude != null) {
      // Fallback: Use vendor location if no tasks
      final lat = double.tryParse(vendor.vendor!.latitude!.toString());
      final lng = double.tryParse(vendor.vendor!.longitude!.toString());
      debugPrint('Restaurant location (fallback): lat=$lat, lng=$lng');
      debugPrint('Vendor name: ${vendor.vendor?.name}');
      if (lat != null && lng != null) {
        newMarkers.add(Marker(
          markerId: const MarkerId('restaurant'),
          position: LatLng(lat, lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: vendor.vendor?.name ?? 'Restaurant',
          ),
        ));
      }
    } else {
      debugPrint('No pickup/restaurant location available');
      debugPrint('Vendor data: ${vendor.vendor?.toJson()}');
    }

    // Add delivery location marker (matches React Native tasks[1])
    if (tasks != null && tasks.length > 1 && tasks[1] != null) {
      final task1 = tasks[1];
      final lat = double.tryParse(task1['latitude']?.toString() ?? '');
      final lng = double.tryParse(task1['longitude']?.toString() ?? '');
      debugPrint('Task 1 (Delivery) location: lat=$lat, lng=$lng');
      if (lat != null && lng != null) {
        newMarkers.add(Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(lat, lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: task1['address'] ?? 'Delivery Location',
          ),
        ));
      }
    } else if (order.address?.latitude != null &&
        order.address?.longitude != null) {
      // Fallback: Use order address if no tasks
      debugPrint(
          'Delivery location (fallback): lat=${order.address!.latitude}, lng=${order.address!.longitude}');
      newMarkers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(order.address!.latitude!, order.address!.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Delivery Location',
        ),
      ));
    } else {
      debugPrint('No delivery location available');
    }

    // Add driver marker if available (matches React Native agent_location)
    if (_currentDriverPosition != null) {
      debugPrint('=== Adding Driver Marker ===');
      debugPrint('Driver location: $_currentDriverPosition');
      debugPrint('Driver heading: $_driverHeading');

      // Build driver info window
      String driverTitle = 'Driver';
      String driverSnippet = '';

      // Use dispatch driver data if available
      if (_dispatchDriverData != null) {
        driverTitle = _dispatchDriverData!.driverName ?? 'Your Driver';
        driverSnippet = 'Tap for details';
        debugPrint('Using dispatch driver name: $driverTitle');
      } else if (_orderTracking?.driverInfo != null) {
        driverTitle = _orderTracking!.driverInfo!.name;
        driverSnippet = _orderTracking!.statusText;
        debugPrint('Using order tracking driver name: $driverTitle');
      }

      // Create driver marker with motorcycle icon
      final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: _currentDriverPosition!,
        icon: _driverIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        rotation: _driverHeading,
        infoWindow: InfoWindow(
          title: driverTitle,
          snippet: driverSnippet,
        ),
        // Make marker always visible
        visible: true,
        zIndex: 999, // Ensure driver marker is on top
        anchor: const Offset(0.5, 0.5), // Center the marker
      );

      newMarkers.add(driverMarker);
      debugPrint('✅ Driver marker added to map');
    } else {
      debugPrint('❌ No driver location available for marker');
    }

    debugPrint('Total markers created: ${newMarkers.length}');
    for (var marker in newMarkers) {
      debugPrint('  - Marker: ${marker.markerId.value} at ${marker.position}');
    }

    // Force UI update with new markers
    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }

    // Update polylines for route (matches React Native MapViewDirections)
    _updatePolylines();

    // If map controller exists and we have markers, update camera
    if (_mapController != null && _markers.isNotEmpty && mounted) {
      // Small delay to ensure markers are rendered
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;

        // If we have a driver, focus on driver
        if (_currentDriverPosition != null) {
          debugPrint('📍 Focusing map on driver position');
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentDriverPosition!, 15.0),
          );
        } else {
          // Otherwise, fit all markers
          debugPrint('📍 Fitting map to all markers');
          _centerMapOnMarkers();
        }
      });
    }
  }

  void _updatePolylines() async {
    // Match React Native MapViewDirections logic
    if (_markers.length < 2) return;

    // Clear existing polylines
    setState(() {
      _polylines.clear();
    });

    // If no driver or tracking data, no need for route
    if (_currentDriverPosition == null) return;

    try {
      // Determine route based on driver status
      LatLng origin = _currentDriverPosition!;
      LatLng destination;

      // Get tracking status or dispatcher status
      final dispatcherStatus = _orderTracking?.dispatcherStatus ??
          context
              .read<OrderProvider>()
              .currentOrderDetails
              ?.vendors
              ?.first
              .dispatcherStatusOptionId;

      if (dispatcherStatus != null && dispatcherStatus < 5) {
        // Driver going to restaurant (status 1-4)
        final restaurantMarker = _markers.firstWhere(
          (m) =>
              m.markerId.value == 'pickup' || m.markerId.value == 'restaurant',
          orElse: () => _markers.first,
        );
        destination = restaurantMarker.position;
      } else {
        // Driver going to customer (status 5+)
        final deliveryMarker = _markers.firstWhere(
          (m) => m.markerId.value == 'delivery',
          orElse: () => _markers.last,
        );
        destination = deliveryMarker.position;
      }

      // Get route from Google Directions API
      final directionsData = await GoogleMapsService.getDirections(
        origin: origin,
        destination: destination,
      );

      if (directionsData != null &&
          directionsData['overview_polyline'] != null) {
        // Decode polyline
        final polylinePoints = PolylinePoints();
        final decodedPoints = polylinePoints.decodePolyline(
          directionsData['overview_polyline']['points'],
        );

        if (decodedPoints.isNotEmpty) {
          final polylineCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          setState(() {
            _polylines.clear();

            // Add shadow polyline for depth effect
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route_shadow'),
                color: Colors.black.withValues(alpha: 0.2),
                width: 7,
                points: polylineCoordinates,
                patterns: [], // Solid line
                zIndex: 1,
              ),
            );

            // Add main route polyline
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: const Color(0xFF2196F3), // Nice blue color
                width: 5,
                points: polylineCoordinates,
                patterns: [], // Solid line
                geodesic: true, // Follow earth's curvature
                jointType: JointType.round, // Round joints
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                zIndex: 2,
              ),
            );
          });
        }
      } else {
        // Fallback to simple line if API fails
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route_fallback'),
              points: [origin, destination],
              color: const Color(0xFF2196F3),
              width: 4,
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10)
              ], // Dashed line for fallback
              geodesic: true,
              jointType: JointType.round,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error updating polylines: $e');
    }
  }

  // Match React Native onCenter function
  void _centerMapOnMarkers() {
    if (_markers.isEmpty || _mapController == null) {
      debugPrint(
          'Cannot center map: markers=${_markers.length}, controller=${_mapController != null}');
      return;
    }

    debugPrint('Centering map on ${_markers.length} markers');
    final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  // Get initial map position based on available data
  LatLng _getInitialMapPosition() {
    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrderDetails;

    debugPrint('=== Getting Initial Map Position ===');

    // Match React Native: use tasks[tasks.length - 2] for initial region
    final tasks = _driverStatus?['tasks'] ?? order?.vendors?.first.tasks;
    if (tasks != null && tasks.isNotEmpty) {
      debugPrint('Tasks available: ${tasks.length} tasks');
      // Use second-to-last task like React Native
      final taskIndex = tasks.length >= 2 ? tasks.length - 2 : 0;
      final task = tasks[taskIndex];
      final lat = double.tryParse(task['latitude']?.toString() ?? '');
      final lng = double.tryParse(task['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        debugPrint(
            'Using task[$taskIndex] for initial map position: lat=$lat, lng=$lng');
        return LatLng(lat, lng);
      }
    }

    // Priority 1: Use delivery address if available
    if (order?.address?.latitude != null && order?.address?.longitude != null) {
      debugPrint(
          'Using delivery address for initial map position: lat=${order!.address!.latitude}, lng=${order.address!.longitude}');
      return LatLng(order.address!.latitude!, order.address!.longitude!);
    }

    // Priority 2: Use vendor location if available
    if (order?.vendors?.isNotEmpty == true) {
      final vendor = order!.vendors!.first;
      if (vendor.vendor?.latitude != null && vendor.vendor?.longitude != null) {
        final lat = double.tryParse(vendor.vendor!.latitude!.toString());
        final lng = double.tryParse(vendor.vendor!.longitude!.toString());
        if (lat != null && lng != null) {
          debugPrint(
              'Using vendor location for initial map position: lat=$lat, lng=$lng');
          return LatLng(lat, lng);
        }
      }
    }

    // Priority 3: Use driver position if available
    if (_currentDriverPosition != null) {
      debugPrint('Using driver location for initial map position');
      return _currentDriverPosition!;
    }

    // Default: Use a reasonable default for your region (not India)
    // You should change this to your actual region's coordinates
    debugPrint('Using default location for initial map position (Dubai)');
    return const LatLng(25.2048, 55.2708); // Dubai coordinates
  }

  // Calculate distance between two coordinates in kilometers
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = math.min(minLat, pos.latitude);
      maxLat = math.max(maxLat, pos.latitude);
      minLng = math.min(minLng, pos.longitude);
      maxLng = math.max(maxLng, pos.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // Match React Native showMapDriver logic
  bool _shouldShowMap() {
    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrderDetails;

    if (order?.vendors?.isNotEmpty != true) return false;

    final vendor = order!.vendors!.first;

    // For testing, always show map for now
    debugPrint('=== Should Show Map Debug ===');
    debugPrint('Has vendors: ${order.vendors?.isNotEmpty}');
    debugPrint('Vendor tasks: ${vendor.tasks}');
    debugPrint('Dispatcher status: ${vendor.dispatcherStatusOptionId}');
    debugPrint('Order status: ${order.statusId}');

    // Show map for active orders (not delivered or cancelled)
    if (order.statusId == 6 || order.statusId == 3) {
      debugPrint('showMapDriver: false (order delivered or cancelled)');
      return false;
    }

    // Show map if we have tasks or dispatcher status
    if (vendor.tasks != null || vendor.dispatcherStatusOptionId != null) {
      debugPrint('showMapDriver: true (has tasks or dispatcher status)');
      return true;
    }

    // Show map for processing orders
    if (order.statusId >= 2 && order.statusId <= 5) {
      debugPrint('showMapDriver: true (order in progress)');
      return true;
    }

    debugPrint('showMapDriver: false (default)');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            final order = orderProvider.currentOrderDetails;
            return Column(
              children: [
                Text(
                  'Order ${order?.orderNumber ?? widget.orderId}',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (order?.createdAt != null)
                  Text(
                    _formatOrderDate(order!.createdAt!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[200]!,
                  Colors.grey[100]!,
                  Colors.grey[200]!,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2196F3)),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading order details...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _loadOrderDetails();
              },
              color: const Color(0xFF2196F3),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Match React Native getHeader() function structure
                    _buildHeader(),

                    // Match React Native main order content
                    _buildOrderContent(),
                  ],
                ),
              ),
            ),
    );
  }

  // Match React Native getHeader function
  Widget _buildHeader() {
    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrderDetails;

    if (order?.vendors?.isNotEmpty != true) return const SizedBox.shrink();

    final vendor = order!.vendors!.first;
    debugPrint("===HEADER DEBUG MAP====");
    debugPrint("driver status: $_driverStatus");
    debugPrint(
        "dispatcher driver: $_dispatchDriverData, has valid loc: ${_dispatchDriverData?.hasValidLocation ?? false}");
    return Column(
      children: [
        // Driver Info Section (matches React Native UserDetail when driver exists)
        // React Native condition: !!(driverStatus?.order && driverStatus?.agent_location?.lat) && showMapDriver
        if ((_driverStatus != null &&
                _driverStatus!['agent_location'] != null &&
                _driverStatus!['agent_location']['lat'] != null &&
                _shouldShowMap()) ||
            (_dispatchDriverData != null &&
                _dispatchDriverData!.hasValidLocation))
          _buildDriverInfoSection(vendor),

        // Large Map Section (matches React Native MapView with height / 2.2)
        // Show map if we should show map and no LaLaMove URL
        // We'll show the map even without driver location, just with restaurant and delivery markers
        if (_shouldShowMap() && _lalaMoveUrl == null)
          if ((_driverStatus != null &&
                  _driverStatus!['agent_location'] != null &&
                  _driverStatus!['agent_location']['lat'] != null) ||
              (_dispatchDriverData != null &&
                  _dispatchDriverData!.hasValidLocation))
            _buildMapSection()
          else
            _buildStaticMapSection(), // Show restaurant and destination only

        // LaLaMove WebView Section (matches React Native lalaMoveUrl condition)
        if (_lalaMoveUrl != null) _buildLalaMoveSection(),

        // Order Status Section (matches React Native StepIndicators and arrowUp logic)
        _buildOrderStatusSection(vendor),
      ],
    );
  }

  Widget _buildDriverInfoSection(OrderVendorDetailModel vendor) {
    // Using new modular widgets for better organization
    final driverPhone = _dispatchDriverData?.driverPhone ?? _orderTracking?.driverInfo?.phone ?? '';

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Driver Card - Basic info with photo, name, rating
          DriverCardWidget(
            orderTracking: _orderTracking,
            dispatchDriverData: _dispatchDriverData,
          ),
          
          SizedBox(height: 12.h),
          
          // Driver Status - Current status with icon
          DriverStatusWidget(
            orderTracking: _orderTracking,
            dispatchDriverData: _dispatchDriverData,
          ),
          
          SizedBox(height: 12.h),
          
          // Driver Contact Actions - Call, SMS, WhatsApp buttons
          DriverContactActions(
            driverPhone: driverPhone,
            deviceType: _dispatchDriverData?.deviceType,
          ),
          
          SizedBox(height: 12.h),
          
          // Driver Delivery Details - ETA, distance, pricing
          DriverDeliveryDetails(
            orderTracking: _orderTracking,
            dispatchDriverData: _dispatchDriverData,
          ),
          
          // Task Status Section
          if (_dispatchDriverData?.tasks != null && _dispatchDriverData!.tasks!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTasksSection(_dispatchDriverData!.tasks!),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Gradient gradient,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(21.w),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22.w,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    // Match React Native MapView with exact height: height / 2.2
    final initialPosition = _getInitialMapPosition();
    debugPrint('=== Building Map Section ===');
    debugPrint('Initial position: $initialPosition');
    debugPrint('Current markers: ${_markers.length}');

    return Container(
      height: MediaQuery.of(context).size.height / 2.2,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                debugPrint('=== Map Created ===');
                _mapController = controller;
                // Update markers first
                _updateMapMarkers();
                // Auto-fit to markers after delay (matches React Native behavior)
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_markers.isNotEmpty) {
                    debugPrint('Centering map on ${_markers.length} markers');
                    _centerMapOnMarkers();
                  } else {
                    debugPrint(
                        'No markers to center on - staying at initial position');
                  }
                });
              },
              markers: _markers,
              polylines: _polylines,
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 13.0, // Slightly lower zoom for better overview
              ),
              // Match React Native MapView props
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              mapType: MapType.normal,
            ),
            // Add loading indicator overlay if markers are still loading
            if (_markers.isEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(const Color(0xFF2196F3)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Loading locations...',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black87,
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

  Widget _buildStaticMapSection() {
    // Map showing only restaurant and delivery destination (no driver)
    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrderDetails;

    debugPrint(
        '=== Building Static Map Section (Restaurant & Destination) ===');

    // Get restaurant and delivery coordinates
    LatLng? restaurantPosition;
    LatLng? deliveryPosition;

    // Get restaurant location from vendor
    if (order?.vendors?.isNotEmpty == true) {
      final vendorDetail = order!.vendors!.first;
      if (vendorDetail.vendor != null &&
          vendorDetail.vendor!.latitude != null &&
          vendorDetail.vendor!.longitude != null) {
        restaurantPosition = LatLng(
          double.parse(vendorDetail.vendor!.latitude!),
          double.parse(vendorDetail.vendor!.longitude!),
        );
        debugPrint('Restaurant position: $restaurantPosition');
      }
    }

    // Get delivery location from order address
    if (order?.address != null) {
      final address = order!.address!;
      if (address.latitude != null && address.longitude != null) {
        deliveryPosition = LatLng(
          address.latitude!,
          address.longitude!,
        );
        debugPrint('Delivery position: $deliveryPosition');
      }
    }

    // If we don't have both locations, don't show map
    if (restaurantPosition == null || deliveryPosition == null) {
      return const SizedBox.shrink();
    }

    // Create markers for restaurant and destination
    final Set<Marker> staticMarkers = {
      // Restaurant marker
      Marker(
        markerId: const MarkerId('restaurant'),
        position: restaurantPosition,
        infoWindow: InfoWindow(
          title: order?.vendors?.first.vendor?.name ??
              order?.vendors?.first.vendorName ??
              'Restaurant',
          snippet: 'Pickup Location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      // Delivery destination marker
      Marker(
        markerId: const MarkerId('delivery'),
        position: deliveryPosition,
        infoWindow: InfoWindow(
          title: 'Delivery Address',
          snippet: order?.address?.address ?? '',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    // Calculate initial camera position (center between restaurant and delivery)
    final centerLat =
        (restaurantPosition.latitude + deliveryPosition.latitude) / 2;
    final centerLng =
        (restaurantPosition.longitude + deliveryPosition.longitude) / 2;
    final initialPosition = LatLng(centerLat, centerLng);

    // Calculate zoom level based on distance
    final distance =
        _calculateDistanceStatic(restaurantPosition, deliveryPosition);
    final zoomLevel = _getZoomLevel(distance);

    return Container(
      height: MediaQuery.of(context).size.height / 2.2,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                debugPrint('=== Static Map Created ===');
                // Fit bounds to show both markers
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            math.min(restaurantPosition!.latitude,
                                deliveryPosition!.latitude),
                            math.min(restaurantPosition.longitude,
                                deliveryPosition.longitude),
                          ),
                          northeast: LatLng(
                            math.max(restaurantPosition.latitude,
                                deliveryPosition.latitude),
                            math.max(restaurantPosition.longitude,
                                deliveryPosition.longitude),
                          ),
                        ),
                        100.0, // padding
                      ),
                    );
                  }
                });
              },
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: zoomLevel,
              ),
              markers: staticMarkers,
              polylines: _polylines, // Will use the same polylines if available
              mapType: MapType.normal,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
            // Status overlay
            Positioned(
              top: 16.h,
              left: 16.w,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.blue[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 32.w,
                            height: 32.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[600]!,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.delivery_dining,
                            size: 18.sp,
                            color: Colors.blue[700],
                          ),
                        ],
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finding Your Driver',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 10.sp,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Estimated wait: 2-5 minutes',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistanceStatic(LatLng pos1, LatLng pos2) {
    // Simple distance calculation (Haversine formula)
    const double earthRadius = 6371; // km
    final double dLat = _toRadiansStatic(pos2.latitude - pos1.latitude);
    final double dLon = _toRadiansStatic(pos2.longitude - pos1.longitude);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadiansStatic(pos1.latitude)) *
            math.cos(_toRadiansStatic(pos2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadiansStatic(double degree) {
    return degree * (math.pi / 180);
  }

  double _getZoomLevel(double distance) {
    // Adjust zoom level based on distance
    if (distance < 1) return 15;
    if (distance < 5) return 13;
    if (distance < 10) return 12;
    if (distance < 20) return 11;
    return 10;
  }

  Widget _buildLalaMoveSection() {
    // Match React Native LaLaMove WebView section
    return Container(
      height: MediaQuery.of(context).size.height / 1.8,
      margin: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        // Placeholder for WebView since it needs proper implementation
        child: Container(
          color: Colors.grey[100],
          child: const Center(
            child: Text('LaLaMove Tracking WebView'),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusSection(OrderVendorDetailModel vendor) {
    // Match React Native expandable order status with arrowUp state
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // Header with arrow (matches React Native arrowUp toggle)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(24.r),
                onTap: () {
                  setState(() {
                    _arrowUp = !_arrowUp;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _arrowUp ? Colors.grey[200]! : Colors.transparent,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple[400]!,
                              Colors.purple[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.timeline,
                          color: Colors.white,
                          size: 22.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Status',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              vendor.tasks?.where((t) => t['task_status'] == '4').length == vendor.tasks?.length
                                  ? 'All tasks completed'
                                  : '${vendor.tasks?.where((t) => t['task_status'] == '4').length ?? 0} of ${vendor.tasks?.length ?? 0} completed',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _arrowUp ? 0.5 : 0,
                        duration: Duration(milliseconds: 300),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[700],
                            size: 20.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expandable task list
            AnimatedCrossFade(
              firstChild: SizedBox.shrink(),
              secondChild: vendor.tasks != null ? _buildTaskList(vendor.tasks!) : SizedBox.shrink(),
              crossFadeState: _arrowUp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    // Match React Native task list rendering logic
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Column(
        children: tasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final isLast = index == tasks.length - 1;
          final isCompleted = task['task_status'] == '4';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline
              Column(
                children: [
                  // Task status indicator
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isCompleted
                          ? LinearGradient(
                              colors: [
                                Colors.green[400]!,
                                Colors.green[600]!,
                              ],
                            )
                          : null,
                      color: !isCompleted ? Colors.grey[200] : null,
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18.w,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                  ),
                  // Connecting line
                  if (!isLast)
                    Container(
                      height: 40.h,
                      width: 2.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isCompleted
                              ? [
                                  Colors.green[400]!,
                                  Colors.green[200]!,
                                ]
                              : [
                                  Colors.grey[300]!,
                                  Colors.grey[200]!,
                                ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16.w),
              // Task details
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isCompleted ? Colors.green[200]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            index == 0 ? Icons.restaurant : Icons.home,
                            size: 16.w,
                            color: isCompleted ? Colors.green[700] : Colors.grey[600],
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            index == 0 ? 'Pickup' : 'Delivery',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.green[700] : Colors.grey[600],
                            ),
                          ),
                          Spacer(),
                          if (isCompleted)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        task['address']?.toString() ?? 'Location ${index + 1}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderContent() {
    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrderDetails;

    if (order == null) return const SizedBox.shrink();

    // Reorganized order content with better spacing
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Order Summary Card
          OrderSummaryCard(order: order),
          
          SizedBox(height: 16.h),
          
          // Vendor Information
          _buildVendorSection(order),
          
          SizedBox(height: 16.h),
          
          // Order Items
          _buildOrderItems(order),
          
          SizedBox(height: 16.h),
          
          // Price Breakdown
          OrderPriceBreakdown(order: order),
          
          SizedBox(height: 16.h),
          
          // Delivery/Pickup Address
          _buildAddressSection(order),
          
          SizedBox(height: 16.h),
          
          // Special Instructions
          if (order.specificInstructions != null || order.commentForVendor != null)
            _buildSpecialInstructions(order),
        ],
      ),
    );
  }

  Widget _buildAddressSection(OrderModel order) {
    final isPickup = order.luxuryOptionName?.toLowerCase() == 'pickup' || 
                     order.luxuryOptionName?.toLowerCase() == 'takeaway';
    
    if (isPickup) {
      // For pickup orders, show vendor address
      if (order.vendors?.isNotEmpty != true) return const SizedBox.shrink();
      
      final vendor = order.vendors!.first;
      
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  Icons.store,
                  size: 20.sp,
                  color: Colors.blue,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Pickup Location',
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
              vendor.vendorName ?? 'Restaurant',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (vendor.vendor?.address != null) ...[
              SizedBox(height: 4.h),
              Text(
                vendor.vendor!.address!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (vendor.vendor?.phone != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    vendor.vendor!.phone!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } else {
      // For delivery orders, show user's delivery address
      if (order.address == null) return const SizedBox.shrink();
      
      final address = order.address!;
      
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  size: 20.sp,
                  color: Colors.red,
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
              address.address,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (address.houseNumber != null && address.houseNumber!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                'House/Apt: ${address.houseNumber}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
            SizedBox(height: 4.h),
            Text(
              '${address.city ?? ''}, ${address.state ?? ''} ${address.zipCode ?? address.pincode ?? ''}',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSpecialInstructions(OrderModel order) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                Icons.edit_note,
                size: 20.sp,
                color: Colors.purple,
              ),
              SizedBox(width: 8.w),
              Text(
                'Special Instructions',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (order.specificInstructions != null && order.specificInstructions!.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.luxuryOptionName?.toLowerCase() == 'pickup' || 
                    order.luxuryOptionName?.toLowerCase() == 'takeaway' 
                        ? 'Pickup Instructions' 
                        : 'Delivery Instructions',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[800],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    order.specificInstructions!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.purple[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (order.commentForVendor != null && order.commentForVendor!.isNotEmpty) ...[
            if (order.specificInstructions != null && order.specificInstructions!.isNotEmpty)
              SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note for Restaurant',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    order.commentForVendor!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.blue[900],
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

  Widget _buildVendorSection(OrderModel order) {
    if (order.vendors?.isNotEmpty != true) return const SizedBox.shrink();

    final vendor = order.vendors!.first;
    
    // Debug vendor logo
    debugPrint('=== Vendor Logo Debug ===');
    debugPrint('Vendor name: ${vendor.vendorName}');
    debugPrint('Vendor logo URL: ${vendor.logo}');
    debugPrint('Has vendor object: ${vendor.vendor != null}');
    if (vendor.vendor != null) {
      debugPrint('Vendor.vendor logo: ${vendor.vendor!.logo}');
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vendor Logo with shadow
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: (vendor.logo != null || vendor.vendor?.logo != null)
                  ? CachedNetworkImage(
                      imageUrl: vendor.logo ?? vendor.vendor!.logo!,
                      fit: BoxFit.cover,
                      httpHeaders: const {
                        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                      },
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                          ),
                        ),
                      ),
                      errorWidget: (context, error, stackTrace) {
                        debugPrint('Error loading vendor logo: $error');
                        debugPrint('Logo URL was: ${vendor.logo}');
                        return Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.grey[400],
                            size: 30.w,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[100],
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.grey[400],
                        size: 30.w,
                      ),
                    ),
            ),
          ),

          SizedBox(width: 16.w),

          // Vendor Details with rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.vendorName ?? 'Restaurant',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                if (vendor.vendor?.address != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14.sp,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          vendor.vendor!.address!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Contact Button with gradient
          if (vendor.vendor?.phone != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2196F3), const Color(0xFF2196F3).withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => _launchUrl('tel:${vendor.vendor!.phone}'),
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 22.w,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(OrderModel order) {
    // Match React Native product display logic
    final products = order.vendors?.isNotEmpty == true
        ? order.vendors!.first.products
        : order.products;

    if (products == null || products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.orange[700],
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Text(
                  '${products.length} items',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...products.map((product) => _buildProductItem(product)),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderProductModel product) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Beautiful Product Image
                Hero(
                  tag: 'order-detail-product-${product.id}',
                  child: Container(
                    width: 85.w,
                    height: 85.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: product.productImage != null
                          ? CachedNetworkImage(
                              imageUrl: product.productImage!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey[200]!,
                                      Colors.grey[300]!,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.orange[100]!,
                                      Colors.orange[200]!,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  color: Colors.orange[700],
                                  size: 40.w,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange[100]!,
                                    Colors.orange[200]!,
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                color: Colors.orange[700],
                                size: 40.w,
                              ),
                            ),
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName ?? 'Unknown Product',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      // Addons if any
                      if (product.productAddons != null && product.productAddons!.isNotEmpty) ...[
                        Text(
                          product.productAddons!.map((addon) => '${addon.addonTitle}: ${addon.optionTitle}').join(', '),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                      ],
                      Row(
                        children: [
                          // Quantity Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[400]!,
                                  Colors.blue[600]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'x${product.quantity}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            AppUtils.formatCurrency(product.price),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Total Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green[400]!,
                            Colors.green[600]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        AppUtils.formatCurrency(product.price * product.quantity),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(OrderModel order) {
    // Match React Native price breakdown display
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!.withValues(alpha: 0.5),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.receipt_outlined,
                  color: Colors.blue[700],
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (order.subtotalAmount != null)
            _buildPriceRow('Subtotal', order.subtotalAmount!, icon: Icons.shopping_cart_outlined),
          if (order.totalDeliveryFee != null && order.totalDeliveryFee! > 0)
            _buildPriceRow('Delivery Fee', order.totalDeliveryFee!, icon: Icons.delivery_dining),
          if (order.totalServiceFee != null && order.totalServiceFee! > 0)
            _buildPriceRow('Service Fee', order.totalServiceFee!, icon: Icons.room_service),
          if (order.taxableAmount != null && order.taxableAmount! > 0)
            _buildPriceRow('Taxes & Fees', order.taxableAmount!, icon: Icons.account_balance),
          if (order.discountAmount != null && order.discountAmount! > 0)
            _buildPriceRow('Discount', -order.discountAmount!,
                isDiscount: true, icon: Icons.discount),
          if (order.tipAmount != null && order.tipAmount! > 0)
            _buildPriceRow('Tip', order.tipAmount!, icon: Icons.volunteer_activism),
          Container(
            margin: EdgeInsets.symmetric(vertical: 16.h),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          _buildPriceRow('Total', order.payableAmount ?? order.totalAmount,
              isTotal: true, icon: Icons.payments),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount,
      {bool isDiscount = false, bool isTotal = false, IconData? icon}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16.w,
              color: isTotal ? Colors.blue[700] : Colors.grey[600],
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal ? Colors.black87 : Colors.grey[700],
              ),
            ),
          ),
          Container(
            padding: isTotal ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h) : null,
            decoration: isTotal
                ? BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12.r),
                  )
                : null,
            child: Text(
              '${isDiscount ? '- ' : ''}${AppUtils.formatCurrency(amount.abs())}',
              style: TextStyle(
                fontSize: isTotal ? 16.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                color: isTotal ? Colors.white : (isDiscount ? Colors.green[600] : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInformation(OrderModel order) {
    // Match React Native order information display
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.purple[700],
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Order Information',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildInfoRow('Order Number', '#${order.orderNumber ?? order.id}',
              icon: Icons.tag),
          _buildInfoRow('Payment Method', order.paymentMethod ?? 'N/A',
              icon: Icons.payment),
          _buildInfoRow(
              'Placed On', _formatDateTime(order.createdDate ?? order.createdAt ?? ''),
              icon: Icons.calendar_today),
          if (order.scheduledDateTime != null)
            _buildInfoRow('Scheduled For', _formatDateTime(order.scheduledDateTime!),
                icon: Icons.schedule),
          if (order.commentForVendor != null &&
              order.commentForVendor!.isNotEmpty)
            _buildInfoRow('Special Instructions', order.commentForVendor!,
                icon: Icons.restaurant_menu),
          if (order.specificInstructions != null &&
              order.specificInstructions!.isNotEmpty)
            _buildInfoRow('Delivery Instructions', order.specificInstructions!,
                icon: Icons.delivery_dining),
          if (order.statusId != null)
            _buildInfoRow('Order Status', _getOrderStatusText(order.statusId),
                icon: Icons.circle,
                iconColor: _getStatusColor(order.statusId)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, Color? iconColor}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey[600])!.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                size: 16.w,
                color: iconColor ?? Colors.grey[600],
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for launching URLs (matches React Native Linking)
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _callDriver(String phone) {
    _launchUrl('tel:$phone');
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.w,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14.w,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeStamp(String label, String time, IconData icon) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.w,
            color: Colors.blue[700],
          ),
          SizedBox(width: 4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getVehicleType(int vehicleTypeId) {
    switch (vehicleTypeId) {
      case 1:
        return 'Bike';
      case 2:
        return 'Car';
      case 3:
        return 'Van';
      case 4:
        return 'Truck';
      default:
        return 'Vehicle';
    }
  }
  
  String _formatOrderDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
  
  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
  
  Color _getStatusColor(int? statusId) {
    switch (statusId) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.red;
      case 4:
      case 5:
        return Colors.green;
      case 6:
        return Colors.green[700]!;
      default:
        return Colors.grey;
    }
  }
  
  String _formatTime(String time) {
    try {
      final dateTime = DateTime.parse(time);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return time;
    }
  }
  
  Widget _buildTasksSection(List<TaskData> tasks) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[50]!,
            Colors.green[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16.w,
                color: Colors.green[700],
              ),
              SizedBox(width: 8.w),
              Text(
                'Delivery Progress',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...tasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }
  
  Widget _buildTaskItem(TaskData task) {
    final isCompleted = task.isCompleted;
    final taskTitle = task.isPickup ? 'Pickup from Restaurant' : 'Delivery to You';
    final taskIcon = task.isPickup ? Icons.restaurant : Icons.home;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : taskIcon,
                  size: 18.w,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskTitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                    if (task.address != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        task.address!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isCompleted && task.updatedAt != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Completed ${_formatTime(task.updatedAt!)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (task.fullProofImageUrl != null && isCompleted) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => _showProofImage(task),
                  child: Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.green[300]!,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Image.network(
                        task.fullProofImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 20.w,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  void _showProofImage(TaskData task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.isPickup ? 'Pickup Confirmation' : 'Delivery Confirmation',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: InteractiveViewer(
                  child: Image.network(
                    task.fullProofImageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200.h,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Completed at ${task.address ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getOrderStatusText(int statusId) {
    switch (statusId) {
      case 1:
        return 'Pending';
      case 2:
        return 'Processing';
      case 3:
        return 'Cancelled';
      case 4:
        return 'On the way';
      case 5:
        return 'Delivered';
      case 6:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }
}
