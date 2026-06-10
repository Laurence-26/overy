import 'package:flutter/material.dart';

/// Centralized color palette inspired by soft, modern femtech design.
/// Warm pinks for periods, cool lavenders for predictions, soft creams for surfaces.
class AppColors {
  AppColors._();

  // Primary brand
  static const Color primary = Color(0xFFFF6B9D);
  static const Color primaryDark = Color(0xFFE94B7C);
  static const Color primaryLight = Color(0xFFFFB3CC);

  // Secondary / accent
  static const Color accent = Color(0xFFA78BFA);
  static const Color accentDark = Color(0xFF7C6CE0);
  static const Color accentLight = Color(0xFFD6CAFF);

  // Cycle phase colors
  static const Color period = Color(0xFFE94B7C);
  static const Color fertile = Color(0xFF8AC8B8);
  static const Color ovulation = Color(0xFF5BB4A0);
  static const Color predicted = Color(0xFFFFC4D6);

  // Surfaces
  static const Color background = Color(0xFFFFF5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFDEEF2);
  static const Color card = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF2D2438);
  static const Color textSecondary = Color(0xFF6B6478);
  static const Color textTertiary = Color(0xFFA39CB0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF6BCFA0);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFFF6B6B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8FA3), Color(0xFFFF6B9D)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBFA9FF), Color(0xFFA78BFA)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF5F7), Color(0xFFFDEEF2)],
  );
}
