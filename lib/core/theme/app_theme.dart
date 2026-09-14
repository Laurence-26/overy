import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'cyclus_palette.dart';
import '../../models/theme_prefs.dart';

class AppTheme {
  AppTheme._();

  static ThemeData fromPrefs(ThemePrefs prefs) {
    final p = CyclusPalette.of(prefs.look).withOverrides(
      primary: prefs.primaryOverride,
      accent: prefs.accentOverride,
      background: prefs.backgroundOverride,
      cornerRadius: prefs.cornerRadius,
    );
    AppColors.bind(p);
    return _build(p, prefs.textStyle);
  }

  static ThemeData _build(CyclusPalette p, AppTextStylePref textStyle) {
    final base = ThemeData.light(useMaterial3: true);
    final text = base.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
      fontFamily: textStyle.fontFamily,
    );
    final spaced = text.copyWith(
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: textStyle.titleWeight,
        letterSpacing: textStyle.letterSpacing,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontWeight: textStyle.titleWeight,
        letterSpacing: textStyle.letterSpacing,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: textStyle.titleWeight,
        letterSpacing: textStyle.letterSpacing,
      ),
      bodyLarge: text.bodyLarge?.copyWith(
        letterSpacing: textStyle.letterSpacing * 0.5,
      ),
    );
    final r = p.cornerRadius;
    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        primary: p.primary,
        secondary: p.accent,
        surface: p.surface,
        error: p.error,
        brightness: Brightness.light,
      ),
      textTheme: spaced,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: spaced.titleMedium?.copyWith(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: textStyle.titleWeight,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((r - 4).clamp(8, 28)),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: textStyle.titleWeight,
            fontFamily: textStyle.fontFamily,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((r - 4).clamp(8, 28)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: p.textTertiary, fontSize: 14),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular((r - 4).clamp(8, 28)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((r - 4).clamp(8, 28)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((r - 4).clamp(8, 28)),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((r - 4).clamp(8, 28)),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.surfaceAlt,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        selectedColor: p.primaryLight,
        labelStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: textStyle.fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),
    );
  }
}
