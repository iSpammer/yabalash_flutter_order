/// Application configuration constants
/// Contains settings for compliance, features, and regional requirements
class AppConfig {
  /// Government compliance settings
  static const bool enforceGovernmentCompliance = true;
  static const bool hideCountryLabels = true;
  static const bool hideAdministrativeBoundaries = true;
  static const bool hidePoliticalEntities = true;
  
  /// Map configuration for safety and legal compliance
  static const bool useGovernmentCompliantMaps = true;
  static const bool hideAllCountryNames = true;
  static const bool hideProvinceLabels = true;
  static const bool hidePOILabels = true;
  
  /// Regional settings
  static const String defaultCountry = 'United Arab Emirates';
  static const String defaultLanguage = '1'; // Arabic/English
  
  /// API configuration
  static const bool restrictPoliticalGeocoding = true;
  static const bool filterSensitiveLocationData = true;
  
  /// Safety features
  static const bool enableLocationPrivacy = true;
  static const bool maskSensitiveAreas = true;
  
  /// Get map style configuration based on app settings
  static Map<String, dynamic> getMapConfiguration() {
    return {
      'governmentCompliant': useGovernmentCompliantMaps,
      'hideCountryLabels': hideCountryLabels,
      'hideAdministrativeBoundaries': hideAdministrativeBoundaries,
      'hidePoliticalEntities': hidePoliticalEntities,
      'minimal': enforceGovernmentCompliance,
    };
  }
  
  /// Check if government compliance mode is active
  static bool get isGovernmentComplianceEnabled => enforceGovernmentCompliance;
  
  /// Check if maps should use safe mode
  static bool get shouldUseSafeMaps => useGovernmentCompliantMaps;
}