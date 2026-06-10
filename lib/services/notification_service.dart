import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';

/// Wraps flutter_local_notifications for predictive period reminders.
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

  Future<void> cancelAll() => _plugin.cancelAll();

  /// All lead-up offsets we schedule notifications for, ordered far → near.
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

  /// Time of day at which scheduled reminders fire. Defaults to 9:00.
  /// [CycleProvider] calls [setReminderTime] before scheduling so the user's
  /// preferred time from their profile is respected.
  int _reminderHour = 9;
  int _reminderMinute = 0;

  void setReminderTime({required int hour, required int minute}) {
    _reminderHour = hour.clamp(0, 23);
    _reminderMinute = minute.clamp(0, 59);
  }

  /// Cancel any previously scheduled phase reminders. Useful before
  /// re-scheduling or when the user disables notifications.
  Future<void> cancelAllPhaseReminders() async {
    for (final id in AppConstants.notifAllPhaseIds) {
      await _plugin.cancel(id);
    }
  }

  /// Schedule period reminders 3, 2, and 1 day(s) before [nextPeriodStart].
  /// Skips any that would fire in the past.
  Future<void> schedulePeriodReminder({
    required DateTime nextPeriodStart,
  }) async {
    for (final entry in _periodLeadDays.entries) {
      await _plugin.cancel(entry.value);
    }
    final now = DateTime.now();
    for (final entry in _periodLeadDays.entries) {
      final days = entry.key;
      final id = entry.value;
      final lead = nextPeriodStart.subtract(Duration(days: days));
      final at = DateTime(
          lead.year, lead.month, lead.day, _reminderHour, _reminderMinute);
      if (at.isBefore(now)) continue;

      final (title, body) = switch (days) {
        3 => (
            'Your period is in 3 days 🌸',
            'Time to stock up and listen to your body.',
          ),
        2 => (
            'Your period is in 2 days 🌸',
            'Take it slow and prioritize rest.',
          ),
        _ => (
            'Your period starts tomorrow 🌸',
            'Get cozy — you\'ve got this.',
          ),
      };
      await _schedule(id: id, title: title, body: body, at: at);
    }
  }

  /// Schedule fertile-window reminders 3, 2, and 1 day(s) before
  /// [fertileWindowStart]. Skips any that would fire in the past.
  Future<void> scheduleFertileWindowReminder({
    required DateTime fertileWindowStart,
  }) async {
    for (final entry in _fertileLeadDays.entries) {
      await _plugin.cancel(entry.value);
    }
    final now = DateTime.now();
    for (final entry in _fertileLeadDays.entries) {
      final days = entry.key;
      final id = entry.value;
      final lead = fertileWindowStart.subtract(Duration(days: days));
      final at = DateTime(
          lead.year, lead.month, lead.day, _reminderHour, _reminderMinute);
      if (at.isBefore(now)) continue;

      final (title, body) = switch (days) {
        3 => (
            'High-fertility window in 3 days 🌿',
            'Your most fertile days are coming up soon.',
          ),
        2 => (
            'High-fertility window in 2 days 🌿',
            'Get ready — peak days are nearly here.',
          ),
        _ => (
            'High-fertility window starts tomorrow 🌿',
            'Your highest-chance days begin tomorrow.',
          ),
      };
      await _schedule(id: id, title: title, body: body, at: at);
    }
  }

  /// For pregnancy mode: remind about upcoming trimester milestones 3 days
  /// before.
  Future<void> scheduleTrimesterReminder({
    required DateTime nextTrimesterStart,
    required String trimesterLabel,
  }) async {
    await _plugin.cancel(AppConstants.notifTrimester);
    final lead = nextTrimesterStart.subtract(const Duration(days: 3));
    final at = DateTime(
        lead.year, lead.month, lead.day, _reminderHour, _reminderMinute);
    if (at.isBefore(DateTime.now())) return;

    await _schedule(
      id: AppConstants.notifTrimester,
      title: '$trimesterLabel coming up 🤰',
      body: 'Begins in about 3 days.',
      at: at,
    );
  }

  /// One-off notification for the user to verify the plumbing actually works
  /// on their device (permissions, channels, etc.). Shows an immediate
  /// notification (so we don't depend on the scheduler) and *throws* on any
  /// failure so the UI can surface the real error.
  Future<void> sendTestNotification() async {
    await _plugin.cancel(AppConstants.notifTest);
    await _plugin.show(
      AppConstants.notifTest,
      'Cyclus notifications work ✅',
      'You\'ll get reminders 3, 2, and 1 day before your period and fertile window.',
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

  Future<void> scheduleDailyLogReminder({int hour = 20, int minute = 0}) async {
    await _plugin.cancel(AppConstants.notifLogReminder);
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    await _schedule(
      id: AppConstants.notifLogReminder,
      title: 'How are you feeling today? 💗',
      body: 'Tap to log your symptoms and mood.',
      at: at,
      repeatDaily: true,
    );
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
        matchDateTimeComponents:
            repeatDaily ? DateTimeComponents.time : null,
      );
    } catch (e) {
      if (kDebugMode) print('Notification schedule failed: $e');
    }
  }
}

