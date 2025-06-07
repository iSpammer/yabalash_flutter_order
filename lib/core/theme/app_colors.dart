import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFFE91E63); // Pink color matching Yabalash brand
  static const Color primaryColorLight = Color(0xFFF48FB1);
  static const Color primaryColorDark = Color(0xFFC2185B);
  
  // Secondary Colors
  static const Color secondaryColor = Color(0xFF4CAF50); // Green for success states
  static const Color accentColor = Color(0xFFFF5722); // Orange for accents
  
  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color infoColor = Color(0xFF1976D2);
  static const Color successColor = Color(0xFF388E3C);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;
  
  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFBDBDBD);
  
  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);
  
  // Status Colors
  static const Color pendingColor = Color(0xFFFFA726);
  static const Color processingColor = Color(0xFF42A5F5);
  static const Color deliveredColor = Color(0xFF66BB6A);
  static const Color cancelledColor = Color(0xFFEF5350);
  
  // Rating Colors
  static const Color ratingStarColor = Color(0xFFFFB400);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryColorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dark Theme Colors (if needed)
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
}