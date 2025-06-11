import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  
  // Store social login data temporarily for phone number completion
  Map<String, dynamic>? _pendingSocialData;
  String? _pendingSocialProvider;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get rememberMe => _rememberMe;
  bool get isLoggedIn => _user != null;
  bool get isAuthenticated => _user != null;
  String? get authToken => _user?.authToken;
  
  // Getters for pending social data
  Map<String, dynamic>? get pendingSocialData => _pendingSocialData;
  String? get pendingSocialProvider => _pendingSocialProvider;
  
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }
  
  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    if (!_rememberMe) {
      // Clear saved credentials when remember me is disabled
      _authService.clearRememberMeCredentials();
    }
    notifyListeners();
  }
  
  void setRememberMe(bool value) {
    _rememberMe = value;
    if (!_rememberMe) {
      // Clear saved credentials when remember me is disabled
      _authService.clearRememberMeCredentials();
    }
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<void> init() async {
    _user = await _authService.getCurrentUser();
    _rememberMe = await _authService.getRememberMePreference();
    notifyListeners();
  }
  
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      
      if (response.success && response.data != null) {
        _user = response.data;
        
        // Save credentials if remember me is enabled
        if (_rememberMe) {
          await _authService.saveRememberMeCredentials(
            username: email,
            password: password,
            isPhone: false,
          );
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> loginWithUsername({
    required String username,
    required String password,
    String? dialCode,
    String? countryCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.loginWithUsername(
        username: username,
        password: password,
        dialCode: dialCode,
        countryCode: countryCode,
      );
      
      if (response.success && response.data != null) {
        _user = response.data;
        
        // Save credentials if remember me is enabled
        if (_rememberMe) {
          await _authService.saveRememberMeCredentials(
            username: username,
            password: password,
            isPhone: true,
            dialCode: dialCode,
            countryCode: countryCode,
          );
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> verifyPhoneOtp({
    required String username,
    required String otp,
    required String dialCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.verifyPhoneOtp(
        username: username,
        otp: otp,
        dialCode: dialCode,
      );
      
      if (response.success && response.data != null) {
        _user = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String dialCode,
    required String password,
    required String countryCode,
    String? referralCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.register(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        dialCode: dialCode,
        password: password,
        countryCode: countryCode,
        referralCode: referralCode,
      );
      
      if (response.success && response.data != null) {
        _user = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.forgotPassword(email: email);
      
      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to send reset email';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> socialLogin({
    required String provider,
    required Map<String, dynamic> socialData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.socialLogin(
        provider: provider,
        socialData: socialData,
      );
      
      if (response.success && response.data != null) {
        _user = response.data;
        
        // Check if phone number is required
        if (_user?.phoneNumberRequired == true || 
            _user?.phoneNumber == null || 
            _user!.phoneNumber!.isEmpty) {
          // Store social data for phone number completion
          _pendingSocialData = socialData;
          _pendingSocialProvider = provider;
        } else {
          // Clear any pending data if phone number is not required
          _pendingSocialData = null;
          _pendingSocialProvider = null;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Social login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateProfileWithPhone({
    required String phoneNumber,
    required String dialCode,
    required String countryCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.updateProfileWithPhone(
        phoneNumber: phoneNumber,
        dialCode: dialCode,
        countryCode: countryCode,
      );
      
      if (response.success && response.data != null) {
        // Update the current user with new data
        _user = response.data;
        
        // Clear pending social data after successful phone update
        _pendingSocialData = null;
        _pendingSocialProvider = null;
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to update phone number';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> getRememberMeCredentials() async {
    return await _authService.getRememberMeCredentials();
  }
  
  Future<bool> verifyAccount({required String otp, String type = 'phone'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.verifyAccount(type: type, otp: otp);
      
      if (response.success && response.data != null) {
        // Update user data with verified status
        _user = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> sendVerificationToken({String type = 'phone', String? authToken}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _authService.sendVerificationToken(
        type: type, 
        authToken: authToken,
      );
      
      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to send verification code';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> refreshUser() async {
    if (_user?.authToken != null) {
      try {
        // Call a profile endpoint to get updated user data
        // For now, we'll just keep the existing user as is
        // In a real implementation, you'd call an API to get fresh user data
        notifyListeners();
      } catch (e) {
        // Handle error silently or show a message
        debugPrint('Failed to refresh user: $e');
      }
    }
  }
  
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}