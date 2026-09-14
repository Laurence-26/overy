import 'package:flutter/material.dart';

import '../core/theme/app_look.dart';

/// User-editable look preferences (on top of a base preset).
class ThemePrefs {
  final String lookId;
  final String motifId;
  final String textStyleId;
  final int cornerRadius;
  final bool showBackground;
  final int? primaryArgb;
  final int? accentArgb;
  final int? backgroundArgb;

  /// Absolute path to a user-uploaded background image (on-device only).
  final String? backgroundImagePath;

  /// How strongly the photo shows (0 = hidden, 1 = vivid). Soft wash overlay
  /// keeps text readable.
  final double backgroundImageStrength;

  /// Chameleon Code: auto-shift colors from cycle phase + time of day.
  final bool chameleonEnabled;

  /// How the cycle hero is shown: flower ring or rectangular card.
  final String cycleViewId;

  const ThemePrefs({
    this.lookId = 'blossom',
    this.motifId = 'flowers',
    this.textStyleId = 'soft',
    this.cornerRadius = 20,
    this.showBackground = true,
    this.primaryArgb,
    this.accentArgb,
    this.backgroundArgb,
    this.backgroundImagePath,
    this.backgroundImageStrength = 0.55,
    this.chameleonEnabled = false,
    this.cycleViewId = 'flower',
  });

  AppLook get look => AppLook.fromId(lookId);

  CycleViewStyle get cycleView => CycleViewStyle.fromId(cycleViewId);

  AppMotif get motif {
    for (final m in AppMotif.values) {
      if (m.name == motifId) return m;
    }
    return look.motif;
  }

  AppTextStylePref get textStyle => AppTextStylePref.fromId(textStyleId);

  Color? get primaryOverride =>
      primaryArgb == null ? null : Color(primaryArgb!);
  Color? get accentOverride => accentArgb == null ? null : Color(accentArgb!);
  Color? get backgroundOverride =>
      backgroundArgb == null ? null : Color(backgroundArgb!);

  bool get hasCustomImage =>
      backgroundImagePath != null && backgroundImagePath!.isNotEmpty;

  ThemePrefs copyWith({
    String? lookId,
    String? motifId,
    String? textStyleId,
    int? cornerRadius,
    bool? showBackground,
    int? primaryArgb,
    int? accentArgb,
    int? backgroundArgb,
    String? backgroundImagePath,
    double? backgroundImageStrength,
    bool? chameleonEnabled,
    String? cycleViewId,
    bool clearPrimary = false,
    bool clearAccent = false,
    bool clearBackground = false,
    bool clearImage = false,
  }) {
    return ThemePrefs(
      lookId: lookId ?? this.lookId,
      motifId: motifId ?? this.motifId,
      textStyleId: textStyleId ?? this.textStyleId,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      showBackground: showBackground ?? this.showBackground,
      primaryArgb: clearPrimary ? null : (primaryArgb ?? this.primaryArgb),
      accentArgb: clearAccent ? null : (accentArgb ?? this.accentArgb),
      backgroundArgb:
          clearBackground ? null : (backgroundArgb ?? this.backgroundArgb),
      backgroundImagePath: clearImage
          ? null
          : (backgroundImagePath ?? this.backgroundImagePath),
      backgroundImageStrength:
          backgroundImageStrength ?? this.backgroundImageStrength,
      chameleonEnabled: chameleonEnabled ?? this.chameleonEnabled,
      cycleViewId: cycleViewId ?? this.cycleViewId,
    );
  }

  Map<String, dynamic> toMap() => {
        'lookId': lookId,
        'motifId': motifId,
        'textStyleId': textStyleId,
        'cornerRadius': cornerRadius,
        'showBackground': showBackground,
        'primaryArgb': primaryArgb,
        'accentArgb': accentArgb,
        'backgroundArgb': backgroundArgb,
        'backgroundImagePath': backgroundImagePath,
        'backgroundImageStrength': backgroundImageStrength,
        'chameleonEnabled': chameleonEnabled,
        'cycleViewId': cycleViewId,
      };

  factory ThemePrefs.fromMap(Map<String, dynamic>? m, {String? fallbackLook}) {
    if (m == null || m.isEmpty) {
      final look = AppLook.fromId(fallbackLook);
      return ThemePrefs(
        lookId: look.id,
        motifId: look.motif.name,
      );
    }
    final look =
        AppLook.fromId((m['lookId'] as String?) ?? fallbackLook ?? 'blossom');
    return ThemePrefs(
      lookId: look.id,
      motifId: m['motifId'] as String? ?? look.motif.name,
      textStyleId: m['textStyleId'] as String? ?? 'soft',
      cornerRadius: (m['cornerRadius'] as num?)?.round() ?? 20,
      showBackground: m['showBackground'] as bool? ?? true,
      primaryArgb: m['primaryArgb'] as int?,
      accentArgb: m['accentArgb'] as int?,
      backgroundArgb: m['backgroundArgb'] as int?,
      backgroundImagePath: m['backgroundImagePath'] as String?,
      backgroundImageStrength:
          (m['backgroundImageStrength'] as num?)?.toDouble() ?? 0.55,
      chameleonEnabled: m['chameleonEnabled'] as bool? ?? false,
      cycleViewId: m['cycleViewId'] as String? ?? 'flower',
    );
  }

  static ThemePrefs fromLook(AppLook look) => ThemePrefs(
        lookId: look.id,
        motifId: look.motif.name,
      );
}

enum CycleViewStyle {
  flower,
  card;

  String get id => name;

  static CycleViewStyle fromId(String? raw) {
    for (final v in CycleViewStyle.values) {
      if (v.id == raw) return v;
    }
    return CycleViewStyle.flower;
  }

  String get title => switch (this) {
        CycleViewStyle.flower => 'Flower',
        CycleViewStyle.card => 'Card',
      };

  IconData get icon => switch (this) {
        CycleViewStyle.flower => Icons.local_florist_rounded,
        CycleViewStyle.card => Icons.crop_landscape_rounded,
      };
}

enum AppTextStylePref {
  soft,
  elegant,
  bold,
  airy,
  playful;

  String get id => name;

  static AppTextStylePref fromId(String? raw) {
    for (final v in AppTextStylePref.values) {
      if (v.id == raw) return v;
    }
    return AppTextStylePref.soft;
  }

  String get title => switch (this) {
        AppTextStylePref.soft => 'Soft',
        AppTextStylePref.elegant => 'Elegant',
        AppTextStylePref.bold => 'Bold',
        AppTextStylePref.airy => 'Airy',
        AppTextStylePref.playful => 'Playful',
      };

  String get subtitle => switch (this) {
        AppTextStylePref.soft => 'Clean and gentle',
        AppTextStylePref.elegant => 'Serif, magazine feel',
        AppTextStylePref.bold => 'Strong headings',
        AppTextStylePref.airy => 'Light with more space',
        AppTextStylePref.playful => 'Rounded and friendly',
      };

  String get fontFamily => switch (this) {
        AppTextStylePref.soft => 'Segoe UI',
        AppTextStylePref.elegant => 'Georgia',
        AppTextStylePref.bold => 'Segoe UI',
        AppTextStylePref.airy => 'Segoe UI',
        AppTextStylePref.playful => 'Trebuchet MS',
      };

  FontWeight get titleWeight => switch (this) {
        AppTextStylePref.bold => FontWeight.w800,
        AppTextStylePref.airy => FontWeight.w500,
        AppTextStylePref.playful => FontWeight.w700,
        _ => FontWeight.w600,
      };

  double get letterSpacing => switch (this) {
        AppTextStylePref.airy => 0.6,
        AppTextStylePref.playful => 0.2,
        AppTextStylePref.elegant => 0.15,
        _ => 0.0,
      };
}

class ThemeColorSwatches {
  static const primaries = <Color>[
    Color(0xFFFF6B9D),
    Color(0xFF9B7EDE),
    Color(0xFFFF8A65),
    Color(0xFFD4A5A5),
    Color(0xFF5EBEA8),
    Color(0xFFFF7A8A),
    Color(0xFFE8A0BF),
    Color(0xFF7C6CE0),
    Color(0xFFFFB4C8),
    Color(0xFFC9A66B),
  ];

  static const accents = <Color>[
    Color(0xFFA78BFA),
    Color(0xFFE8A0BF),
    Color(0xFFFFB4C8),
    Color(0xFFC9A66B),
    Color(0xFFFF8FB5),
    Color(0xFF8AC8B8),
    Color(0xFF5BB4A0),
    Color(0xFFBFA9FF),
    Color(0xFFFFC4B0),
    Color(0xFF7FA88E),
  ];

  static const backgrounds = <Color>[
    Color(0xFFFFF5F7),
    Color(0xFFF7F3FF),
    Color(0xFFFFF8F2),
    Color(0xFFFFF6F4),
    Color(0xFFF3FBF8),
    Color(0xFFFFF0F5),
    Color(0xFFF5F0FF),
    Color(0xFFFFF5EE),
    Color(0xFFF0FFF8),
    Color(0xFFFFFAF5),
  ];
}
