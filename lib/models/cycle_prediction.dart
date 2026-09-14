/// What the prediction engine returns for the current/next cycle.
class CyclePrediction {
  final DateTime nextPeriodStart;
  final DateTime nextPeriodEnd;
  final DateTime ovulationDay;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final int averageCycleLength;
  final int averagePeriodLength;
  final bool isIrregular;
  final int confidence; // 0-100

  /// Inclusive likely window for period start (wider when irregular).
  final DateTime earliestPeriodStart;
  final DateTime latestPeriodStart;

  /// Learned or default luteal length used for ovulation.
  final int lutealLength;

  /// True when today's date is already past [nextPeriodStart].
  final bool isLate;

  const CyclePrediction({
    required this.nextPeriodStart,
    required this.nextPeriodEnd,
    required this.ovulationDay,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.isIrregular,
    required this.confidence,
    DateTime? earliestPeriodStart,
    DateTime? latestPeriodStart,
    this.lutealLength = 14,
    this.isLate = false,
  })  : earliestPeriodStart = earliestPeriodStart ?? nextPeriodStart,
        latestPeriodStart = latestPeriodStart ?? nextPeriodStart;

  /// Days until next period (negative means it's late).
  int daysUntilNextPeriod(DateTime today) {
    final t = DateTime(today.year, today.month, today.day);
    final n = DateTime(
        nextPeriodStart.year, nextPeriodStart.month, nextPeriodStart.day);
    return n.difference(t).inDays;
  }

  int get predictedRangeDays =>
      latestPeriodStart.difference(earliestPeriodStart).inDays;
}

enum CyclePhase {
  period,
  follicular,
  fertile,
  ovulation,
  luteal,
  predicted,
  unknown,
}
