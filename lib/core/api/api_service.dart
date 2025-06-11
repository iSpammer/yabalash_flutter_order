import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../models/api_response.dart';

class ApiService {
  late final Dio _dio;
  static final ApiService _instance = ApiService._internal();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _cachedDeviceId;

  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.fullBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'code': ApiConstants.companyCode,
          'language': '1',
        },
      ),
    );

    _dio.interceptors.addAll([
      // Conditionally add logger based on request path
      // InterceptorsWrapper(
      //   onRequest: (options, handler) {
      //     // Skip logging for /v2/homepage endpoint
      //     if (!options.path.contains('/v2/homepage')) {
      //       options.extra['skipLog'] = false;
      //     } else {
      //       options.extra['skipLog'] = true;
      //     }
      //     handler.next(options);
      //   },
      // ),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        filter: (options, _) {
          // Skip logging for homepage and other high-frequency endpoints
          final path = options.path.toLowerCase();
          if (path.contains('/homepage') || 
              path.contains('/v2/homepage') ||
              path.contains('/cart/list') ||
              path.contains('/notification/count')) {
            return false;
          }
          // Skip if explicitly marked
          return options.extra['skipLog'] != true;
        },
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = token;
          }

          final prefs = await SharedPreferences.getInstance();
          // Force language to be "1" until we implement proper language management
          final language = AppConstants.defaultLanguage;
          await prefs.setString(AppConstants.languageKey, language);
          options.headers['language'] = language;
          options.headers['code'] = AppConstants.apiCode;

          // Add additional headers that React Native app uses
          options.headers['currency'] = '1'; // Currency ID from curl example
          options.headers['freelancer'] = '0'; // Not freelancer mode

          // Add device ID as systemuser header
          final deviceId = await _getDeviceId();
          if (deviceId != null) {
            options.headers['systemuser'] = deviceId;
          }

          // Add location headers if available in query params
          if (options.queryParameters.containsKey('latitude')) {
            options.headers['latitude'] =
                options.queryParameters['latitude'].toString();
          }
          if (options.queryParameters.containsKey('longitude')) {
            options.headers['longitude'] =
                options.queryParameters['longitude'].toString();
          }

          handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized access
            await _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    ]);
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userDataKey);
    final authToken = prefs.getString(AppConstants.authTokenKey);

    if (userData != null && authToken != null) {
      return authToken;
    }
    return null;
  }

  Future<void> _handleUnauthorized() async {
    // Clear user data and navigate to login
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.authTokenKey);
    // Navigation will be handled by the app
  }

  Future<String?> _getDeviceId() async {
    // Use cached value if available
    if (_cachedDeviceId != null) return _cachedDeviceId;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        _cachedDeviceId = androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _cachedDeviceId = iosInfo.identifierForVendor ?? '';
      } else {
        // For web or other platforms, generate a unique ID
        final prefs = await SharedPreferences.getInstance();
        String? storedId = prefs.getString('device_id');
        if (storedId == null) {
          storedId = DateTime.now().millisecondsSinceEpoch.toString();
          await prefs.setString('device_id', storedId);
        }
        _cachedDeviceId = storedId;
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      // Fallback to a default value
      _cachedDeviceId = 'flutter_default_id';
    }

    return _cachedDeviceId;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return ApiResponse.fromJson(response.data, fromJsonT);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );

      return ApiResponse.fromJson(response.data, fromJsonT);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // Dedicated method for endpoints that return data directly without wrapping
  Future<ApiResponse<T>> postDirect<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    String? extractField,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );

      // For endpoints that return data directly at root level
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        // Debug logging disabled for now
        // if (kDebugMode) {
        //   // ignore: avoid_print
        //   print('PostDirect - Response data keys: ${responseData.keys}');
        //   if (extractField != null) {
        //     // ignore: avoid_print
        //     print('PostDirect - Looking for field: $extractField');
        //     // ignore: avoid_print
        //     print('PostDirect - Field value: ${responseData[extractField]}');
        //   }
        // }

        // If we need to extract a specific field
        if (extractField != null && responseData.containsKey(extractField)) {
          return ApiResponse.success(
            data: responseData[extractField] as T,
            statusCode: response.statusCode,
          );
        }

        // Return the whole response as data
        return ApiResponse.success(
          data: responseData as T,
          statusCode: response.statusCode,
        );
      }

      // Fallback to normal parsing
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, fromJsonT);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return ApiResponse.fromJson(response.data, fromJsonT);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    String message = 'An error occurred';
    Map<String, dynamic>? errors;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        if (error.response != null && error.response!.data != null) {
          if (error.response!.data is Map) {
            final responseData = error.response!.data as Map<String, dynamic>;

            // Handle message which could be a String or Map
            if (responseData['message'] != null) {
              final messageData = responseData['message'];
              if (messageData is String) {
                message = messageData;
              } else if (messageData is Map) {
                // Extract error message from Map (e.g., vendor conflict)
                message =
                    messageData['error']?.toString() ?? messageData.toString();
              } else {
                message = messageData.toString();
              }
            } else if (responseData['error'] != null) {
              // Handle the 'error' field that the API returns
              final errorData = responseData['error'];
              if (errorData is String) {
                message = errorData;
              } else {
                message = errorData.toString();
              }
            } else {
              message = 'Server error occurred';
            }

            errors = responseData['errors'];
          } else {
            message = 'Server error occurred';
          }
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          message = 'No internet connection';
        } else {
          message = 'Something went wrong. Please try again.';
        }
        break;
      default:
        message = 'Network error occurred';
    }

    return ApiResponse.error(
      message: message,
      statusCode: error.response?.statusCode,
      errors: errors,
    );
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  void updateHeaders(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }
}
