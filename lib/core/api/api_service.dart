import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../models/api_response.dart';

class ApiService {
  late final Dio _dio;
  static final ApiService _instance = ApiService._internal();

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
        },
      ),
    );

    _dio.interceptors.addAll([
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
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
        
        // Debug logging
        print('PostDirect - Response data keys: ${responseData.keys}');
        if (extractField != null) {
          print('PostDirect - Looking for field: $extractField');
          print('PostDirect - Field value: ${responseData[extractField]}');
        }
        
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
