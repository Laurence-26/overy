import 'package:cloud_firestore/cloud_firestore.dart';

/// A single completed or in-progress menstrual cycle.
/// A cycle starts on the first day of a period and ends the day before the
/// next period starts.
class Cycle {
  final String id;
  final DateTime startDate;
  final DateTime? endDate; // null while still active
  final int periodLength; // number of bleeding days
  final int? cycleLength; // total length in days, null until next cycle starts

  const Cycle({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.periodLength,
    this.cycleLength,
  });

  bool get isActive => endDate == null;

  Cycle copyWith({
    DateTime? endDate,
    int? periodLength,
    int? cycleLength,
  }) {
    return Cycle(
      id: id,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      periodLength: periodLength ?? this.periodLength,
      cycleLength: cycleLength ?? this.cycleLength,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
        'periodLength': periodLength,
        'cycleLength': cycleLength,
      };

  factory Cycle.fromMap(Map<String, dynamic> m) => Cycle(
        id: m['id'] as String,
        startDate: (m['startDate'] as Timestamp).toDate(),
        endDate: (m['endDate'] as Timestamp?)?.toDate(),
        periodLength: m['periodLength'] as int? ?? 5,
        cycleLength: m['cycleLength'] as int?,
      );
}
