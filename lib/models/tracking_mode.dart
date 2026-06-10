/// Which tracking experience the user is using.
enum TrackingMode {
  period,
  conception,
  pregnancy;

  String get id => name;

  static TrackingMode? fromId(String? id) {
    if (id == null) return null;
    for (final m in TrackingMode.values) {
      if (m.id == id) return m;
    }
    return null;
  }

  String get displayName => switch (this) {
        TrackingMode.period => 'Period',
        TrackingMode.conception => 'Conceive',
        TrackingMode.pregnancy => 'Pregnancy',
      };

  String get tagline => switch (this) {
        TrackingMode.period => 'Track your cycle',
        TrackingMode.conception => 'Plan your conception journey',
        TrackingMode.pregnancy => 'Track your pregnancy',
      };
}
