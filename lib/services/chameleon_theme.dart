import '../core/theme/app_look.dart';
import '../models/cycle_prediction.dart';
import '../models/theme_prefs.dart';

/// Chameleon Code: auto-shifts the look from cycle phase + time of day.
class ChameleonTheme {
  ChameleonTheme._();

  static ThemePrefs resolve(
    ThemePrefs base, {
    required CyclePhase phase,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final hour = t.hour;
    final look = _lookFor(phase, hour);
    final tones = _tonesFor(look, hour);

    return base.copyWith(
      lookId: look.id,
      motifId: look.motif.name,
      primaryArgb: tones.primary,
      accentArgb: tones.accent,
      backgroundArgb: tones.background,
      // Keep her photo; nudge strength so evening/night stays softer.
      backgroundImageStrength: _imageStrength(base, hour),
    );
  }

  static String statusLabel(CyclePhase phase, DateTime now) {
    final slot = _slot(now.hour);
    final phaseName = switch (phase) {
      CyclePhase.period => 'period',
      CyclePhase.fertile => 'fertile',
      CyclePhase.ovulation => 'ovulation',
      CyclePhase.predicted => 'pre-period',
      CyclePhase.follicular => 'follicular',
      CyclePhase.luteal => 'luteal',
      CyclePhase.unknown => 'your cycle',
    };
    return 'Matching $phaseName · $slot';
  }

  static AppLook _lookFor(CyclePhase phase, int hour) {
    final night = hour >= 21 || hour < 5;
    return switch (phase) {
      CyclePhase.period => night ? AppLook.roseGold : AppLook.blossom,
      CyclePhase.fertile || CyclePhase.ovulation =>
        night ? AppLook.mint : AppLook.peach,
      CyclePhase.follicular => AppLook.peach,
      CyclePhase.luteal || CyclePhase.predicted =>
        night ? AppLook.lavender : AppLook.lavender,
      CyclePhase.unknown => night ? AppLook.lavender : AppLook.blossom,
    };
  }

  static String _slot(int hour) {
    if (hour >= 5 && hour < 11) return 'morning light';
    if (hour >= 11 && hour < 17) return 'day glow';
    if (hour >= 17 && hour < 21) return 'evening warmth';
    return 'night calm';
  }

  static double _imageStrength(ThemePrefs base, int hour) {
    final user = base.backgroundImageStrength;
    if (!base.hasCustomImage) return user;
    // Night: slightly softer so features stay readable; day: honor her setting.
    if (hour >= 21 || hour < 5) return (user * 0.82).clamp(0.15, 1.0);
    if (hour >= 17) return (user * 0.92).clamp(0.2, 1.0);
    return user.clamp(0.15, 1.0);
  }

  static ({int primary, int accent, int background}) _tonesFor(
    AppLook look,
    int hour,
  ) {
    // Time-tinted accents on top of the chosen look family.
    final morning = hour >= 5 && hour < 11;
    final evening = hour >= 17 && hour < 21;
    final night = hour >= 21 || hour < 5;

    return switch (look) {
      AppLook.blossom => (
          primary: morning
              ? 0xFFFF7A9A
              : night
                  ? 0xFFE85A8A
                  : 0xFFFF6B9D,
          accent: evening || night ? 0xFFBFA9FF : 0xFFA78BFA,
          background: night
              ? 0xFFF3E8EF
              : morning
                  ? 0xFFFFF8FA
                  : 0xFFFFF5F7,
        ),
      AppLook.lavender => (
          primary: night ? 0xFF8B6FD4 : 0xFF9B7EDE,
          accent: 0xFFE8A0BF,
          background: night ? 0xFFEFE8F8 : 0xFFF7F3FF,
        ),
      AppLook.peach => (
          primary: morning ? 0xFFFF9A70 : 0xFFFF8A65,
          accent: 0xFFFFB4C8,
          background: night ? 0xFFF8EEE8 : 0xFFFFF8F2,
        ),
      AppLook.roseGold => (
          primary: 0xFFD4A5A5,
          accent: night ? 0xFFC9A66B : 0xFFE0B87A,
          background: night ? 0xFFF3EBE8 : 0xFFFFF6F4,
        ),
      AppLook.mint => (
          primary: morning ? 0xFF4DB89E : 0xFF5EBEA8,
          accent: 0xFFFF8FB5,
          background: night ? 0xFFE8F5F1 : 0xFFF3FBF8,
        ),
    };
  }
}
