import 'dart:math' as math;

import '../core/constants.dart';
import '../models/cycle.dart';
import '../models/cycle_prediction.dart';

/// Pure functions for cycle prediction. No I/O, fully testable.
///
/// Handles BOTH regular and irregular cycles:
///   • Regular  → uses rolling average over up to [maxCyclesForAverage] cycles.
///   • Irregular → detected when stdev > [irregularityThresholdDays];
///                 prediction widens its confidence + shows a range.
class PredictionEngine {
  PredictionEngine._();

  /// Returns null if there is not even one logged cycle.
  static CyclePrediction? predict({
    required List<Cycle> cyclesNewestFirst,
    required int fallbackCycleLength,
    required int fallbackPeriodLength,
  }) {
    if (cyclesNewestFirst.isEmpty) return null;
    final lastStart = cyclesNewestFirst.first.startDate;

    // Collect completed cycle lengths
    final lengths = <int>[];
    for (final c in cyclesNewestFirst) {
      if (c.cycleLength != null && c.cycleLength! > 0) {
        lengths.add(c.cycleLength!);
      }
      if (lengths.length >= AppConstants.maxCyclesForAverage) break;
    }

    final avgCycle = lengths.isEmpty
        ? fallbackCycleLength
        : (lengths.reduce((a, b) => a + b) / lengths.length).round();

    // Period length average
    final periodLengths = cyclesNewestFirst
        .take(AppConstants.maxCyclesForAverage)
        .map((c) => c.periodLength)
        .where((p) => p > 0)
        .toList();
    final avgPeriod = periodLengths.isEmpty
        ? fallbackPeriodLength
        : (periodLengths.reduce((a, b) => a + b) / periodLengths.length)
            .round();

    // Irregularity = stdev of cycle lengths
    final stdev = _stdev(lengths);
    final isIrregular =
        lengths.length >= AppConstants.minCyclesForPrediction &&
            stdev > AppConstants.irregularityThresholdDays;

    // Confidence drops with fewer samples and rising stdev
    int confidence;
    if (lengths.isEmpty) {
      confidence = 30;
    } else {
      final sampleScore = (lengths.length / 6).clamp(0, 1) * 60;
      final stabilityScore =
          (1 - (stdev / 14).clamp(0, 1).toDouble()) * 40;
      confidence = (sampleScore + stabilityScore).round().clamp(20, 99);
    }

    final nextPeriodStart = lastStart.add(Duration(days: avgCycle));
    final nextPeriodEnd =
        nextPeriodStart.add(Duration(days: avgPeriod - 1));

    // Ovulation ≈ next period start − 14 days (luteal phase length)
    final ovulationDay =
        nextPeriodStart.subtract(const Duration(days: 14));
    final fertileWindowStart =
        ovulationDay.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDay.add(const Duration(days: 1));

    return CyclePrediction(
      nextPeriodStart: _stripTime(nextPeriodStart),
      nextPeriodEnd: _stripTime(nextPeriodEnd),
      ovulationDay: _stripTime(ovulationDay),
      fertileWindowStart: _stripTime(fertileWindowStart),
      fertileWindowEnd: _stripTime(fertileWindowEnd),
      averageCycleLength: avgCycle,
      averagePeriodLength: avgPeriod,
      isIrregular: isIrregular,
      confidence: confidence,
    );
  }

  /// Classify a date relative to known cycles + a prediction.
  static CyclePhase phaseFor({
    required DateTime day,
    required List<Cycle> cyclesNewestFirst,
    required CyclePrediction? prediction,
  }) {
    final d = _stripTime(day);

    // 1. Was this day in any logged period?
    for (final c in cyclesNewestFirst) {
      final start = _stripTime(c.startDate);
      final end = start.add(Duration(days: c.periodLength - 1));
      if (!d.isBefore(start) && !d.isAfter(end)) return CyclePhase.period;
    }

    if (prediction == null) return CyclePhase.unknown;

    // 2. Predicted next period
    if (!d.isBefore(prediction.nextPeriodStart) &&
        !d.isAfter(prediction.nextPeriodEnd)) {
      return CyclePhase.predicted;
    }

    // 3. Ovulation / fertile window
    if (_sameDay(d, prediction.ovulationDay)) return CyclePhase.ovulation;
    if (!d.isBefore(prediction.fertileWindowStart) &&
        !d.isAfter(prediction.fertileWindowEnd)) {
      return CyclePhase.fertile;
    }

    // 4. Otherwise classify by current-cycle position
    if (cyclesNewestFirst.isNotEmpty) {
      final last = cyclesNewestFirst.first;
      final lastStart = _stripTime(last.startDate);
      final dayInCycle = d.difference(lastStart).inDays;
      if (dayInCycle >= 0 && dayInCycle < prediction.averageCycleLength) {
        if (dayInCycle < prediction.averageCycleLength ~/ 2) {
          return CyclePhase.follicular;
        }
        return CyclePhase.luteal;
      }
    }
    return CyclePhase.unknown;
  }

  static double _stdev(List<int> xs) {
    if (xs.length < 2) return 0;
    final mean = xs.reduce((a, b) => a + b) / xs.length;
    final variance =
        xs.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
            xs.length;
    return math.sqrt(variance);
  }

  static DateTime _stripTime(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
