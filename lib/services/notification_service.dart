import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';
import '../models/cycle_prediction.dart';
import '../models/daily_log.dart';
import '../models/pregnancy_status.dart';
import '../models/tracking_mode.dart';
import '../models/user_profile.dart';
import 'personalization_service.dart';

/// Local reminders only. Copy is built from the person's name, mode, and logs.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      if (kDebugMode) print('cancelAll failed: $e');
    }
  }

  static const _periodLeadDays = <int, int>{
    3: AppConstants.notifPeriod3Days,
    2: AppConstants.notifPeriod2Days,
    1: AppConstants.notifPeriod1Day,
  };

  static const _fertileLeadDays = <int, int>{
    3: AppConstants.notifFertile3Days,
    2: AppConstants.notifFertile2Days,
    1: AppConstants.notifFertile1Day,
  };

  int _reminderHour = 9;
  int _reminderMinute = 0;

  void setReminderTime({required int hour, required int minute}) {
    _reminderHour = hour.clamp(0, 23);
    _reminderMinute = minute.clamp(0, 59);
  }

  Future<void> cancelAllPhaseReminders() async {
    for (final id in AppConstants.notifAllPhaseIds) {
      try {
        await _plugin.cancel(id);
      } catch (e) {
        if (kDebugMode) print('cancel($id) failed: $e');
      }
    }
  }

  /// Rebuilds every reminder from the person's profile, mode, and prediction.
  Future<void> rescheduleForPerson({
    required UserProfile profile,
    required CyclePrediction? prediction,
    required CyclePhase phase,
    required List<DailyLog> logs,
    PregnancyStatus? pregnancy,
  }) async {
    await cancelAllPhaseReminders();
    if (!profile.notificationsEnabled) return;

    setReminderTime(
      hour: profile.reminderHour,
      minute: profile.reminderMinute,
    );

    final mode = profile.trackingMode ?? TrackingMode.period;

    if (mode == TrackingMode.pregnancy) {
      if (profile.notifyTrimester && pregnancy != null) {
        final next = pregnancy.nextTrimesterStart;
        if (next != null) {
          await scheduleTrimesterReminder(
            nextTrimesterStart: next,
            trimesterLabel: pregnancy.nextTrimesterLabel ?? 'Next trimester',
            profile: profile,
          );
        }
        await _scheduleWeeklyPregnancy(profile, pregnancy);
      }
      if (profile.notifyVitamins && profile.takingPrenatalVitamins == true) {
        await scheduleVitaminReminder(profile: profile);
      }
    } else if (prediction != null) {
      if (profile.notifyPeriod) {
        await schedulePeriodReminder(
          nextPeriodStart: prediction.nextPeriodStart,
          profile: profile,
          logs: logs,
          isLate: prediction.isLate,
        );
      }
      if (profile.notifyFertile) {
        await scheduleFertileWindowReminder(
          fertileWindowStart: prediction.fertileWindowStart,
          ovulationDay: prediction.ovulationDay,
          profile: profile,
          mode: mode,
        );
      }
      if (profile.notifyVitamins &&
          mode == TrackingMode.conception &&
          profile.takingPrenatalVitamins == true) {
        await scheduleVitaminReminder(profile: profile);
      }
    }

    if (profile.notifyDailyLog) {
      await scheduleDailyLogReminder(
        hour: 20,
        minute: 0,
        profile: profile,
        phase: phase,
        mode: mode,
        pregnancy: pregnancy,
      );
    }
  }

  Future<void> schedulePeriodReminder({
    required DateTime nextPeriodStart,
    UserProfile? profile,
    List<DailyLog> logs = const [],
    bool isLate = false,
  }) async {
    for (final entry in _periodLeadDays.entries) {
      await _plugin.cancel(entry.value);
    }
    await _plugin.cancel(AppConstants.notifPeriodToday);
    await _plugin.cancel(AppConstants.notifPeriodLate);

    if (isLate) {
      final (title, body) = PersonalizationService.periodLate(profile);
      final at = _nextOccurrence(_reminderHour, _reminderMinute);
      await _schedule(
        id: AppConstants.notifPeriodLate,
        title: title,
        body: body,
        at: at,
      );
      return;
    }

    final now = DateTime.now();
    for (final entry in _periodLeadDays.entries) {
      final days = entry.key;
      final id = entry.value;
      final lead = nextPeriodStart.subtract(Duration(days: days));
      final at = DateTime(
          lead.year, lead.month, lead.day, _reminderHour, _reminderMinute);
      if (at.isBefore(now)) continue;
      final (title, body) = PersonalizationService.periodLead(
        profile: profile,
        days: days,
        recentLogs: logs,
      );
      await _schedule(id: id, title: title, body: body, at: at);
    }

    final todayAt = DateTime(
      nextPeriodStart.year,
      nextPeriodStart.month,
      nextPeriodStart.day,
      _reminderHour,
      _reminderMinute,
    );
    if (!todayAt.isBefore(now)) {
      final (title, body) = PersonalizationService.periodToday(profile);
      await _schedule(
        id: AppConstants.notifPeriodToday,
        title: title,
        body: body,
        at: todayAt,
      );
    }
  }

  Future<void> scheduleFertileWindowReminder({
    required DateTime fertileWindowStart,
    DateTime? ovulationDay,
    UserProfile? profile,
    TrackingMode mode = TrackingMode.period,
  }) async {
    for (final entry in _fertileLeadDays.entries) {
      await _plugin.cancel(entry.value);
    }
    await _plugin.cancel(AppConstants.notifOvulation);

    final now = DateTime.now();
    for (final entry in _fertileLeadDays.entries) {
      final days = entry.key;
      final id = entry.value;
      final lead = fertileWindowStart.subtract(Duration(days: days));
      final at = DateTime(
          lead.year, lead.month, lead.day, _reminderHour, _reminderMinute);
      if (at.isBefore(now)) continue;
      final (title, body) = PersonalizationService.fertileLead(
        profile: profile,
        days: days,
        mode: mode,
      );
      await _schedule(id: id, title: title, body: body, at: at);
    }

    if (ovulationDay != null) {
      final at = DateTime(
        ovulationDay.year,
        ovulationDay.month,
        ovulationDay.day,
        _reminderHour,
        _reminderMinute,
      );
      if (!at.isBefore(now)) {
        final (title, body) = PersonalizationService.ovulationDay(
          profile: profile,
          mode: mode,
        );
        await _schedule(
          id: AppConstants.notifOvulation,
          title: title,
          body: body,
          at: at,
        );
      }
    }
  }

  Future<void> scheduleTrimesterReminder({
    required DateTime nextTrimesterStart,
    required String trimesterLabel,
    UserProfile? profile,
  }) async {
    await _plugin.cancel(AppConstants.notifTrimester);
    final lead = nextTrimesterStart.subtract(const Duration(days: 3));
    final at = DateTime(
        lead.year, lead.month, lead.day, _reminderHour, _reminderMinute);
    if (at.isBefore(DateTime.now())) return;
    final (title, body) = PersonalizationService.trimester(
      profile: profile,
      trimesterLabel: trimesterLabel,
    );
    await _schedule(
      id: AppConstants.notifTrimester,
      title: title,
      body: body,
      at: at,
    );
  }

  Future<void> _scheduleWeeklyPregnancy(
      UserProfile profile, PregnancyStatus status) async {
    await _plugin.cancel(AppConstants.notifPregnancyWeekly);
    final nextMonday = _nextOccurrence(_reminderHour, _reminderMinute);
    final (title, body) =
        PersonalizationService.pregnancyWeek(profile, status.weeksAlong);
    await _schedule(
      id: AppConstants.notifPregnancyWeekly,
      title: title,
      body: body,
      at: nextMonday,
      repeatDaily: false,
    );
  }

  Future<void> scheduleVitaminReminder({required UserProfile profile}) async {
    await _plugin.cancel(AppConstants.notifVitamins);
    final now = DateTime.now();
    var at =
        DateTime(now.year, now.month, now.day, _reminderHour, _reminderMinute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    final (title, body) = PersonalizationService.vitamins(profile);
    await _schedule(
      id: AppConstants.notifVitamins,
      title: title,
      body: body,
      at: at,
      repeatDaily: true,
    );
  }

  Future<void> sendTestNotification({UserProfile? profile}) async {
    await init();
    await requestPermissions();
    try {
      await _plugin.cancel(AppConstants.notifTest);
    } catch (_) {
      // Older release builds can fail cancel under R8; still show the test.
    }
    final name = PersonalizationService.firstName(profile);
    await _plugin.show(
      AppConstants.notifTest,
      '$name, Cyclus is ready',
      'Reminders stay on this phone and use your name, mode, and usual symptoms.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cycle_reminders',
          'Cycle reminders',
          channelDescription: 'Period predictions and daily reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleDailyLogReminder({
    int hour = 20,
    int minute = 0,
    UserProfile? profile,
    CyclePhase phase = CyclePhase.unknown,
    TrackingMode mode = TrackingMode.period,
    PregnancyStatus? pregnancy,
  }) async {
    await _plugin.cancel(AppConstants.notifLogReminder);
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    final (title, body) = PersonalizationService.dailyLog(
      profile: profile,
      phase: phase,
      mode: mode,
      pregnancy: pregnancy,
    );
    await _schedule(
      id: AppConstants.notifLogReminder,
      title: title,
      body: body,
      at: at,
      repeatDaily: true,
    );
  }

  DateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    return at;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    bool repeatDaily = false,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cycle_reminders',
            'Cycle reminders',
            channelDescription: 'Period predictions and daily reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      );
    } catch (e) {
      if (kDebugMode) print('Notification schedule failed: $e');
    }
  }
}
