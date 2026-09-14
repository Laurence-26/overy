import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/cycle.dart';
import '../models/cycle_prediction.dart';
import '../models/theme_prefs.dart';
import '../providers/cycle_provider.dart';
import '../providers/theme_provider.dart';
import 'surface_panel.dart';

/// Cycle hero — flower or rectangular card, switchable by the user.
class CycleRing extends StatelessWidget {
  final Cycle? currentCycle;
  final CyclePrediction? prediction;
  final double size;

  const CycleRing({
    super.key,
    required this.currentCycle,
    required this.prediction,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    final view = context.watch<ThemeController>().cycleView;
    final phase = context.watch<CycleProvider>().phaseFor(DateTime.now());
    final metrics = _CycleMetrics.from(
      currentCycle: currentCycle,
      prediction: prediction,
      phase: phase,
    );

    return Column(
      children: [
        const CycleViewSwitcher(),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(anim),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(view),
            child: view == CycleViewStyle.card
                ? _CardCycleView(metrics: metrics)
                : _FlowerCycleView(metrics: metrics, size: size),
          ),
        ),
      ],
    );
  }
}

class CycleViewSwitcher extends StatelessWidget {
  const CycleViewSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final current = theme.cycleView;

    return SurfacePanel(
      padding: const EdgeInsets.all(4),
      opacity: 0.55,
      elevated: false,
      borderRadius: 999,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in CycleViewStyle.values)
            _SwitchChip(
              selected: current == v,
              icon: v.icon,
              label: v.title,
              onTap: () => _select(context, v),
            ),
        ],
      ),
    );
  }

  Future<void> _select(BuildContext context, CycleViewStyle view) async {
    final theme = context.read<ThemeController>();
    final cycle = context.read<CycleProvider>();
    if (theme.cycleView == view) return;
    theme.setCycleView(view);
    final profile = cycle.profile;
    if (profile == null) return;
    await cycle.updateProfile(
      profile.copyWith(themePrefs: theme.userPrefs.toMap()),
    );
  }
}

class _SwitchChip extends StatelessWidget {
  const _SwitchChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [AppColors.primary, AppColors.accent])
              : null,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleMetrics {
  final int? cycleDay;
  final int cycleLength;
  final int? daysToPeriod;
  final CyclePrediction? prediction;
  final Cycle? currentCycle;
  final CyclePhase phase;

  const _CycleMetrics({
    required this.cycleDay,
    required this.cycleLength,
    required this.daysToPeriod,
    required this.prediction,
    required this.currentCycle,
    required this.phase,
  });

  factory _CycleMetrics.from({
    required Cycle? currentCycle,
    required CyclePrediction? prediction,
    required CyclePhase phase,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int? cycleDay;
    final cycleLength = prediction?.averageCycleLength ?? 28;
    final daysToPeriod = prediction?.daysUntilNextPeriod(today);
    if (currentCycle != null) {
      cycleDay = today.difference(currentCycle.startDate).inDays + 1;
      if (cycleDay < 1) cycleDay = 1;
      if (cycleDay > cycleLength) cycleDay = cycleLength;
    }
    return _CycleMetrics(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      daysToPeriod: daysToPeriod,
      prediction: prediction,
      currentCycle: currentCycle,
      phase: phase,
    );
  }

  String get label {
    final d = daysToPeriod;
    if (d == null) return 'Welcome';
    if (d < 0) return 'Period late by';
    if (d == 0) return 'Period starts';
    if (prediction != null && prediction!.predictedRangeDays > 0) {
      return 'Likely period in';
    }
    return 'Next period in';
  }

  /// Big line always includes day/days when it's a count.
  String get bigNumber {
    final d = daysToPeriod;
    if (d == null) return '—';
    if (d == 0) return 'Today';
    if (prediction != null && prediction!.predictedRangeDays > 0) {
      final early = prediction!.earliestPeriodStart;
      final late = prediction!.latestPeriodStart;
      final today = DateTime.now();
      final t = DateTime(today.year, today.month, today.day);
      final a = early.difference(t).inDays.clamp(0, 99);
      final b = late.difference(t).inDays.clamp(0, 99);
      final unit = b == 1 ? 'day' : 'days';
      if (a == b) return '$a $unit';
      return '$a–$b $unit';
    }
    final n = d.abs();
    return '$n ${n == 1 ? 'day' : 'days'}';
  }

  String get subLabel {
    final d = daysToPeriod;
    if (d == null) return 'Log your first period';
    if (d == 0) return 'Starts today';
    if (cycleDay != null) return 'Cycle day $cycleDay';
    return '';
  }

  double get progress {
    if (cycleDay == null || cycleLength <= 0) return 0;
    return (cycleDay! / cycleLength).clamp(0.0, 1.0);
  }

  String get phaseTitle => switch (phase) {
        CyclePhase.period => 'Period',
        CyclePhase.fertile => 'Fertile',
        CyclePhase.ovulation => 'Ovulation',
        CyclePhase.predicted => 'Predicted',
        CyclePhase.follicular => 'Follicular',
        CyclePhase.luteal => 'Luteal',
        CyclePhase.unknown => 'Safe',
      };

  Color get phaseColor => switch (phase) {
        CyclePhase.period => AppColors.period,
        CyclePhase.fertile => AppColors.fertile,
        CyclePhase.ovulation => AppColors.ovulation,
        CyclePhase.predicted => AppColors.predicted,
        CyclePhase.follicular => AppColors.accent,
        CyclePhase.luteal => AppColors.accentDark,
        CyclePhase.unknown => AppColors.safe,
      };
}

// ───────────────────── Flower view ─────────────────────

class _FlowerCycleView extends StatelessWidget {
  const _FlowerCycleView({required this.metrics, required this.size});

  final _CycleMetrics metrics;
  final double size;

  @override
  Widget build(BuildContext context) {
    final canvas = size + 28;
    return SizedBox(
      width: canvas,
      height: canvas,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(canvas, canvas),
            painter: _BloomPainter(
              cycleDay: metrics.cycleDay,
              cycleLength: metrics.cycleLength,
              prediction: metrics.prediction,
              startDate: metrics.currentCycle?.startDate,
              phaseColor: metrics.phaseColor,
            ),
          ),
          // No inner circle plate — text sits in the open flower center.
          SizedBox(
            width: size * 0.48,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size * 0.44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      metrics.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.9),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metrics.bigNumber,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.95),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    if (metrics.subLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        metrics.subLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.9),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real flower bloom: layered petals + tiny pistil, no inner text disc.
class _BloomPainter extends CustomPainter {
  final int? cycleDay;
  final int cycleLength;
  final CyclePrediction? prediction;
  final DateTime? startDate;
  final Color phaseColor;

  _BloomPainter({
    required this.cycleDay,
    required this.cycleLength,
    required this.prediction,
    required this.startDate,
    required this.phaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final petalR = size.width * 0.34;

    // Soft glow behind bloom
    canvas.drawCircle(
      c,
      petalR + 8,
      Paint()
        ..color = AppColors.primary.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Back petals (slightly larger, rotated)
    _drawPetalLayer(
      canvas,
      c,
      petalR * 1.05,
      count: 6,
      rotation: math.pi / 6,
      color: AppColors.primary.withOpacity(0.28),
      stroke: AppColors.primary.withOpacity(0.35),
    );

    // Front petals
    _drawPetalLayer(
      canvas,
      c,
      petalR,
      count: 6,
      rotation: 0,
      color: Color.lerp(AppColors.primaryLight, Colors.white, 0.25)!
          .withOpacity(0.88),
      stroke: AppColors.primary.withOpacity(0.55),
    );

    // Phase-tinted petal highlight toward "today"
    if (cycleDay != null) {
      final frac = (cycleDay! - 1) / cycleLength;
      final a = -math.pi / 2 + frac * 2 * math.pi;
      _drawSinglePetal(
        canvas,
        c,
        petalR * 0.92,
        a,
        phaseColor.withOpacity(0.55),
        phaseColor,
      );
    }

    // Period / fertile petal tints along the bloom edge
    if (prediction != null && startDate != null) {
      final periodLen = prediction!.averagePeriodLength;
      for (var i = 0; i < periodLen && i < cycleLength; i++) {
        final a = -math.pi / 2 + (i / cycleLength) * 2 * math.pi;
        final tip = Offset(
          c.dx + math.cos(a) * petalR * 0.92,
          c.dy + math.sin(a) * petalR * 0.92,
        );
        canvas.drawCircle(tip, 4.5, Paint()..color = AppColors.period);
      }

      final fs = prediction!.fertileWindowStart.difference(startDate!).inDays;
      final fe = prediction!.fertileWindowEnd.difference(startDate!).inDays;
      if (fs >= 0) {
        for (var i = fs; i <= fe && i < cycleLength; i++) {
          final a = -math.pi / 2 + (i / cycleLength) * 2 * math.pi;
          final tip = Offset(
            c.dx + math.cos(a) * petalR * 0.78,
            c.dy + math.sin(a) * petalR * 0.78,
          );
          canvas.drawCircle(
              tip, 3.5, Paint()..color = AppColors.fertile.withOpacity(0.9));
        }
      }

      final ovu = prediction!.ovulationDay.difference(startDate!).inDays;
      if (ovu >= 0 && ovu < cycleLength) {
        final a = -math.pi / 2 + (ovu / cycleLength) * 2 * math.pi;
        final tip = Offset(
          c.dx + math.cos(a) * petalR * 0.85,
          c.dy + math.sin(a) * petalR * 0.85,
        );
        canvas.drawCircle(tip, 6, Paint()..color = Colors.white);
        canvas.drawCircle(tip, 4.5, Paint()..color = AppColors.ovulation);
      }
    }

    // Tiny pistil dots — not a text disc
    for (var i = 0; i < 5; i++) {
      final a = i * (2 * math.pi / 5) - math.pi / 2;
      final p = Offset(c.dx + math.cos(a) * 7, c.dy + math.sin(a) * 7);
      canvas.drawCircle(
        p,
        3.2,
        Paint()..color = const Color(0xFFFFE08A).withOpacity(0.9),
      );
    }
    canvas.drawCircle(
      c,
      4,
      Paint()..color = const Color(0xFFFFC94A).withOpacity(0.95),
    );

    // Today gem on outer petal tip
    if (cycleDay != null) {
      final frac = (cycleDay! - 1) / cycleLength;
      final a = -math.pi / 2 + frac * 2 * math.pi;
      final p = Offset(
        c.dx + math.cos(a) * petalR * 1.02,
        c.dy + math.sin(a) * petalR * 1.02,
      );
      canvas.drawCircle(
        p,
        11,
        Paint()
          ..color = phaseColor.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(p, 8, Paint()..color = Colors.white);
      canvas.drawCircle(p, 5.5, Paint()..color = phaseColor);
    }
  }

  void _drawPetalLayer(
    Canvas canvas,
    Offset c,
    double r, {
    required int count,
    required double rotation,
    required Color color,
    required Color stroke,
  }) {
    for (var i = 0; i < count; i++) {
      final a = rotation + -math.pi / 2 + i * (2 * math.pi / count);
      _drawSinglePetal(canvas, c, r, a, color, stroke);
    }
  }

  void _drawSinglePetal(
    Canvas canvas,
    Offset c,
    double r,
    double angle,
    Color fill,
    Color stroke,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -r * 0.15)
      ..cubicTo(r * 0.42, -r * 0.35, r * 0.48, -r * 0.75, 0, -r)
      ..cubicTo(-r * 0.48, -r * 0.75, -r * 0.42, -r * 0.35, 0, -r * 0.15)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Vein
    canvas.drawLine(
      Offset(0, -r * 0.2),
      Offset(0, -r * 0.88),
      Paint()
        ..color = stroke.withOpacity(0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BloomPainter old) =>
      old.cycleDay != cycleDay ||
      old.cycleLength != cycleLength ||
      old.prediction != prediction ||
      old.phaseColor != phaseColor;
}

// ───────────────────── Card / rectangle view ─────────────────────

class _CardCycleView extends StatelessWidget {
  const _CardCycleView({required this.metrics});

  final _CycleMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final p = metrics.prediction;
    final phaseColor = metrics.phaseColor;

    return SurfacePanel(
      opacity: 0.6,
      tint: phaseColor,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: phaseColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: phaseColor),
                    const SizedBox(width: 6),
                    Text(
                      'Cycle snapshot',
                      style: TextStyle(
                        color: phaseColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (metrics.cycleDay != null)
                Text(
                  'Day ${metrics.cycleDay}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            metrics.label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metrics.bigNumber,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: metrics.bigNumber.length > 10 ? 34 : 42,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          if (metrics.subLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              metrics.subLabel,
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.75),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          // Phase label sits on top of the progress bar
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: phaseColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: phaseColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  metrics.phaseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(metrics.progress * 100).round()}%',
                style: TextStyle(
                  color: phaseColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: phaseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: metrics.progress.clamp(0.04, 1.0),
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          phaseColor,
                          Color.lerp(phaseColor, Colors.white, 0.25)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: phaseColor.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Progress colored by today’s phase',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (p != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniChip(
                  color: AppColors.period,
                  label: 'Period ${p.averagePeriodLength}d',
                ),
                _MiniChip(
                  color: AppColors.predicted,
                  label: 'Predicted',
                ),
                _MiniChip(
                  color: AppColors.fertile,
                  label: 'Fertile',
                ),
                _MiniChip(
                  color: AppColors.safe,
                  label: 'Safe',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
