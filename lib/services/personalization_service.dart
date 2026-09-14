import '../models/cycle_prediction.dart';
import '../models/daily_log.dart';
import '../models/pregnancy_status.dart';
import '../models/tracking_mode.dart';
import '../models/user_profile.dart';

/// Builds copy that sounds like it was written for *this* person:
/// her name, her mode, her phase, her usual symptoms.
class PersonalizationService {
  PersonalizationService._();

  static String firstName(UserProfile? profile) =>
      profile?.greetingName ?? 'love';

  static (String title, String body) periodLead({
    required UserProfile? profile,
    required int days,
    required List<DailyLog> recentLogs,
  }) {
    final name = firstName(profile);
    final irregular = profile?.hasIrregularCycles == true;
    final pms = _usualPms(recentLogs);
    final rest = pms == null
        ? 'Take it slow and listen to your body.'
        : 'You often get $pms around now - be extra kind to yourself.';

    return switch (days) {
      3 => (
          irregular
              ? '$name, your period may start in about 3 days'
              : '$name, your period is in 3 days',
          irregular
              ? 'Windows can shift with irregular cycles. $rest'
              : 'Time to stock up. $rest',
        ),
      2 => (
          '$name, period in 2 days',
          rest,
        ),
      _ => (
          '$name, your period starts tomorrow',
          pms == null
              ? 'Get cozy - you\'ve got this.'
              : 'Tomorrow may bring $pms. Heat pad, water, rest.',
        ),
    };
  }

  static (String title, String body) periodToday(UserProfile? profile) {
    final name = firstName(profile);
    return (
      '$name, your period is likely today',
      'Log your flow when you can - it makes tomorrow\'s prediction sharper.',
    );
  }

  static (String title, String body) periodLate(UserProfile? profile) {
    final name = firstName(profile);
    return (
      '$name, your period looks late',
      'That\'s common, especially with stress or irregular cycles. Log it when it starts so we can re-learn your rhythm.',
    );
  }

  static (String title, String body) fertileLead({
    required UserProfile? profile,
    required int days,
    required TrackingMode mode,
  }) {
    final name = firstName(profile);
    if (mode == TrackingMode.conception) {
      return switch (days) {
        3 => (
            '$name, high-chance days in 3 days',
            'Your most fertile window is coming. A positive OPK around then is extra useful.',
          ),
        2 => (
            '$name, peak window in 2 days',
            'If you\'re trying, plan intimacy for the next few days.',
          ),
        _ => (
            '$name, high-chance window starts tomorrow',
            'Egg-white mucus or a positive OPK means you\'re right on time.',
          ),
      };
    }
    return switch (days) {
      3 => (
          '$name, fertile window in 3 days',
          'A heads-up so you can plan your week.',
        ),
      2 => (
          '$name, fertile window in 2 days',
          'Energy often lifts here - nice day for a walk.',
        ),
      _ => (
          '$name, fertile window starts tomorrow',
          'You might notice more energy or cervical mucus changes.',
        ),
    };
  }

  static (String title, String body) ovulationDay({
    required UserProfile? profile,
    required TrackingMode mode,
  }) {
    final name = firstName(profile);
    if (mode == TrackingMode.conception) {
      return (
        '$name, today is your peak day',
        'Highest chance of conceiving. Logging an OPK or mucus today trains future predictions.',
      );
    }
    return (
      '$name, ovulation is likely today',
      'You may feel a one-sided twinge or extra energy. Totally normal.',
    );
  }

  static (String title, String body) dailyLog({
    required UserProfile? profile,
    required CyclePhase phase,
    required TrackingMode mode,
    PregnancyStatus? pregnancy,
  }) {
    final name = firstName(profile);
    if (mode == TrackingMode.pregnancy) {
      final week = pregnancy?.weeksAlong;
      return (
        week == null
            ? '$name, how are you and baby today?'
            : '$name, week $week check-in',
        pregnancy != null && pregnancy.trimester == 1
            ? 'Nausea, fatigue, and tiny meals are so common right now. Log what you feel.'
            : 'A few taps on kicks, swelling, or mood helps you see patterns.',
      );
    }
    if (mode == TrackingMode.conception) {
      return switch (phase) {
        CyclePhase.fertile || CyclePhase.ovulation => (
            '$name, peak days - log today',
            'OPK, mucus, or intimacy notes make your fertile window more accurate.',
          ),
        CyclePhase.luteal => (
            '$name, two-week wait check-in',
            'This phase can feel long. Capture mood or symptoms - no pressure.',
          ),
        _ => (
            '$name, how are you feeling today?',
            'A quick log keeps your high-chance days honest.',
          ),
      };
    }
    return switch (phase) {
      CyclePhase.period => (
          '$name, period day check-in',
          'Flow, cramps, mood - whatever you want to remember.',
        ),
      CyclePhase.luteal => (
          '$name, luteal-phase check-in',
          'PMS can sneak in here. Logging now helps us warn you next cycle.',
        ),
      CyclePhase.follicular => (
          '$name, how\'s your energy today?',
          'This is often your brighter stretch. Capture it if you like.',
        ),
      _ => (
          '$name, how are you feeling today?',
          'Tap to log symptoms and mood - it stays on this device.',
        ),
    };
  }

  static (String title, String body) vitamins(UserProfile? profile) {
    final name = firstName(profile);
    return (
      '$name, prenatal vitamin time',
      'A gentle nudge - same time every day is the easiest habit.',
    );
  }

  static (String title, String body) trimester({
    required UserProfile? profile,
    required String trimesterLabel,
  }) {
    final name = firstName(profile);
    return (
      '$name, $trimesterLabel is almost here',
      'Begins in about 3 days. New symptoms can show up - log them if you want a record.',
    );
  }

  static (String title, String body) pregnancyWeek(
      UserProfile? profile, int week) {
    final name = firstName(profile);
    return (
      '$name, you\'re in week $week',
      week < 13
          ? 'First trimester: rest counts as progress.'
          : week < 28
              ? 'Second trimester: a good week to notice kicks and energy.'
              : 'Third trimester: slower days, extra pillows, you\'re doing great.',
    );
  }

  /// Short card copy for the Today tab.
  static String todayTip({
    required UserProfile? profile,
    required TrackingMode mode,
    required CyclePhase phase,
    PregnancyStatus? pregnancy,
    List<DailyLog> recentLogs = const [],
  }) {
    final name = firstName(profile);
    if (mode == TrackingMode.pregnancy) {
      final w = pregnancy?.weeksAlong;
      if (w == null) return 'Add your due date and this space becomes yours.';
      if (profile?.takingPrenatalVitamins == true) {
        return '$name, week $w - prenatal vitamin + water is a solid pair today.';
      }
      return '$name, week $w. Small meals, extra rest, and a kick log if you feel them.';
    }
    if (mode == TrackingMode.conception) {
      return switch (phase) {
        CyclePhase.ovulation =>
          '$name, peak day. If you\'re trying, today and yesterday matter most.',
        CyclePhase.fertile =>
          '$name, you\'re in your high-chance window. Log mucus or an OPK if you have one.',
        CyclePhase.luteal =>
          'Two-week wait. Whatever happens, logging symptoms still trains your next window.',
        CyclePhase.period =>
          'Period days. When it ends, your next fertile window will be clearer.',
        _ =>
          'Building toward your next window. Regular sleep helps ovulation stay predictable.',
      };
    }
    final pms = _usualPms(recentLogs);
    return switch (phase) {
      CyclePhase.period => pms == null
          ? '$name, period day. Heat, water, and whatever food sounds good.'
          : '$name, you often get $pms on period days - plan a slower evening.',
      CyclePhase.luteal => pms == null
          ? 'Luteal phase - cravings and mood swings are hormones, not a character flaw.'
          : 'Luteal phase. $pms often shows up for you here. Extra kindness.',
      CyclePhase.fertile ||
      CyclePhase.ovulation =>
        'Energy often peaks here. A good day for movement if you want it.',
      CyclePhase.follicular =>
        'Follicular phase - many people feel clearer and more social here.',
      CyclePhase.predicted =>
        'Period may start soon. Pack what you usually need.',
      _ =>
        'Log how you feel. The more days you capture, the sharper this gets.',
    };
  }

  static String? _usualPms(List<DailyLog> logs) {
    const watch = ['Cramps', 'Headache', 'Bloating', 'Irritable', 'Fatigue'];
    final counts = <String, int>{};
    for (final log in logs) {
      for (final s in [...log.symptoms, ...log.moods]) {
        if (watch.contains(s)) {
          counts[s] = (counts[s] ?? 0) + 1;
        }
      }
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value < 3) return null;
    return best.key.toLowerCase();
  }
}
