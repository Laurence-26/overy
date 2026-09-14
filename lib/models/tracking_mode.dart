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

  String get homeGreeting => switch (this) {
        TrackingMode.period => 'Your cycle, today',
        TrackingMode.conception => 'Your high-chance days',
        TrackingMode.pregnancy => 'Your pregnancy, today',
      };

  String get logFabLabel => switch (this) {
        TrackingMode.period => 'Log period',
        TrackingMode.conception => 'Log today',
        TrackingMode.pregnancy => 'Log day',
      };

  String get insightsTitle => switch (this) {
        TrackingMode.period => 'Cycle insights',
        TrackingMode.conception => 'Fertility insights',
        TrackingMode.pregnancy => 'Pregnancy insights',
      };

  String get calendarTitle => switch (this) {
        TrackingMode.period => 'Your cycle calendar',
        TrackingMode.conception => 'Your fertile calendar',
        TrackingMode.pregnancy => 'Your pregnancy calendar',
      };
}
