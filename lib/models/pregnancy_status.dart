/// Computed snapshot of a pregnancy's progress.
class PregnancyStatus {
  final DateTime lmp; // Last Menstrual Period
  final DateTime dueDate;
  final DateTime today;

  const PregnancyStatus({
    required this.lmp,
    required this.dueDate,
    required this.today,
  });

  /// Compute due date from LMP (Naegele's rule = LMP + 280 days).
  factory PregnancyStatus.fromLmp(DateTime lmp, {DateTime? today}) {
    final t = today ?? DateTime.now();
    return PregnancyStatus(
      lmp: _strip(lmp),
      dueDate: _strip(lmp).add(const Duration(days: 280)),
      today: _strip(t),
    );
  }

  /// Compute LMP from due date.
  factory PregnancyStatus.fromDueDate(DateTime dueDate, {DateTime? today}) {
    final t = today ?? DateTime.now();
    return PregnancyStatus(
      lmp: _strip(dueDate).subtract(const Duration(days: 280)),
      dueDate: _strip(dueDate),
      today: _strip(t),
    );
  }

  int get daysSinceLmp => today.difference(lmp).inDays;
  int get weeksAlong => daysSinceLmp ~/ 7;
  int get daysIntoWeek => daysSinceLmp % 7;
  int get daysUntilDue => dueDate.difference(today).inDays;

  /// 1, 2, or 3 (clamped). 1st = 0-12wk, 2nd = 13-27wk, 3rd = 28-40wk.
  int get trimester {
    if (weeksAlong < 13) return 1;
    if (weeksAlong < 28) return 2;
    return 3;
  }

  /// First day of the *next* trimester. Returns null if already in 3rd.
  DateTime? get nextTrimesterStart {
    final weeksToNext = switch (trimester) {
      1 => 13 - weeksAlong,
      2 => 28 - weeksAlong,
      _ => null,
    };
    if (weeksToNext == null) return null;
    return today.add(Duration(days: weeksToNext * 7 - daysIntoWeek));
  }

  String get trimesterLabel => switch (trimester) {
        1 => 'First trimester',
        2 => 'Second trimester',
        _ => 'Third trimester',
      };

  /// Label of the *upcoming* trimester, or null if already in the third.
  String? get nextTrimesterLabel => switch (trimester) {
        1 => 'Second trimester',
        2 => 'Third trimester',
        _ => null,
      };

  /// 0..1 progress through the whole pregnancy.
  double get progress {
    final p = daysSinceLmp / 280;
    return p.clamp(0.0, 1.0);
  }

  static DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);
}
