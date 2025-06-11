import '../../../core/api/api_service.dart';
import '../../../core/constants/api_constants.dart';

class ProfileService {
  final ApiService _apiService = ApiService();

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phoneNumber,
    required String countryCode,
    required String callingCode,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.updateProfile,
        data: {
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'country_code': countryCode,
          'callingCode': callingCode,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to update profile');
      }
      
      return response.success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to change password');
      }
      
      return response.success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateProfileImage(String base64Image) async {
    try {
      final response = await _apiService.post(
        ApiConstants.updateProfileImage,
        data: {
          'image': base64Image,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to update profile image');
      }
      
      return response.success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sendReferralCode(String email) async {
    try {
      final response = await _apiService.post(
        ApiConstants.sendReferralCode,
        data: {
          'email': email,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to send referral code');
      }
      
      return response.success;
    } catch (e) {
      rethrow;
    }
  }
}