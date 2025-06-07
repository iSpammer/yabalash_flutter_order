import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get rememberMe => _rememberMe;
  bool get isLoggedIn => _user != null;
  bool get isAuthenticated => _user != null;
  String? get authToken => _user?.authToken;
  
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
  
  Future<Map<String, dynamic>?> getRememberMeCredentials() async {
    return await _authService.getRememberMeCredentials();
  }
  
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}