import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_look.dart';
import '../core/theme/cyclus_palette.dart';
import '../models/theme_prefs.dart';
import '../models/user_profile.dart';
import '../providers/cycle_provider.dart';
import '../providers/theme_provider.dart';
import '../services/theme_background_store.dart';
import '../widgets/gradient_button.dart';

/// Modern theme studio with live preview, animations, and photo backgrounds.
class ThemeStudioScreen extends StatefulWidget {
  const ThemeStudioScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ThemeStudioScreen> createState() => _ThemeStudioScreenState();
}

enum _StudioTab { chameleon, presets, colors, background, style }

class _ThemeStudioScreenState extends State<ThemeStudioScreen>
    with TickerProviderStateMixin {
  late ThemePrefs _draft;
  bool _saving = false;
  bool _pickingImage = false;
  _StudioTab _tab = _StudioTab.presets;

  late final AnimationController _previewPulse;
  late final AnimationController _tabFade;

  static const _titleInk = Color(0xFF1A1228);
  static const _bodyInk = Color(0xFF3D3550);
  static const _mutedInk = Color(0xFF5C5470);
  static const _pageBg = Color(0xFFFFF8FA);
  static const _card = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _draft = ThemePrefs.fromMap(
      widget.profile.themePrefs,
      fallbackLook: widget.profile.themeId,
    );
    _previewPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _tabFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
  }

  @override
  void dispose() {
    _previewPulse.dispose();
    _tabFade.dispose();
    super.dispose();
  }

  Future<void> _applyLive(ThemePrefs next) async {
    setState(() => _draft = next);
    context.read<ThemeController>().applyUserPrefs(next);
    _previewPulse
      ..reset()
      ..forward();
  }

  Future<void> _switchTab(_StudioTab tab) async {
    if (tab == _tab) return;
    await _tabFade.reverse();
    if (!mounted) return;
    setState(() => _tab = tab);
    await _tabFade.forward();
  }

  Future<void> _pickBackground() async {
    setState(() => _pickingImage = true);
    final path = await ThemeBackgroundStore.pickAndSave();
    if (!mounted) return;
    setState(() => _pickingImage = false);
    if (path == null) return;
    await _applyLive(_draft.copyWith(
      backgroundImagePath: path,
      backgroundImageStrength:
          _draft.hasCustomImage ? _draft.backgroundImageStrength : 0.5,
      showBackground: true,
    ));
  }

  Future<void> _clearBackground() async {
    await ThemeBackgroundStore.clear();
    if (!mounted) return;
    await _applyLive(_draft.copyWith(clearImage: true));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final cycle = context.read<CycleProvider>();
    final theme = context.read<ThemeController>();
    theme.applyUserPrefs(_draft);
    await cycle.updateProfile(widget.profile.copyWith(
      themeId: _draft.lookId,
      themePrefs: _draft.toMap(),
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Look saved'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        foregroundColor: _titleInk,
        elevation: 0,
        title: const Text(
          'Theme studio',
          style: TextStyle(
            color: _titleInk,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: _titleInk),
        actions: [
          TextButton(
            onPressed: () => _applyLive(ThemePrefs.fromLook(AppLook.blossom)),
            child: Text(
              'Reset',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _LivePreview(
                draft: _draft,
                pulse: _previewPulse,
                firstName: () {
                  final n = (widget.profile.displayName ??
                          widget.profile.username ??
                          'you')
                      .trim();
                  if (n.isEmpty) return 'you';
                  return n.split(RegExp(r'\s+')).first;
                }(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TabBar(
                current: _tab,
                onSelect: _switchTab,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _tabFade,
                  curve: Curves.easeOutCubic,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.04, 0.02),
                      end: Offset.zero,
                    ).animate(anim);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: _buildPanel(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: _pageBg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: GradientButton(
              label: 'Save my look',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    switch (_tab) {
      case _StudioTab.chameleon:
        return _ChameleonPanel(draft: _draft, onApply: _applyLive);
      case _StudioTab.presets:
        return _PresetsPanel(draft: _draft, onApply: _applyLive);
      case _StudioTab.colors:
        return _ColorsPanel(draft: _draft, onApply: _applyLive);
      case _StudioTab.background:
        return _BackgroundPanel(
          draft: _draft,
          picking: _pickingImage,
          onApply: _applyLive,
          onPick: _pickBackground,
          onClear: _clearBackground,
        );
      case _StudioTab.style:
        return _StylePanel(draft: _draft, onApply: _applyLive);
    }
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.draft,
    required this.pulse,
    required this.firstName,
  });

  final ThemePrefs draft;
  final AnimationController pulse;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final p = CyclusPalette.of(draft.look).withOverrides(
      primary: draft.primaryOverride,
      accent: draft.accentOverride,
      background: draft.backgroundOverride,
      cornerRadius: draft.cornerRadius,
    );
    final clean = ThemeBackgroundStore.stripCacheBust(draft.backgroundImagePath);
    final hasImage =
        clean != null && ThemeBackgroundStore.exists(draft.backgroundImagePath);
    final strength = draft.backgroundImageStrength.clamp(0.0, 1.0);
    final text = draft.textStyle;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.97, end: 1).animate(
        CurvedAnimation(parent: pulse, curve: Curves.easeOutBack),
      ),
      child: Container(
        height: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: p.primary.withOpacity(0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.gradientA, p.primary, p.accent],
                ),
              ),
            ),
            if (hasImage)
              Opacity(
                opacity: strength,
                child: Image.file(
                  File(clean),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (hasImage)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: const Text(
                          'Live preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(draft.motif.icon, color: Colors.white, size: 20),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Hi, $firstName',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: text.fontFamily,
                      fontWeight: text.titleWeight,
                      letterSpacing: text.letterSpacing,
                      fontSize: 22,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    draft.look.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: text.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            draft.cornerRadius.toDouble().clamp(8, 28)),
                      ),
                      child: Text(
                        'Sample card',
                        style: TextStyle(
                          color: p.primary,
                          fontFamily: text.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});

  final _StudioTab current;
  final ValueChanged<_StudioTab> onSelect;

  static const _labels = {
    _StudioTab.chameleon: 'Auto',
    _StudioTab.presets: 'Presets',
    _StudioTab.colors: 'Colors',
    _StudioTab.background: 'Photo',
    _StudioTab.style: 'Style',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4EA)),
      ),
      child: Row(
        children: [
          for (final tab in _StudioTab.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: current == tab
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: current == tab
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _labels[tab]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: current == tab
                          ? Colors.white
                          : _ThemeStudioScreenState._mutedInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChameleonPanel extends StatelessWidget {
  const _ChameleonPanel({required this.draft, required this.onApply});

  final ThemePrefs draft;
  final Future<void> Function(ThemePrefs) onApply;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _panelCard(
          title: 'Chameleon Code',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auto-shifts your colors from cycle phase and time of day — period pinks, fertile mint, evening calm, morning glow.',
                style: TextStyle(
                  color: _ThemeStudioScreenState._bodyInk,
                  height: 1.45,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.14),
                      AppColors.accent.withOpacity(0.14),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        draft.chameleonEnabled
                            ? (theme.chameleonStatus ?? 'Listening to your cycle…')
                            : 'Off — using your saved look',
                        style: TextStyle(
                          color: _ThemeStudioScreenState._titleInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Enable Chameleon Code',
                  style: TextStyle(
                    color: _ThemeStudioScreenState._titleInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                subtitle: const Text(
                  'Keeps your photo & text style; remaps colors live.',
                  style: TextStyle(
                    color: _ThemeStudioScreenState._mutedInk,
                    fontSize: 12.5,
                  ),
                ),
                value: draft.chameleonEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    onApply(draft.copyWith(chameleonEnabled: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _panelCard(
          title: 'How it reads you',
          child: Column(
            children: const [
              _ChameleonHint(
                icon: Icons.water_drop_rounded,
                title: 'Period',
                body: 'Warm blossom / rose tones',
              ),
              SizedBox(height: 10),
              _ChameleonHint(
                icon: Icons.eco_rounded,
                title: 'Fertile & ovulation',
                body: 'Peach energy by day, mint calm at night',
              ),
              SizedBox(height: 10),
              _ChameleonHint(
                icon: Icons.spa_rounded,
                title: 'Luteal / pre-period',
                body: 'Soft lavender for wind-down',
              ),
              SizedBox(height: 10),
              _ChameleonHint(
                icon: Icons.wb_twilight_rounded,
                title: 'Time of day',
                body: 'Morning light → evening warmth → night calm',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChameleonHint extends StatelessWidget {
  const _ChameleonHint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ThemeStudioScreenState._titleInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                body,
                style: const TextStyle(
                  color: _ThemeStudioScreenState._bodyInk,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetsPanel extends StatelessWidget {
  const _PresetsPanel({required this.draft, required this.onApply});

  final ThemePrefs draft;
  final Future<void> Function(ThemePrefs) onApply;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        const Text(
          'Start with a curated look, then tweak anything.',
          style: TextStyle(
            color: _ThemeStudioScreenState._bodyInk,
            height: 1.4,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < AppLook.values.length; i++) ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 280 + i * 50),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - t)),
                child: child,
              ),
            ),
            child: _PresetTile(
              look: AppLook.values[i],
              selected: draft.lookId == AppLook.values[i].id,
              onTap: () => onApply(draft.copyWith(
                lookId: AppLook.values[i].id,
                motifId: AppLook.values[i].motif.name,
                clearPrimary: true,
                clearAccent: true,
                clearBackground: true,
              )),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.look,
    required this.selected,
    required this.onTap,
  });

  final AppLook look;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = CyclusPalette.of(look);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _ThemeStudioScreenState._card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? p.primary : const Color(0xFFE8DEE6),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: p.primary.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [p.gradientA, p.primary]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(look.motif.icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      look.title,
                      style: const TextStyle(
                        color: _ThemeStudioScreenState._titleInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      look.subtitle,
                      style: const TextStyle(
                        color: _ThemeStudioScreenState._bodyInk,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0.6,
                duration: const Duration(milliseconds: 220),
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.check_circle_rounded, color: p.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorsPanel extends StatelessWidget {
  const _ColorsPanel({required this.draft, required this.onApply});

  final ThemePrefs draft;
  final Future<void> Function(ThemePrefs) onApply;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _panelCard(
          title: 'Primary',
          child: _SwatchGrid(
            colors: ThemeColorSwatches.primaries,
            selected: draft.primaryOverride ?? AppColors.primary,
            onPick: (c) => onApply(draft.copyWith(primaryArgb: c.value)),
          ),
        ),
        const SizedBox(height: 12),
        _panelCard(
          title: 'Accent',
          child: _SwatchGrid(
            colors: ThemeColorSwatches.accents,
            selected: draft.accentOverride ?? AppColors.accent,
            onPick: (c) => onApply(draft.copyWith(accentArgb: c.value)),
          ),
        ),
        const SizedBox(height: 12),
        _panelCard(
          title: 'Page wash',
          child: _SwatchGrid(
            colors: ThemeColorSwatches.backgrounds,
            selected: draft.backgroundOverride ?? AppColors.background,
            onPick: (c) => onApply(draft.copyWith(backgroundArgb: c.value)),
          ),
        ),
      ],
    );
  }
}

class _BackgroundPanel extends StatelessWidget {
  const _BackgroundPanel({
    required this.draft,
    required this.picking,
    required this.onApply,
    required this.onPick,
    required this.onClear,
  });

  final ThemePrefs draft;
  final bool picking;
  final Future<void> Function(ThemePrefs) onApply;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final clean =
        ThemeBackgroundStore.stripCacheBust(draft.backgroundImagePath);
    final hasImage =
        clean != null && ThemeBackgroundStore.exists(draft.backgroundImagePath);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _panelCard(
          title: 'Your photo',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8DEE6)),
                  color: const Color(0xFFF7F0F4),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(clean), fit: BoxFit.cover),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: ClipRect(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  color: Colors.black.withOpacity(0.28),
                                  child: const Text(
                                    'Showing behind app screens',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 36,
                                color: AppColors.primary.withOpacity(0.7)),
                            const SizedBox(height: 8),
                            const Text(
                              'No photo yet',
                              style: TextStyle(
                                color: _ThemeStudioScreenState._mutedInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: picking ? null : onPick,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: picking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_rounded, size: 18),
                      label: Text(
                        hasImage ? 'Change photo' : 'Upload photo',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: onClear,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEEF2),
                        foregroundColor: const Color(0xFFC23B5A),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ],
              ),
              if (hasImage) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Photo visibility',
                      style: TextStyle(
                        color: _ThemeStudioScreenState._mutedInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      draft.backgroundImageStrength < 0.35
                          ? 'Soft'
                          : draft.backgroundImageStrength < 0.7
                              ? 'Balanced'
                              : 'Vivid',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    thumbColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primary.withOpacity(0.18),
                    overlayColor: AppColors.primary.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: draft.backgroundImageStrength.clamp(0.05, 1.0),
                    min: 0.05,
                    max: 1.0,
                    onChanged: (v) => onApply(
                      draft.copyWith(backgroundImageStrength: v),
                    ),
                  ),
                ),
                const Text(
                  'Drag right to show more of your photo behind the app.',
                  style: TextStyle(
                    color: _ThemeStudioScreenState._mutedInk,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _panelCard(
          title: 'Pattern motif',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in AppMotif.values)
                _AnimChip(
                  selected: draft.motifId == m.name &&
                      (m == AppMotif.none
                          ? !draft.showBackground
                          : draft.showBackground),
                  label: m.title,
                  icon: m.icon,
                  onTap: () => onApply(draft.copyWith(
                    motifId: m == AppMotif.none ? draft.motifId : m.name,
                    showBackground: m != AppMotif.none,
                  )),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StylePanel extends StatelessWidget {
  const _StylePanel({required this.draft, required this.onApply});

  final ThemePrefs draft;
  final Future<void> Function(ThemePrefs) onApply;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _panelCard(
          title: 'Corners  ·  ${draft.cornerRadius}',
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  thumbColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withOpacity(0.18),
                ),
                child: Slider(
                  value: draft.cornerRadius.toDouble().clamp(10, 32),
                  min: 10,
                  max: 32,
                  divisions: 11,
                  onChanged: (v) =>
                      onApply(draft.copyWith(cornerRadius: v.round())),
                ),
              ),
              Row(
                children: [
                  for (final e in [
                    ('Soft', 20),
                    ('Round', 28),
                    ('Sharp', 12),
                  ]) ...[
                    Expanded(
                      child: _AnimChip(
                        selected: draft.cornerRadius == e.$2,
                        label: e.$1,
                        onTap: () =>
                            onApply(draft.copyWith(cornerRadius: e.$2)),
                      ),
                    ),
                    if (e.$1 != 'Sharp') const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _panelCard(
          title: 'Typography',
          child: Column(
            children: [
              for (var i = 0; i < AppTextStylePref.values.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _TextStyleTile(
                  style: AppTextStylePref.values[i],
                  selected: draft.textStyleId == AppTextStylePref.values[i].id,
                  onTap: () => onApply(draft.copyWith(
                    textStyleId: AppTextStylePref.values[i].id,
                  )),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Widget _panelCard({required String title, required Widget child}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: _ThemeStudioScreenState._card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEDE4EA)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1A1228).withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ThemeStudioScreenState._titleInk,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({
    required this.colors,
    required this.selected,
    required this.onPick,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () => onPick(c),
            child: AnimatedScale(
              scale: selected.value == c.value ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected.value == c.value
                        ? _ThemeStudioScreenState._titleInk
                        : Colors.white,
                    width: selected.value == c.value ? 2.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withOpacity(0.4),
                      blurRadius: selected.value == c.value ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimChip extends StatelessWidget {
  const _AnimChip({
    required this.selected,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [AppColors.primary, AppColors.accent])
              : null,
          color: selected ? null : const Color(0xFFF7F0F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.primary.withOpacity(0.18),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected
                    ? Colors.white
                    : _ThemeStudioScreenState._titleInk,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : _ThemeStudioScreenState._titleInk,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextStyleTile extends StatelessWidget {
  const _TextStyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AppTextStylePref style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.08)
                : const Color(0xFFFaf6F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE8DEE6),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.title,
                      style: TextStyle(
                        fontFamily: style.fontFamily,
                        fontWeight: style.titleWeight,
                        letterSpacing: style.letterSpacing,
                        color: _ThemeStudioScreenState._titleInk,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.subtitle,
                      style: TextStyle(
                        fontFamily: style.fontFamily,
                        color: _ThemeStudioScreenState._bodyInk,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: selected ? AppColors.primary : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
