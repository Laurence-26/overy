import '../core/json_dates.dart';

/// A single completed or in-progress menstrual cycle.
/// A cycle starts on the first day of a period and ends the day before the
/// next period starts.
class Cycle {
  final String id;
  final DateTime startDate;

  /// When she only knew a *range* for period start, the latest possible day.
  /// Predictions then span [startDate + L, startDateLatest + L].
  final DateTime? startDateLatest;

  final DateTime? endDate; // null while still active
  final int periodLength; // number of bleeding days
  final int? cycleLength; // total length in days, null until next cycle starts

  const Cycle({
    required this.id,
    required this.startDate,
    this.startDateLatest,
    this.endDate,
    required this.periodLength,
    this.cycleLength,
  });

  bool get isActive => endDate == null;

  /// Inclusive days of uncertainty on when this period started (0 = exact).
  int get startUncertaintyDays {
    final latest = startDateLatest;
    if (latest == null) return 0;
    final a = DateTime(startDate.year, startDate.month, startDate.day);
    final b = DateTime(latest.year, latest.month, latest.day);
    final d = b.difference(a).inDays;
    return d < 0 ? 0 : d;
  }

  bool get hasStartRange => startUncertaintyDays > 0;

  Cycle copyWith({
    DateTime? startDate,
    DateTime? startDateLatest,
    bool clearStartDateLatest = false,
    DateTime? endDate,
    int? periodLength,
    int? cycleLength,
  }) {
    return Cycle(
      id: id,
      startDate: startDate ?? this.startDate,
      startDateLatest: clearStartDateLatest
          ? null
          : (startDateLatest ?? this.startDateLatest),
      endDate: endDate ?? this.endDate,
      periodLength: periodLength ?? this.periodLength,
      cycleLength: cycleLength ?? this.cycleLength,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'startDate': JsonDates.encode(startDate),
        'startDateLatest': JsonDates.encode(startDateLatest),
        'endDate': JsonDates.encode(endDate),
        'periodLength': periodLength,
        'cycleLength': cycleLength,
      };

  factory Cycle.fromMap(Map<String, dynamic> m) => Cycle(
        id: m['id'] as String,
        startDate: JsonDates.decodeRequired(m['startDate']),
        startDateLatest: JsonDates.decode(m['startDateLatest']),
        endDate: JsonDates.decode(m['endDate']),
        periodLength: m['periodLength'] as int? ?? 5,
        cycleLength: m['cycleLength'] as int?,
      );
}
