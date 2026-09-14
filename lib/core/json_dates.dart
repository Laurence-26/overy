/// ISO-8601 helpers so models never depend on Firestore Timestamps.
class JsonDates {
  JsonDates._();

  static String? encode(DateTime? d) => d?.toIso8601String();

  static DateTime? decode(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) {
      // milliseconds or seconds since epoch
      if (v > 9999999999) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    if (v is double) {
      return DateTime.fromMillisecondsSinceEpoch(v.round());
    }
    return null;
  }

  static DateTime decodeRequired(dynamic v, {DateTime? fallback}) {
    return decode(v) ?? fallback ?? DateTime.now();
  }
}
