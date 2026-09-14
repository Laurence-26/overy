import '../models/tracking_mode.dart';

/// App-wide constants and default values.
class AppConstants {
  AppConstants._();

  static const String appName = 'Cyclus';
  static const String appTagline = 'Your cycle, beautifully tracked - offline';

  // Cycle defaults
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int minCycleLength = 21;
  static const int maxCycleLength = 45;
  static const int minPeriodLength = 2;
  static const int maxPeriodLength = 10;

  // History needed for irregular cycle detection
  static const int irregularityThresholdDays = 6;
  static const int minCyclesForPrediction = 2;
  static const int maxCyclesForAverage = 12;
  static const int defaultLutealLength = 14;
  static const int minLutealLength = 10;
  static const int maxLutealLength = 16;

  // Notification IDs - one per (phase, lead-day) pair so they don't overwrite.
  static const int notifPeriod3Days = 1001;
  static const int notifPeriod2Days = 1002;
  static const int notifPeriod1Day = 1003;
  static const int notifPeriodToday = 1004;
  static const int notifPeriodLate = 1005;

  static const int notifFertile3Days = 1011;
  static const int notifFertile2Days = 1012;
  static const int notifFertile1Day = 1013;
  static const int notifOvulation = 1014;

  static const int notifTrimester = 1101;
  static const int notifPregnancyWeekly = 1102;

  static const int notifLogReminder = 1200;
  static const int notifVitamins = 1201;

  static const int notifTest = 9999;

  /// All scheduled phase reminders - useful when toggling notifs off.
  static const List<int> notifAllPhaseIds = [
    notifPeriod3Days,
    notifPeriod2Days,
    notifPeriod1Day,
    notifPeriodToday,
    notifPeriodLate,
    notifFertile3Days,
    notifFertile2Days,
    notifFertile1Day,
    notifOvulation,
    notifTrimester,
    notifPregnancyWeekly,
    notifVitamins,
  ];

  static const String prefsOnboardingComplete = 'onboarding_complete';
  static const String prefsNotificationsEnabled = 'notifications_enabled';

  static const String storeAccounts = 'cyclus.accounts';
  static const String storeSession = 'cyclus.session_uid';
  static const String storeShareCodes = 'cyclus.share_codes';
}

/// Symptom categories shown in daily log - tailored per tracking mode.
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

  static const List<String> fertilitySigns = [
    'Ovulation pain',
    'Egg-white mucus',
    'Positive OPK',
    'High libido',
    'Mittelschmerz',
  ];

  static const List<String> pregnancyPhysical = [
    'Nausea',
    'Heartburn',
    'Swelling',
    'Backache',
    'Fatigue',
    'Cravings',
    'Baby kicks',
    'Braxton Hicks',
    'Headache',
    'Insomnia',
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

  static List<String> physicalFor(TrackingMode? mode) => switch (mode) {
        TrackingMode.pregnancy => pregnancyPhysical,
        TrackingMode.conception => [...physical, ...fertilitySigns],
        _ => physical,
      };

  static bool showsFlow(TrackingMode? mode) => mode != TrackingMode.pregnancy;
}
