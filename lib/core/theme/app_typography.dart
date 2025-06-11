import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide typography constants for consistent text styling
class AppTypography {
  // Base font family
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;
  
  // Headline styles
  static TextStyle headline1 = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  
  static TextStyle headline2 = TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  
  static TextStyle headline3 = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static TextStyle headline4 = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body styles
  static TextStyle body1 = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle body2 = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  // Caption style
  static TextStyle caption = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  // Button style
  static TextStyle button = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  // Small button style
  static TextStyle buttonSmall = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  // Overline style
  static TextStyle overline = TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 1.0,
  );
  
  // Price styles
  static TextStyle priceSmall = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static TextStyle priceMedium = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  
  static TextStyle priceLarge = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  
  // Helper method to apply font family to any TextStyle
  static TextStyle withFont(TextStyle style) {
    return GoogleFonts.poppins(textStyle: style);
  }
  
  // Pre-configured text themes
  static TextTheme textTheme = TextTheme(
    displayLarge: headline1,
    displayMedium: headline2,
    displaySmall: headline3,
    headlineMedium: headline4,
    bodyLarge: body1,
    bodyMedium: body2,
    bodySmall: caption,
    labelLarge: button,
    labelSmall: overline,
  );
}