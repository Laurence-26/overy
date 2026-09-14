import 'package:flutter/material.dart';

import 'app_look.dart';

/// Full color + shape recipe for one [AppLook].
class CyclusPalette {
  const CyclusPalette({
    required this.look,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.period,
    required this.fertile,
    required this.ovulation,
    required this.predicted,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.error,
    required this.gradientA,
    required this.gradientB,
    required this.softTop,
    required this.softBottom,
    this.cornerRadius = 20,
  });

  final AppLook look;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final Color accentDark;
  final Color accentLight;
  final Color period;
  final Color fertile;
  final Color ovulation;
  final Color predicted;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color warning;
  final Color error;
  final Color gradientA;
  final Color gradientB;
  final Color softTop;
  final Color softBottom;
  final double cornerRadius;

  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientA, primary],
      );

  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentLight, accent],
      );

  LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [softTop, softBottom],
      );

  CyclusPalette withOverrides({
    Color? primary,
    Color? accent,
    Color? background,
    int? cornerRadius,
  }) {
    final p = primary ?? this.primary;
    final a = accent ?? this.accent;
    final bg = background ?? this.background;
    return CyclusPalette(
      look: look,
      primary: p,
      primaryDark: _darken(p, 0.12),
      primaryLight: _lighten(p, 0.28),
      accent: a,
      accentDark: _darken(a, 0.12),
      accentLight: _lighten(a, 0.28),
      period: this.period,
      fertile: fertile,
      ovulation: ovulation,
      predicted: Color.lerp(p, const Color(0xFFFF9A6C), 0.55) ?? this.predicted,
      background: bg,
      surface: surface,
      surfaceAlt: Color.lerp(bg, p, 0.08) ?? surfaceAlt,
      card: card,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      success: success,
      warning: warning,
      error: error,
      gradientA: _lighten(p, 0.12),
      gradientB: p,
      softTop: bg,
      softBottom: Color.lerp(bg, p, 0.10) ?? softBottom,
      cornerRadius: (cornerRadius ?? this.cornerRadius).toDouble(),
    );
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static CyclusPalette of(AppLook look) => switch (look) {
        AppLook.blossom => blossom,
        AppLook.lavender => lavender,
        AppLook.peach => peach,
        AppLook.roseGold => roseGold,
        AppLook.mint => mint,
      };

  static const blossom = CyclusPalette(
    look: AppLook.blossom,
    primary: Color(0xFFFF6B9D),
    primaryDark: Color(0xFFE94B7C),
    primaryLight: Color(0xFFFFB3CC),
    accent: Color(0xFFA78BFA),
    accentDark: Color(0xFF7C6CE0),
    accentLight: Color(0xFFD6CAFF),
    period: Color(0xFFE94B7C),
    fertile: Color(0xFF8AC8B8),
    ovulation: Color(0xFF5BB4A0),
    predicted: Color(0xFFFF9A6C),
    background: Color(0xFFFFF5F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFDEEF2),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1228),
    textSecondary: Color(0xFF4A4258),
    textTertiary: Color(0xFF7A7288),
    success: Color(0xFF6BCFA0),
    warning: Color(0xFFFFB347),
    error: Color(0xFFFF6B6B),
    gradientA: Color(0xFFFF8FA3),
    gradientB: Color(0xFFFF6B9D),
    softTop: Color(0xFFFFF5F7),
    softBottom: Color(0xFFFDEEF2),
    cornerRadius: 20,
  );

  static const lavender = CyclusPalette(
    look: AppLook.lavender,
    primary: Color(0xFF9B7EDE),
    primaryDark: Color(0xFF7B5CC8),
    primaryLight: Color(0xFFD4C4F5),
    accent: Color(0xFFE8A0BF),
    accentDark: Color(0xFFD47A9E),
    accentLight: Color(0xFFF5D4E4),
    period: Color(0xFFC77DFF),
    fertile: Color(0xFF9AD4C8),
    ovulation: Color(0xFF6BBFB0),
    predicted: Color(0xFFE8A070),
    background: Color(0xFFF7F3FF),
    surface: Color(0xFFFFFBFF),
    surfaceAlt: Color(0xFFEEE6FA),
    card: Color(0xFFFFFBFF),
    textPrimary: Color(0xFF1A1228),
    textSecondary: Color(0xFF4A4258),
    textTertiary: Color(0xFF7A7288),
    success: Color(0xFF7BCFBC),
    warning: Color(0xFFFFC46B),
    error: Color(0xFFE87A9A),
    gradientA: Color(0xFFB89AE8),
    gradientB: Color(0xFF9B7EDE),
    softTop: Color(0xFFF7F3FF),
    softBottom: Color(0xFFEDE4FA),
    cornerRadius: 24,
  );

  static const peach = CyclusPalette(
    look: AppLook.peach,
    primary: Color(0xFFFF8A65),
    primaryDark: Color(0xFFE86A45),
    primaryLight: Color(0xFFFFC4B0),
    accent: Color(0xFFFFB4C8),
    accentDark: Color(0xFFE88AA8),
    accentLight: Color(0xFFFFDCE6),
    period: Color(0xFFFF7A8A),
    fertile: Color(0xFF9DC9A5),
    ovulation: Color(0xFF6FB383),
    predicted: Color(0xFFFFA070),
    background: Color(0xFFFFF8F2),
    surface: Color(0xFFFFFCF9),
    surfaceAlt: Color(0xFFFFEDE3),
    card: Color(0xFFFFFCF9),
    textPrimary: Color(0xFF1A1228),
    textSecondary: Color(0xFF4A4258),
    textTertiary: Color(0xFF7A7288),
    success: Color(0xFF7BC99A),
    warning: Color(0xFFFFB347),
    error: Color(0xFFFF6B6B),
    gradientA: Color(0xFFFFA07A),
    gradientB: Color(0xFFFF8A65),
    softTop: Color(0xFFFFF8F2),
    softBottom: Color(0xFFFFE8DC),
    cornerRadius: 18,
  );

  static const roseGold = CyclusPalette(
    look: AppLook.roseGold,
    primary: Color(0xFFD4A5A5),
    primaryDark: Color(0xFFB87E7E),
    primaryLight: Color(0xFFE8CDCD),
    accent: Color(0xFFC9A66B),
    accentDark: Color(0xFFA88445),
    accentLight: Color(0xFFE8D5A8),
    period: Color(0xFFC97B84),
    fertile: Color(0xFFA8C5B0),
    ovulation: Color(0xFF7FA88E),
    predicted: Color(0xFFE0A070),
    background: Color(0xFFFFF6F4),
    surface: Color(0xFFFFFBFA),
    surfaceAlt: Color(0xFFF5E8E4),
    card: Color(0xFFFFFBFA),
    textPrimary: Color(0xFF1A1228),
    textSecondary: Color(0xFF4A4258),
    textTertiary: Color(0xFF7A7288),
    success: Color(0xFF8CB89A),
    warning: Color(0xFFD4B06A),
    error: Color(0xFFC96B6B),
    gradientA: Color(0xFFE0B8B8),
    gradientB: Color(0xFFD4A5A5),
    softTop: Color(0xFFFFF6F4),
    softBottom: Color(0xFFF3E6E0),
    cornerRadius: 16,
  );

  static const mint = CyclusPalette(
    look: AppLook.mint,
    primary: Color(0xFF5EBEA8),
    primaryDark: Color(0xFF3FA08A),
    primaryLight: Color(0xFFB0E4D8),
    accent: Color(0xFFFF8FB5),
    accentDark: Color(0xFFE86B95),
    accentLight: Color(0xFFFFD0E0),
    period: Color(0xFFFF7A9E),
    fertile: Color(0xFF6BCFB5),
    ovulation: Color(0xFF3DB89A),
    predicted: Color(0xFFFF9E78),
    background: Color(0xFFF3FBF8),
    surface: Color(0xFFFAFFFD),
    surfaceAlt: Color(0xFFE4F5EF),
    card: Color(0xFFFAFFFD),
    textPrimary: Color(0xFF1A1228),
    textSecondary: Color(0xFF4A4258),
    textTertiary: Color(0xFF7A7288),
    success: Color(0xFF5EBEA8),
    warning: Color(0xFFFFB347),
    error: Color(0xFFFF6B8A),
    gradientA: Color(0xFF7ED4C0),
    gradientB: Color(0xFF5EBEA8),
    softTop: Color(0xFFF3FBF8),
    softBottom: Color(0xFFE0F3EC),
    cornerRadius: 22,
  );
}
