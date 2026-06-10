import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-day notes: flow level, symptoms, mood, free-form text.
class DailyLog {
  final DateTime date;
  final String? flow; // one of Symptoms.flowLevels, or null = none
  final List<String> symptoms;
  final List<String> moods;
  final String? notes;

  const DailyLog({
    required this.date,
    this.flow,
    this.symptoms = const [],
    this.moods = const [],
    this.notes,
  });

  bool get isEmpty =>
      flow == null && symptoms.isEmpty && moods.isEmpty && (notes ?? '').isEmpty;

  bool get hasFlow => flow != null;

  /// Firestore document id — one log per day.
  String get docId =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DailyLog copyWith({
    String? flow,
    bool clearFlow = false,
    List<String>? symptoms,
    List<String>? moods,
    String? notes,
  }) {
    return DailyLog(
      date: date,
      flow: clearFlow ? null : (flow ?? this.flow),
      symptoms: symptoms ?? this.symptoms,
      moods: moods ?? this.moods,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'flow': flow,
        'symptoms': symptoms,
        'moods': moods,
        'notes': notes,
      };

  factory DailyLog.fromMap(Map<String, dynamic> m) => DailyLog(
        date: (m['date'] as Timestamp).toDate(),
        flow: m['flow'] as String?,
        symptoms: List<String>.from(m['symptoms'] as List? ?? const []),
        moods: List<String>.from(m['moods'] as List? ?? const []),
        notes: m['notes'] as String?,
      );
}
