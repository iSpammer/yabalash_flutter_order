import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  
  Future<String> _getDeviceToken() async {
    return await FirebaseService.instance.getDeviceToken();
  }
  
  Future<String> _getDeviceType() async {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
  
  Future<ApiResponse<UserModel>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final deviceType = await _getDeviceType();
    final deviceToken = await _getDeviceToken();
    
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'device_type': deviceType,
        'device_token': deviceToken,
      },
    );
    
    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data!['data'] ?? response.data!);
      await _saveUserData(user);
      return ApiResponse.success(data: user);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Login failed',
      errors: response.errors,
    );
  }
  
  Future<ApiResponse<UserModel>> loginWithUsername({
    required String username,
    required String password,
    String? dialCode,
    String? countryCode,
  }) async {
    final deviceType = await _getDeviceType();
    final deviceToken = await _getDeviceToken();
    
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.loginViaUsername,
      data: {
        'username': username,
        'password': password,
        if (dialCode != null) 'dialCode': dialCode,
        if (countryCode != null) 'countryData': countryCode,
        'device_type': deviceType,
        'device_token': deviceToken,
      },
    );
    
    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data!['data'] ?? response.data!);
      await _saveUserData(user);
      return ApiResponse.success(data: user);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Login failed',
      errors: response.errors,
    );
  }
  
  Future<ApiResponse<UserModel>> verifyPhoneOtp({
    required String username,
    required String otp,
    required String dialCode,
  }) async {
    final deviceType = await _getDeviceType();
    final deviceToken = await _getDeviceToken();
    
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.verifyPhoneLoginOtp,
      data: {
        'username': username,
        'dialCode': dialCode,
        'device_type': deviceType,
        'device_token': deviceToken,
        'verifyToken': otp,
      },
    );
    
    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data!['data'] ?? response.data!);
      await _saveUserData(user);
      return ApiResponse.success(data: user);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Verification failed',
      errors: response.errors,
    );
  }
  
  Future<ApiResponse<UserModel>> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String dialCode,
    required String password,
    required String countryCode,
    String? referralCode,
  }) async {
    final deviceType = await _getDeviceType();
    final deviceToken = await _getDeviceToken();
    
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'dial_code': dialCode,
        'password': password,
        'country_code': countryCode,
        'device_type': deviceType,
        'device_token': deviceToken,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      },
    );
    
    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data!['data'] ?? response.data!);
      await _saveUserData(user);
      return ApiResponse.success(data: user);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Registration failed',
      errors: response.errors,
    );
  }
  
  Future<ApiResponse<bool>> verifyAccount({
    required String type,
    required String otp,
  }) async {
    final response = await _apiService.post(
      ApiConstants.verifyAccount,
      data: {
        'type': type,
        'otp': otp,
      },
    );
    
    return ApiResponse<bool>(
      success: response.success,
      message: response.message,
      data: response.success,
    );
  }
  
  Future<ApiResponse<bool>> forgotPassword({required String email}) async {
    final response = await _apiService.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
    
    return ApiResponse<bool>(
      success: response.success,
      message: response.message,
      data: response.success,
    );
  }
  
  Future<ApiResponse<bool>> sendVerificationToken({required String type}) async {
    final response = await _apiService.post(
      ApiConstants.sendToken,
      data: {'type': type},
    );
    
    return ApiResponse<bool>(
      success: response.success,
      message: response.message,
      data: response.success,
    );
  }
  
  Future<ApiResponse<List<Map<String, dynamic>>>> getCountryList() async {
    final response = await _apiService.get<List<dynamic>>(
      ApiConstants.countryList,
    );
    
    if (response.success && response.data != null) {
      final countries = (response.data as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      return ApiResponse.success(data: countries);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Failed to fetch countries',
    );
  }
  
  Future<ApiResponse<Map<String, dynamic>>> checkShortCode({
    required String shortCode,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.shortCode,
      data: {'shortCode': shortCode},
    );
    
    if (response.success && response.data != null) {
      return ApiResponse.success(data: response.data!);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Invalid short code',
    );
  }
  
  Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));
    if (user.authToken != null) {
      await prefs.setString(AppConstants.authTokenKey, user.authToken!);
    }
  }
  
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userDataKey);
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }
  
  Future<ApiResponse<UserModel>> socialLogin({
    required String provider,
    required Map<String, dynamic> socialData,
  }) async {
    final deviceType = await _getDeviceType();
    final deviceToken = await _getDeviceToken();
    
    final response = await _apiService.post<Map<String, dynamic>>(
      '/social/login/$provider',
      data: {
        'auth_id': socialData['id'],  // Changed from social_id to auth_id to match React Native
        'name': socialData['name'],
        'email': socialData['email'],
        'avatar': socialData['photo'],
        'device_type': deviceType,
        'device_token': deviceToken,
        'fcm_token': deviceToken,  // Added fcm_token as expected by backend
        if (socialData['accessToken'] != null)
          'access_token': socialData['accessToken'],
        if (socialData['idToken'] != null)
          'id_token': socialData['idToken'],
      },
    );
    
    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data!['data'] ?? response.data!);
      await _saveUserData(user);
      return ApiResponse.success(data: user);
    }
    
    return ApiResponse.error(
      message: response.message ?? 'Social login failed',
      errors: response.errors,
    );
  }
  
  Future<void> saveRememberMeCredentials({
    required String username,
    required String password,
    required bool isPhone,
    String? dialCode,
    String? countryCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remember_username', username);
    await prefs.setString('remember_password', password);
    await prefs.setBool('remember_is_phone', isPhone);
    if (dialCode != null) await prefs.setString('remember_dial_code', dialCode);
    if (countryCode != null) await prefs.setString('remember_country_code', countryCode);
    await prefs.setBool('remember_me', true);
  }
  
  Future<Map<String, dynamic>?> getRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    if (!rememberMe) return null;
    
    return {
      'username': prefs.getString('remember_username'),
      'password': prefs.getString('remember_password'),
      'isPhone': prefs.getBool('remember_is_phone') ?? false,
      'dialCode': prefs.getString('remember_dial_code'),
      'countryCode': prefs.getString('remember_country_code'),
    };
  }
  
  Future<void> clearRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_username');
    await prefs.remove('remember_password');
    await prefs.remove('remember_is_phone');
    await prefs.remove('remember_dial_code');
    await prefs.remove('remember_country_code');
    await prefs.setBool('remember_me', false);
  }
  
  Future<bool> getRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.authTokenKey);
    // Keep remember me preference and credentials if remember me is enabled
  }
  
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null && user.authToken != null;
  }
}