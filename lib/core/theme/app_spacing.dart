import 'package:flutter_screenutil/flutter_screenutil.dart';

/// App-wide spacing constants following 4/8-point grid system
/// Use these constants for consistent spacing throughout the app
class AppSpacing {
  // Base spacing values
  static const double xs = 4.0;   // Extra small
  static const double sm = 8.0;   // Small
  static const double md = 16.0;  // Medium (default)
  static const double lg = 24.0;  // Large
  static const double xl = 32.0;  // Extra large
  static const double xxl = 48.0; // Extra extra large
  
  // Responsive spacing helpers
  static double xsW = xs.w;
  static double smW = sm.w;
  static double mdW = md.w;
  static double lgW = lg.w;
  static double xlW = xl.w;
  static double xxlW = xxl.w;
  
  static double xsH = xs.h;
  static double smH = sm.h;
  static double mdH = md.h;
  static double lgH = lg.h;
  static double xlH = xl.h;
  static double xxlH = xxl.h;
  
  // Common padding values
  static double cardPadding = md.w;
  static double screenPadding = md.w;
  static double sectionPadding = lg.w;
  
  // Common margin values
  static double cardMargin = sm.w;
  static double sectionMargin = md.h;
  
  // List item spacing
  static double listItemVertical = 12.h;
  static double listItemHorizontal = md.w;
  
  // Button spacing
  static double buttonPaddingHorizontal = md.w;
  static double buttonPaddingVertical = 14.h;
  
  // Icon spacing
  static double iconTextGap = sm.w;
}