import 'package:flutter/material.dart';

import 'cyclus_palette.dart';

/// Active palette. Screens keep calling [AppColors.primary] etc.;
/// [ThemeController] swaps the bound palette when she picks a look.
class AppColors {
  AppColors._();

  static CyclusPalette _p = CyclusPalette.blossom;

  static CyclusPalette get palette => _p;

  static void bind(CyclusPalette palette) {
    _p = palette;
  }

  static Color get primary => _p.primary;
  static Color get primaryDark => _p.primaryDark;
  static Color get primaryLight => _p.primaryLight;
  static Color get accent => _p.accent;
  static Color get accentDark => _p.accentDark;
  static Color get accentLight => _p.accentLight;
  static Color get period => _p.period;
  static Color get fertile => _p.fertile;
  static Color get ovulation => _p.ovulation;
  static Color get predicted => _p.predicted;

  /// Soft sky blue — clearly different from light predicted pink/peach.
  static const Color safe = Color(0xFF6BA3C7);

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceAlt => _p.surfaceAlt;
  static Color get card => _p.card;
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textTertiary => _p.textTertiary;
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static Color get success => _p.success;
  static Color get warning => _p.warning;
  static Color get error => _p.error;

  static LinearGradient get primaryGradient => _p.primaryGradient;
  static LinearGradient get accentGradient => _p.accentGradient;
  static LinearGradient get softGradient => _p.softGradient;

  static Color get softTop => _p.softTop;
  static Color get softBottom => _p.softBottom;

  static double get cornerRadius => _p.cornerRadius;
}
