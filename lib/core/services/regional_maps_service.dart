import 'package:flutter/foundation.dart';

/// Regional Maps Service
/// Handles region-specific Google Maps configuration to ensure
/// appropriate political views are shown based on the user's location
class RegionalMapsService {
  
  /// Arab countries that should see Palestine instead of Israel
  static const List<String> arabCountries = [
    'AE', // UAE
    'SA', // Saudi Arabia
    'QA', // Qatar
    'KW', // Kuwait
    'BH', // Bahrain
    'OM', // Oman
    'JO', // Jordan
    'LB', // Lebanon
    'SY', // Syria
    'IQ', // Iraq
    'EG', // Egypt
    'LY', // Libya
    'TN', // Tunisia
    'DZ', // Algeria
    'MA', // Morocco
    'SD', // Sudan
    'YE', // Yemen
    'PS', // Palestine
  ];
  
  /// Get the appropriate Google Maps configuration for the region
  static Map<String, dynamic> getRegionalConfiguration() {
    return {
      'region': 'AE', // UAE region code - this helps Google show Palestine
      'language': 'ar', // Arabic language
      'useRegionalView': true,
    };
  }
  
  /// Check if the app is running in an Arab region
  static bool isArabRegion() {
    // You can implement location detection here
    // For now, assume true since the app is for UAE
    return true;
  }
  
  /// Get map initialization parameters for Arab regions
  static Map<String, dynamic> getMapInitParams() {
    if (isArabRegion()) {
      return {
        'region': 'AE',
        'language': 'ar',
        'components': 'country:AE|country:SA|country:QA|country:KW|country:BH|country:OM',
      };
    }
    return {};
  }
  
  /// Log safety information
  static void logMapSafetyInfo() {
    if (kDebugMode) {
      debugPrint('🌍 Regional Maps Service: Using Arab region configuration');
      debugPrint('🌍 This should show Palestine instead of Israel');
      debugPrint('🌍 Region: UAE (AE)');
      debugPrint('🌍 Language: Arabic (ar)');
    }
  }
}