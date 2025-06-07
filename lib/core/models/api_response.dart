class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.fromJson(
    dynamic json,
    T Function(dynamic)? fromJsonT,
  ) {
    // Handle case where json is a List (direct array response)
    if (json is List) {
      return ApiResponse(
        success: true,
        message: null,
        data: fromJsonT != null ? fromJsonT(json) : json as T?,
        statusCode: 200,
        errors: null,
      );
    }

    // Handle normal Map response
    final jsonMap = json as Map<String, dynamic>;

    // For Yabalash API, check various success indicators
    bool isSuccess = jsonMap['data'] != null ||
        jsonMap['success'] == true ||
        jsonMap['status'] == 'success' ||
        jsonMap['status'] == 'Success' ||
        // Handle special case for clear cart endpoint that returns only a success message
        (jsonMap['message'] is String && 
         jsonMap['message'].toString().toLowerCase().contains('success') &&
         jsonMap['data'] == null &&
         jsonMap['status'] == null);

    // Extract message - handle both String and Map formats
    String? message;
    if (jsonMap['message'] != null) {
      final messageData = jsonMap['message'];
      if (messageData is String) {
        message = messageData;
      } else if (messageData is Map) {
        // Extract error message from Map (e.g., vendor conflict)
        message = messageData['error']?.toString() ?? messageData.toString();
      } else {
        message = messageData.toString();
      }
    }

    return ApiResponse(
      success: isSuccess,
      message: message,
      data: jsonMap['data'] != null && fromJsonT != null
          ? fromJsonT(jsonMap['data'])
          : jsonMap['data'],
      statusCode: jsonMap['status_code'] ?? jsonMap['code'],
      errors: jsonMap['errors'],
    );
  }

  factory ApiResponse.error({
    required String message,
    int? statusCode,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }
}
