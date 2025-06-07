class AppConstants {
  static const String appName = 'Yabalash';
  
  // API Configuration
  static const String apiCode = '2b5f69'; // Company code for yabalash
  
  // Storage keys
  static const String userDataKey = 'userData';
  static const String authTokenKey = 'authToken';
  static const String rememberMeKey = 'rememberMe';
  static const String languageKey = 'language';
  static const String themeKey = 'theme';
  
  // Default values
  static const String defaultLanguage = '1';
  static const String defaultCountryCode = 'IN';
  static const String defaultDialCode = '+91';
  
  // Regex patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\d{6,15}$';
  static const String namePattern = r'^[a-zA-Z\s]{2,50}$';
  
  // Social login providers
  static const String googleProvider = 'google';
  static const String facebookProvider = 'facebook';
  static const String appleProvider = 'apple';
  static const String twitterProvider = 'twitter';
}