import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_look.dart';
import '../core/theme/cyclus_palette.dart';
import '../models/cycle_prediction.dart';
import '../models/theme_prefs.dart';
import '../services/chameleon_theme.dart';

/// Holds the active visual look + user overrides and keeps [AppColors] in sync.
class ThemeController extends ChangeNotifier {
  ThemeController([ThemePrefs prefs = const ThemePrefs()]) {
    _userPrefs = prefs;
    applyPrefs(prefs, notify: false);
  }

  ThemePrefs _userPrefs = const ThemePrefs();
  ThemePrefs _prefs = const ThemePrefs();
  late CyclusPalette _palette;
  CyclePhase _phase = CyclePhase.unknown;
  Timer? _chameleonTick;
  String? _chameleonStatus;

  /// Saved prefs (what she edits / stores on profile).
  ThemePrefs get userPrefs => _userPrefs;

  /// Effective prefs currently painted (may include Chameleon Code).
  ThemePrefs get prefs => _prefs;
  AppLook get look => _prefs.look;
  AppMotif get motif => _prefs.showBackground ? _prefs.motif : AppMotif.none;
  AppTextStylePref get textStyle => _prefs.textStyle;
  CyclusPalette get palette => _palette;
  String? get backgroundImagePath => _prefs.backgroundImagePath;
  double get backgroundImageStrength => _prefs.backgroundImageStrength;
  bool get chameleonEnabled => _userPrefs.chameleonEnabled;
  String? get chameleonStatus => _chameleonStatus;
  CycleViewStyle get cycleView => _userPrefs.cycleView;

  Future<void> setCycleView(CycleViewStyle view) async {
    applyUserPrefs(_userPrefs.copyWith(cycleViewId: view.id));
  }

  void applyPrefs(ThemePrefs prefs, {bool notify = true}) {
    _prefs = prefs;
    _palette = CyclusPalette.of(prefs.look).withOverrides(
      primary: prefs.primaryOverride,
      accent: prefs.accentOverride,
      background: prefs.backgroundOverride,
      cornerRadius: prefs.cornerRadius,
    );
    AppColors.bind(_palette);
    if (notify) notifyListeners();
  }

  /// Apply edits from Theme Studio (updates the stored baseline).
  void applyUserPrefs(ThemePrefs prefs, {CyclePhase? phase}) {
    _userPrefs = prefs;
    if (phase != null) _phase = phase;
    _recompute(notify: true);
  }

  void setLook(AppLook look) {
    applyUserPrefs(ThemePrefs.fromLook(look).copyWith(
      textStyleId: _userPrefs.textStyleId,
      cornerRadius: _userPrefs.cornerRadius,
      showBackground: _userPrefs.showBackground,
      primaryArgb: _userPrefs.primaryArgb,
      accentArgb: _userPrefs.accentArgb,
      backgroundArgb: _userPrefs.backgroundArgb,
      backgroundImagePath: _userPrefs.backgroundImagePath,
      backgroundImageStrength: _userPrefs.backgroundImageStrength,
      chameleonEnabled: _userPrefs.chameleonEnabled,
      cycleViewId: _userPrefs.cycleViewId,
      motifId: look.motif.name,
    ));
  }

  void patch(ThemePrefs Function(ThemePrefs p) fn) {
    applyUserPrefs(fn(_userPrefs));
  }

  void syncFromProfile({
    String? themeId,
    Map<String, dynamic>? themePrefs,
    CyclePhase? phase,
  }) {
    _userPrefs = ThemePrefs.fromMap(themePrefs, fallbackLook: themeId);
    if (phase != null) _phase = phase;
    _recompute(notify: true);
    _ensureTicker();
  }

  /// Call when cycle phase may have changed (Today screen / app resume).
  void updateCyclePhase(CyclePhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    if (chameleonEnabled) _recompute(notify: true);
  }

  void _recompute({required bool notify}) {
    if (_userPrefs.chameleonEnabled) {
      final resolved = ChameleonTheme.resolve(
        _userPrefs,
        phase: _phase,
        now: DateTime.now(),
      );
      _chameleonStatus =
          ChameleonTheme.statusLabel(_phase, DateTime.now());
      applyPrefs(resolved, notify: notify);
    } else {
      _chameleonStatus = null;
      applyPrefs(_userPrefs, notify: notify);
    }
  }

  void _ensureTicker() {
    _chameleonTick?.cancel();
    if (!_userPrefs.chameleonEnabled) return;
    _chameleonTick = Timer.periodic(const Duration(minutes: 10), (_) {
      _recompute(notify: true);
    });
  }

  @override
  void dispose() {
    _chameleonTick?.cancel();
    super.dispose();
  }
}
