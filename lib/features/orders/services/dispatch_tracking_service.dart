import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DispatchTrackingService {
  final Dio _dio = Dio();

  // Base URL for dispatch images
  static const String imageBaseUrl =
      'https://imgproxy.royodispatch.com/insecure/fit/300/100/sm/0/plain/https://yabalash-assets.s3.me-central-1.amazonaws.com/';

  /// Converts dispatch tracking URL to API endpoint and fetches real-time GPS data
  /// Example:
  /// From: https://dispatch.yabalash.com/order/tracking/976d51/nS7ueT
  /// To: https://dispatch.yabalash.com/order-details/tracking/976d51/nS7ueT
  Future<Map<String, dynamic>?> getDriverLocation(String? trackingUrl) async {
    if (trackingUrl == null || trackingUrl.isEmpty) {
      debugPrint('No tracking URL provided');
      return null;
    }

    try {
      // Convert the tracking URL
      final convertedUrl = trackingUrl.replaceFirst(
          '/order/tracking/', '/order-details/tracking/');
      debugPrint('=== Fetching Driver Location ===');
      debugPrint('Original URL: $trackingUrl');
      debugPrint('Converted URL: $convertedUrl');

      // Configure Dio with timeout
      _dio.options.connectTimeout = const Duration(seconds: 10);
      _dio.options.receiveTimeout = const Duration(seconds: 10);

      final response = await _dio.get(
        convertedUrl,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('=== Dispatch API Response ===');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Type: ${response.data.runtimeType}');
        debugPrint(
            'Response Keys: ${response.data is Map ? (response.data as Map).keys.toList() : 'Not a Map'}');
        debugPrint('Full Response: ${response.data}');

        // Parse the response based on the structure
        if (response.data is Map) {
          // Check if data contains agent_location directly
          if (response.data['agent_location'] != null) {
            debugPrint('✅ Found agent_location at root level');
            debugPrint('Agent Location: ${response.data['agent_location']}');
            return response.data as Map<String, dynamic>;
          }
          // Check if data is nested
          if (response.data['data'] != null &&
              response.data['data']['agent_location'] != null) {
            debugPrint('✅ Found agent_location in nested data');
            debugPrint(
                'Agent Location: ${response.data['data']['agent_location']}');
            return response.data['data'] as Map<String, dynamic>;
          }

          // Check for any structure that might contain location data
          debugPrint('❌ No agent_location found in expected locations');
          debugPrint('Available keys: ${(response.data as Map).keys.toList()}');

          // Log all potential location-related keys
          final data = response.data as Map<String, dynamic>;
          for (final key in data.keys) {
            if (key.toString().toLowerCase().contains('location') ||
                key.toString().toLowerCase().contains('agent') ||
                key.toString().toLowerCase().contains('driver') ||
                key.toString().toLowerCase().contains('lat') ||
                key.toString().toLowerCase().contains('lng') ||
                key.toString().toLowerCase().contains('gps')) {
              debugPrint('🔍 Potential location key: $key = ${data[key]}');
            }
          }
        }
      }

      debugPrint('No valid driver location data found in response');
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        debugPrint('Network error fetching driver location: ${e.message}');
        debugPrint(
            'This might be due to network connectivity issues or DNS resolution problems');
      } else {
        debugPrint(
            'DioError fetching driver location: ${e.type} - ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching driver location: $e');
      return null;
    }
  }

  /// Extracts driver info from the dispatch data
  static DriverLocationData? parseDriverLocation(Map<String, dynamic>? data) {
    if (data == null || data['agent_location'] == null) return null;

    try {
      final agentLocation = data['agent_location'] as Map<String, dynamic>;
      final agent = data['agent'] as Map<String, dynamic>?;
      final order = data['order'] as Map<String, dynamic>?;
      final task = data['task'] as Map<String, dynamic>?;

      return DriverLocationData(
        lat: double.tryParse(agentLocation['lat']?.toString() ?? ''),
        lng: double.tryParse(agentLocation['long']?.toString() ?? '') ??
            double.tryParse(agentLocation['lng']?.toString() ?? ''),
        updatedAt: agentLocation['updated_at']?.toString(),
        driverName: agent?['name']?.toString() ??
            data['driver_name']?.toString() ??
            agentLocation['driver_name']?.toString(),
        driverPhone: agent?['phone_number']?.toString() ??
            data['driver_phone']?.toString() ??
            agentLocation['driver_phone']?.toString(),
        driverPhoto: data['driver_photo']?.toString() ??
            agentLocation['driver_photo']?.toString(),
        driverRating: double.tryParse(data['driver_rating']?.toString() ?? ''),
        vehicleInfo: data['vehicle_info']?.toString(),
        eta: data['eta']?.toString(),
        // Additional fields
        distanceFee: double.tryParse(order?['distance_fee']?.toString() ?? ''),
        basePrice: double.tryParse(order?['base_price']?.toString() ?? ''),
        actualDistance:
            double.tryParse(order?['actual_distance']?.toString() ?? ''),
        deviceType: agent?['device_type']?.toString(),
        status: order?['status']?.toString(),
        vehicleTypeId:
            int.tryParse(agent?['vehicle_type_id']?.toString() ?? ''),
        profilePicture: agent?['profile_picture']?.toString(),
        createdAt: agent?['created_at']?.toString(),
        taskUpdatedAt: task?['updated_at']?.toString(),
        tasks: _parseTasks(data['tasks']),
      );
    } catch (e) {
      debugPrint('Error parsing driver location: $e');
      return null;
    }
  }

  static List<TaskData>? _parseTasks(dynamic tasksData) {
    if (tasksData == null || tasksData is! List) return null;

    try {
      return tasksData
          .map((task) => TaskData(
                id: task['id'] as int?,
                taskStatus: task['task_status']?.toString(),
                address: task['address']?.toString(),
                proofImage: task['proof_image']?.toString(),
                updatedAt: task['updated_at']?.toString(),
                taskTypeId: task['task_type_id'] as int?,
                latitude: double.tryParse(task['latitude']?.toString() ?? ''),
                longitude: double.tryParse(task['longitude']?.toString() ?? ''),
              ))
          .toList();
    } catch (e) {
      debugPrint('Error parsing tasks: $e');
      return null;
    }
  }
}

class DriverLocationData {
  final double? lat;
  final double? lng;
  final String? updatedAt;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final double? driverRating;
  final String? vehicleInfo;
  final String? eta;
  // Additional fields from dispatch data
  final double? distanceFee;
  final double? basePrice;
  final double? actualDistance;
  final String? deviceType;
  final String? status;
  final int? vehicleTypeId;
  final String? profilePicture;
  final String? createdAt;
  final String? taskUpdatedAt;
  final List<TaskData>? tasks;

  DriverLocationData({
    this.lat,
    this.lng,
    this.updatedAt,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.driverRating,
    this.vehicleInfo,
    this.eta,
    this.distanceFee,
    this.basePrice,
    this.actualDistance,
    this.deviceType,
    this.status,
    this.vehicleTypeId,
    this.profilePicture,
    this.createdAt,
    this.taskUpdatedAt,
    this.tasks,
  });

  bool get hasValidLocation => lat != null && lng != null;

  String? get fullProfilePictureUrl {
    if (profilePicture != null && profilePicture!.isNotEmpty) {
      return '${DispatchTrackingService.imageBaseUrl}$profilePicture';
    }
    return null;
  }
}

class TaskData {
  final int? id;
  final String? taskStatus;
  final String? address;
  final String? proofImage;
  final String? updatedAt;
  final int? taskTypeId; // 1 = pickup, 2 = delivery
  final double? latitude;
  final double? longitude;

  TaskData({
    this.id,
    this.taskStatus,
    this.address,
    this.proofImage,
    this.updatedAt,
    this.taskTypeId,
    this.latitude,
    this.longitude,
  });

  String? get fullProofImageUrl {
    if (proofImage != null && proofImage!.isNotEmpty) {
      return '${DispatchTrackingService.imageBaseUrl}$proofImage';
    }
    return null;
  }

  bool get isCompleted => taskStatus == '4';
  bool get isPickup => taskTypeId == 1;
  bool get isDelivery => taskTypeId == 2;
}
