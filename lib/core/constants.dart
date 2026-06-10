/// App-wide constants and default values.
class AppConstants {
  AppConstants._();

  static const String appName = 'Cyclus';
  static const String appTagline = 'Your cycle, beautifully tracked';

  // Cycle defaults
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int minCycleLength = 21;
  static const int maxCycleLength = 45;
  static const int minPeriodLength = 2;
  static const int maxPeriodLength = 10;

  // History needed for irregular cycle detection
  static const int irregularityThresholdDays = 7;
  static const int minCyclesForPrediction = 2;
  static const int maxCyclesForAverage = 6;

  // Notification IDs — one per (phase, lead-day) pair so they don't overwrite.
  // Period lead-up: 3 days, 2 days, 1 day before next predicted period.
  static const int notifPeriod3Days = 1001;
  static const int notifPeriod2Days = 1002;
  static const int notifPeriod1Day = 1003;

  // Fertile window lead-up: 3 days, 2 days, 1 day before window starts.
  static const int notifFertile3Days = 1011;
  static const int notifFertile2Days = 1012;
  static const int notifFertile1Day = 1013;

  // Pregnancy trimester lead-up (single reminder 3 days before).
  static const int notifTrimester = 1101;

  // Daily nudge to log how you're feeling.
  static const int notifLogReminder = 1200;

  // Reserved for the "Test notification" button.
  static const int notifTest = 9999;

  /// All scheduled phase reminders — useful when toggling notifs off.
  static const List<int> notifAllPhaseIds = [
    notifPeriod3Days,
    notifPeriod2Days,
    notifPeriod1Day,
    notifFertile3Days,
    notifFertile2Days,
    notifFertile1Day,
    notifTrimester,
  ];

  // Storage keys
  static const String prefsOnboardingComplete = 'onboarding_complete';
  static const String prefsNotificationsEnabled = 'notifications_enabled';
}

/// Symptom categories shown in daily log.
class Symptoms {
  Symptoms._();

  static const List<String> physical = [
    'Cramps',
    'Headache',
    'Bloating',
    'Backache',
    'Tender breasts',
    'Fatigue',
    'Acne',
    'Nausea',
  ];

  static const List<String> moods = [
    'Happy',
    'Calm',
    'Sad',
    'Anxious',
    'Irritable',
    'Energetic',
    'Tired',
    'Sensitive',
  ];

  static const List<String> flowLevels = [
    'Spotting',
    'Light',
    'Medium',
    'Heavy',
  ];
}
