import 'dart:math' as math;

import '../core/constants.dart';
import '../models/cycle.dart';
import '../models/cycle_prediction.dart';
import '../models/daily_log.dart';

/// On-device cycle math. No I/O.
///
/// Designed for both regular and irregular cycles:
/// * Recent cycles weigh more (exponential decay).
/// * Outliers are dropped with a robust median/MAD filter.
/// * Ovulation uses a learned luteal length when logs show OPK / pain /
/// egg-white mucus; otherwise a 14-day luteal phase (10-16 clamp).
/// * Irregular cycles get a date *range* and a wider fertile window.
/// * If the predicted start is already in the past, the period is marked
/// late instead of inventing a new date.
class PredictionEngine {
  PredictionEngine._();

  static CyclePrediction? predict({
    required List<Cycle> cyclesNewestFirst,
    required int fallbackCycleLength,
    required int fallbackPeriodLength,
    List<DailyLog> logs = const [],
    bool userReportedIrregular = false,
    int? age,
    DateTime? now,
  }) {
    if (cyclesNewestFirst.isEmpty) return null;
    final today = _stripTime(now ?? DateTime.now());
    final last = cyclesNewestFirst.first;
    final lastStart = _stripTime(last.startDate);
    final lastStartLatest = last.startDateLatest != null
        ? _stripTime(last.startDateLatest!)
        : lastStart;
    final startSpanDays =
        math.max(0, lastStartLatest.difference(lastStart).inDays);

    final rawLengths = <int>[];
    for (final c in cyclesNewestFirst) {
      if (c.cycleLength != null && c.cycleLength! > 0) {
        rawLengths.add(c.cycleLength!);
      }
      if (rawLengths.length >= AppConstants.maxCyclesForAverage) break;
    }

    final lengths = _rejectOutliers(rawLengths);
    final used = lengths.isEmpty ? rawLengths : lengths;

    final avgCycle = used.isEmpty
        ? fallbackCycleLength.clamp(
            AppConstants.minCycleLength, AppConstants.maxCycleLength)
        : _weightedMean(used)
            .round()
            .clamp(AppConstants.minCycleLength, AppConstants.maxCycleLength);

    final periodLengths = cyclesNewestFirst
        .take(AppConstants.maxCyclesForAverage)
        .map((c) => c.periodLength)
        .where((p) => p > 0)
        .toList();
    final avgPeriod = periodLengths.isEmpty
        ? fallbackPeriodLength
        : (periodLengths.reduce((a, b) => a + b) / periodLengths.length)
            .round()
            .clamp(AppConstants.minPeriodLength, AppConstants.maxPeriodLength);

    final stdev = _stdev(used);
    final cv = used.isEmpty || avgCycle == 0 ? 0.0 : stdev / avgCycle;
    final isIrregular = userReportedIrregular ||
        startSpanDays > 0 ||
        (used.length >= AppConstants.minCyclesForPrediction &&
            (stdev > AppConstants.irregularityThresholdDays || cv > 0.18));

    final luteal = _learnedLutealLength(
      cyclesNewestFirst: cyclesNewestFirst,
      logs: logs,
      age: age,
    );

    int confidence;
    if (used.isEmpty) {
      confidence = startSpanDays > 0 ? 22 : 28;
    } else {
      final sampleScore =
          (used.length / AppConstants.maxCyclesForAverage).clamp(0, 1) * 45;
      final stabilityScore = (1 - (stdev / 12).clamp(0, 1).toDouble()) * 40;
      final recencyBoost = used.length >= 3 ? 8 : 0;
      confidence =
          (sampleScore + stabilityScore + recencyBoost).round().clamp(18, 96);
      if (isIrregular) confidence = (confidence * 0.85).round().clamp(18, 88);
      if (startSpanDays > 0) {
        confidence = (confidence * 0.8).round().clamp(15, 80);
      }
    }

    // Anchor on the midpoint when she only knew a start range.
    final midLast = lastStart.add(Duration(days: startSpanDays ~/ 2));
    var nextPeriodStart = midLast.add(Duration(days: avgCycle));
    var isLate = false;
    if (nextPeriodStart.isBefore(today)) {
      isLate = true;
      confidence = (confidence * 0.7).round().clamp(15, 70);
    }

    final pad = isIrregular
        ? math.max(2, (stdev * 0.9).round().clamp(2, 7))
        : math.max(0, (stdev * 0.5).round().clamp(0, 2));

    // If last period was a date range, the next one is that same window shifted.
    final earliest = startSpanDays > 0
        ? lastStart.add(Duration(days: avgCycle))
        : nextPeriodStart.subtract(Duration(days: pad));
    final latest = startSpanDays > 0
        ? lastStartLatest.add(Duration(days: avgCycle))
        : nextPeriodStart.add(Duration(days: pad));

    final nextPeriodEnd = nextPeriodStart.add(Duration(days: avgPeriod - 1));
    final ovulationDay = nextPeriodStart.subtract(Duration(days: luteal));
    final fertilePad = (isIrregular || startSpanDays > 0) ? 1 : 0;
    final fertileWindowStart =
        ovulationDay.subtract(Duration(days: 5 + fertilePad));
    final fertileWindowEnd = ovulationDay.add(Duration(days: 1 + fertilePad));

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
      earliestPeriodStart: _stripTime(earliest),
      latestPeriodStart: _stripTime(latest),
      lutealLength: luteal,
      isLate: isLate,
    );
  }

  /// Classify a date relative to known cycles + a prediction.
  static CyclePhase phaseFor({
    required DateTime day,
    required List<Cycle> cyclesNewestFirst,
    required CyclePrediction? prediction,
  }) {
    final d = _stripTime(day);

    for (final c in cyclesNewestFirst) {
      final start = _stripTime(c.startDate);
      final end = start.add(Duration(days: c.periodLength - 1));
      if (!d.isBefore(start) && !d.isAfter(end)) return CyclePhase.period;
    }

    if (prediction == null) return CyclePhase.unknown;

    final periodStart = prediction.predictedRangeDays > 0
        ? prediction.earliestPeriodStart
        : prediction.nextPeriodStart;
    final periodEnd = prediction.predictedRangeDays > 0
        ? prediction.latestPeriodStart
            .add(Duration(days: prediction.averagePeriodLength - 1))
        : prediction.nextPeriodEnd;
    if (!d.isBefore(periodStart) && !d.isAfter(periodEnd)) {
      return CyclePhase.predicted;
    }

    if (_sameDay(d, prediction.ovulationDay)) return CyclePhase.ovulation;
    if (!d.isBefore(prediction.fertileWindowStart) &&
        !d.isAfter(prediction.fertileWindowEnd)) {
      return CyclePhase.fertile;
    }

    if (cyclesNewestFirst.isNotEmpty) {
      final last = cyclesNewestFirst.first;
      final lastStart = _stripTime(last.startDate);
      final dayInCycle = d.difference(lastStart).inDays;
      if (dayInCycle >= 0 && dayInCycle < prediction.averageCycleLength) {
        final ovuOffset =
            prediction.averageCycleLength - prediction.lutealLength;
        if (dayInCycle < ovuOffset - 1) return CyclePhase.follicular;
        return CyclePhase.luteal;
      }
    }
    return CyclePhase.unknown;
  }

  /// Exponential-decay mean so the most recent cycle counts most.
  static double _weightedMean(List<int> newestFirst) {
    if (newestFirst.isEmpty) return 0;
    var num = 0.0;
    var den = 0.0;
    for (var i = 0; i < newestFirst.length; i++) {
      final w = math.pow(0.82, i).toDouble();
      num += newestFirst[i] * w;
      den += w;
    }
    return num / den;
  }

  /// Drops values more than 2.5 median-absolute-deviations from the median.
  static List<int> _rejectOutliers(List<int> xs) {
    if (xs.length < 4) return xs;
    final sorted = [...xs]..sort();
    final med = _median(sorted);
    final deviations = sorted.map((x) => (x - med).abs()).toList()..sort();
    final mad = _median(deviations);
    if (mad == 0) return xs;
    final kept =
        xs.where((x) => (x - med).abs() <= 2.5 * mad * 1.4826).toList();
    return kept.length >= 2 ? kept : xs;
  }

  static double _median(List<num> sorted) {
    if (sorted.isEmpty) return 0;
    final m = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[m].toDouble();
    return (sorted[m - 1] + sorted[m]) / 2;
  }

  /// Infer luteal length from OPK / ovulation-pain / egg-white mucus logs.
  static int _learnedLutealLength({
    required List<Cycle> cyclesNewestFirst,
    required List<DailyLog> logs,
    int? age,
  }) {
    const signs = {
      'Ovulation pain',
      'Positive OPK',
      'Egg-white mucus',
      'Mittelschmerz',
    };
    final luteals = <int>[];
    for (final c in cyclesNewestFirst) {
      if (c.cycleLength == null || c.cycleLength! <= 0) continue;
      final start = _stripTime(c.startDate);
      final nextStart = start.add(Duration(days: c.cycleLength!));
      DateTime? ovu;
      for (final log in logs) {
        final d = _stripTime(log.date);
        if (d.isBefore(start) || !d.isBefore(nextStart)) continue;
        final hit = log.symptoms.any(signs.contains);
        if (hit) {
          if (ovu == null || d.isAfter(ovu)) ovu = d;
        }
      }
      if (ovu != null) {
        final luteal = nextStart.difference(ovu).inDays;
        if (luteal >= AppConstants.minLutealLength &&
            luteal <= AppConstants.maxLutealLength) {
          luteals.add(luteal);
        }
      }
    }

    var base = AppConstants.defaultLutealLength;
    if (age != null && age >= 40) base = 13;
    if (luteals.isEmpty) return base;
    final learned = _weightedMean(luteals).round();
    return learned.clamp(
        AppConstants.minLutealLength, AppConstants.maxLutealLength);
  }

  static double _stdev(List<int> xs) {
    if (xs.length < 2) return 0;
    final mean = xs.reduce((a, b) => a + b) / xs.length;
    final variance =
        xs.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
            xs.length;
    return math.sqrt(variance);
  }

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
