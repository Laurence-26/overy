import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/cycle.dart';
import '../models/cycle_prediction.dart';

/// The signature circular cycle progress widget shown on the home screen.
/// Shows: current cycle day, days to next period, fertile window arc.
class CycleRing extends StatelessWidget {
  final Cycle? currentCycle;
  final CyclePrediction? prediction;
  final double size;

  const CycleRing({
    super.key,
    required this.currentCycle,
    required this.prediction,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int? cycleDay;
    int cycleLength = prediction?.averageCycleLength ?? 28;
    int? daysToPeriod = prediction?.daysUntilNextPeriod(today);

    if (currentCycle != null) {
      cycleDay = today.difference(currentCycle!.startDate).inDays + 1;
      if (cycleDay < 1) cycleDay = 1;
      if (cycleDay > cycleLength) cycleDay = cycleLength;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              cycleDay: cycleDay,
              cycleLength: cycleLength,
              prediction: prediction,
              startDate: currentCycle?.startDate,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _label(daysToPeriod),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _bigNumber(daysToPeriod),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _subLabel(daysToPeriod, cycleDay),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(int? daysToPeriod) {
    if (daysToPeriod == null) return 'WELCOME';
    if (daysToPeriod < 0) return 'PERIOD LATE BY';
    if (daysToPeriod == 0) return 'PERIOD STARTS';
    return 'NEXT PERIOD IN';
  }

  String _bigNumber(int? daysToPeriod) {
    if (daysToPeriod == null) return '—';
    if (daysToPeriod == 0) return 'Today';
    return daysToPeriod.abs().toString();
  }

  String _subLabel(int? daysToPeriod, int? cycleDay) {
    if (daysToPeriod == null) return 'Log your first period to begin';
    if (daysToPeriod == 0) return '';
    final word = daysToPeriod.abs() == 1 ? 'day' : 'days';
    final cycleStr = cycleDay != null ? ' • Cycle day $cycleDay' : '';
    return '$word$cycleStr';
  }
}

class _RingPainter extends CustomPainter {
  final int? cycleDay;
  final int cycleLength;
  final CyclePrediction? prediction;
  final DateTime? startDate;

  _RingPainter({
    required this.cycleDay,
    required this.cycleLength,
    required this.prediction,
    required this.startDate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;
    final strokeWidth = 22.0;

    // Background ring
    final bg = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    if (prediction == null) return;

    // Fertile window arc
    final fertileStartDay =
        prediction!.fertileWindowStart.difference(startDate ?? DateTime.now()).inDays;
    final fertileEndDay =
        prediction!.fertileWindowEnd.difference(startDate ?? DateTime.now()).inDays;
    if (startDate != null && fertileStartDay >= 0) {
      _drawArc(canvas, center, radius, strokeWidth,
          AppColors.fertile.withOpacity(0.55),
          fertileStartDay / cycleLength, fertileEndDay / cycleLength);
    }

    // Period arc (first N days)
    final periodLen = prediction!.averagePeriodLength;
    _drawArc(canvas, center, radius, strokeWidth, AppColors.period,
        0, periodLen / cycleLength);

    // Predicted next period arc near the end
    _drawArc(canvas, center, radius, strokeWidth,
        AppColors.predicted, (cycleLength - 1) / cycleLength, 1);

    // Progress marker - current day
    if (cycleDay != null) {
      final fraction = (cycleDay! - 1) / cycleLength;
      final angle = -math.pi / 2 + fraction * 2 * math.pi;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final outer = Paint()..color = Colors.white;
      final inner = Paint()..color = AppColors.primaryDark;
      canvas.drawCircle(dotCenter, 11, outer);
      canvas.drawCircle(dotCenter, 7, inner);
    }
  }

  void _drawArc(Canvas canvas, Offset center, double radius, double strokeWidth,
      Color color, double startFrac, double endFrac) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -math.pi / 2 + startFrac * 2 * math.pi;
    final sweep = (endFrac - startFrac).clamp(0.0, 1.0) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.cycleDay != cycleDay ||
      old.cycleLength != cycleLength ||
      old.prediction != prediction;
}
