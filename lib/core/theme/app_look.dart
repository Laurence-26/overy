import 'package:flutter/material.dart';

/// Visual identity the user can pick. Five girl-forward looks.
enum AppLook {
  blossom,
  lavender,
  peach,
  roseGold,
  mint;

  String get id => name;

  static AppLook fromId(String? raw) {
    for (final v in AppLook.values) {
      if (v.id == raw) return v;
    }
    return AppLook.blossom;
  }

  String get title => switch (this) {
        AppLook.blossom => 'Blossom Pink',
        AppLook.lavender => 'Lavender Garden',
        AppLook.peach => 'Peach Cream',
        AppLook.roseGold => 'Rose Gold',
        AppLook.mint => 'Mint Petals',
      };

  String get subtitle => switch (this) {
        AppLook.blossom => 'Soft petals & warm blush',
        AppLook.lavender => 'Dreamy florals in purple mist',
        AppLook.peach => 'Sunny peach & cream',
        AppLook.roseGold => 'Elegant rose with gold glow',
        AppLook.mint => 'Fresh mint leaves & pink tips',
      };

  /// Motif drawn behind screens.
  AppMotif get motif => switch (this) {
        AppLook.blossom => AppMotif.flowers,
        AppLook.lavender => AppMotif.lavender,
        AppLook.peach => AppMotif.hearts,
        AppLook.roseGold => AppMotif.sparkles,
        AppLook.mint => AppMotif.leaves,
      };
}

enum AppMotif { flowers, lavender, hearts, sparkles, leaves, none }

extension AppMotifX on AppMotif {
  String get title => switch (this) {
        AppMotif.flowers => 'Flowers',
        AppMotif.lavender => 'Lavender sprigs',
        AppMotif.hearts => 'Hearts',
        AppMotif.sparkles => 'Sparkles',
        AppMotif.leaves => 'Leaves',
        AppMotif.none => 'Plain (no pattern)',
      };

  IconData get icon => switch (this) {
        AppMotif.flowers => Icons.local_florist_rounded,
        AppMotif.lavender => Icons.spa_rounded,
        AppMotif.hearts => Icons.favorite_rounded,
        AppMotif.sparkles => Icons.auto_awesome_rounded,
        AppMotif.leaves => Icons.eco_rounded,
        AppMotif.none => Icons.crop_landscape_rounded,
      };
}
