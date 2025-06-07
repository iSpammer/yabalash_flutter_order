import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/api_response.dart';

class OrderTrackingService {
  final ApiService _apiService = ApiService();
  static const String code = '2b5f69';
  
  // Get order tracking details with real-time driver location
  Future<ApiResponse<OrderTracking>> getOrderTracking(int orderId, int vendorId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/order-detail',
        data: {
          'order_id': orderId,
          'vendor_id': vendorId,
        },
      );
      
      if (response.success && response.data != null) {
        final orderData = response.data!['data'] ?? response.data!;
        return ApiResponse(
          success: true,
          data: OrderTracking.fromJson(orderData),
        );
      }
      
      return ApiResponse(
        success: false,
        message: 'Failed to get order tracking data',
      );
    } catch (e) {
      debugPrint('Error getting order tracking: $e');
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  // Get Firebase token for push notifications
  Future<String> getFirebaseToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? '';
    } catch (e) {
      debugPrint('Error getting Firebase token: $e');
      return '';
    }
  }
}

// Order Tracking Model with driver location
class OrderTracking {
  final String orderNumber;
  final int? dispatcherStatus;
  final String? trackingUrl;
  final List<String> statusIcons;
  final String orderStatus;
  final double? driverLat;
  final double? driverLng;
  final double? driverHeading;
  final String? estimatedTime;
  final DriverInfo? driverInfo;
  final List<TaskLocation>? tasks;
  final Map<String, dynamic>? agentLocation;
  
  OrderTracking({
    required this.orderNumber,
    this.dispatcherStatus,
    this.trackingUrl,
    required this.statusIcons,
    required this.orderStatus,
    this.driverLat,
    this.driverLng,
    this.driverHeading,
    this.estimatedTime,
    this.driverInfo,
    this.tasks,
    this.agentLocation,
  });
  
  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendors'] != null && json['vendors'].isNotEmpty
        ? json['vendors'][0]
        : null;
    
    if (vendor == null) {
      throw Exception('No vendor data found');
    }
    
    // Extract driver location from agent_location
    double? driverLat;
    double? driverLng;
    double? driverHeading;
    
    if (vendor['agent_location'] != null) {
      final agentLoc = vendor['agent_location'];
      driverLat = double.tryParse(agentLoc['lat']?.toString() ?? '');
      driverLng = double.tryParse(agentLoc['lng']?.toString() ?? 
                                  agentLoc['long']?.toString() ?? '');
      driverHeading = double.tryParse(agentLoc['heading_angle']?.toString() ?? '0');
    }
    
    // Parse tasks for pickup/delivery locations
    List<TaskLocation>? tasks;
    if (vendor['tasks'] != null && vendor['tasks'] is List) {
      tasks = (vendor['tasks'] as List)
          .map((task) => TaskLocation.fromJson(task))
          .toList();
    }
    
    return OrderTracking(
      orderNumber: json['order_number'] ?? '',
      dispatcherStatus: vendor['dispatcher_status_option_id'],
      trackingUrl: vendor['dispatch_traking_url'],
      statusIcons: vendor['dispatcher_status_icons'] != null
          ? List<String>.from(vendor['dispatcher_status_icons'])
          : [],
      orderStatus: vendor['order_status']?['current_status']?['title'] ?? 'Processing',
      driverLat: driverLat,
      driverLng: driverLng,
      driverHeading: driverHeading,
      estimatedTime: vendor['ETA'],
      driverInfo: vendor['agent_location'] != null && 
                  vendor['dispatcher_status_option_id'] != null &&
                  vendor['dispatcher_status_option_id'] >= 2
          ? DriverInfo.fromAgentLocation(vendor['agent_location'])
          : null,
      tasks: tasks,
      agentLocation: vendor['agent_location'],
    );
  }
  
  bool get isDelivered => dispatcherStatus == 6;
  bool get isCancelled => dispatcherStatus == 3;
  bool get hasDriver => driverLat != null && driverLng != null;
  
  String get statusText {
    switch (dispatcherStatus) {
      case 1: return 'Order Accepted';
      case 2: return 'Driver Assigned';
      case 3: return 'Driver Going to Restaurant';
      case 4: return 'Driver at Restaurant';
      case 5: return 'Order Picked Up';
      case 6: return 'Order Delivered';
      default: return 'Preparing Order';
    }
  }
}

class TaskLocation {
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? taskStatus;
  final int? taskType; // 0 = pickup, 1 = delivery
  
  TaskLocation({
    this.address,
    this.latitude,
    this.longitude,
    this.taskStatus,
    this.taskType,
  });
  
  factory TaskLocation.fromJson(Map<String, dynamic> json) {
    return TaskLocation(
      address: json['address'],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      taskStatus: json['task_status']?.toString(),
      taskType: json['task_type'] != null ? int.tryParse(json['task_type'].toString()) : null,
    );
  }
  
  bool get isCompleted => taskStatus == '4';
}

class DriverInfo {
  final String name;
  final String phone;
  final String? photo;
  final double? rating;
  final int? driverId;
  
  DriverInfo({
    required this.name,
    required this.phone,
    this.photo,
    this.rating,
    this.driverId,
  });
  
  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      name: json['name'] ?? 'Driver',
      phone: json['phone'] ?? '',
      photo: json['photo'],
      rating: json['rating']?.toDouble(),
      driverId: json['driver_id'] != null ? int.tryParse(json['driver_id'].toString()) : null,
    );
  }
  
  // Create driver info from agent_location data
  factory DriverInfo.fromAgentLocation(Map<String, dynamic> agentLocation) {
    return DriverInfo(
      name: agentLocation['driver_name'] ?? 'Your Driver',
      phone: agentLocation['driver_phone'] ?? '',
      photo: agentLocation['driver_photo'],
      rating: agentLocation['driver_rating']?.toDouble(),
      driverId: agentLocation['driver_id'] != null 
          ? int.tryParse(agentLocation['driver_id'].toString()) 
          : null,
    );
  }
}