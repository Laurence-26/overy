import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/cycle.dart';
import '../models/cycle_prediction.dart';
import '../models/daily_log.dart';
import '../models/pregnancy_status.dart';
import '../models/tracking_mode.dart';
import '../models/user_profile.dart';
import '../services/cycle_service.dart';
import '../services/notification_service.dart';
import '../services/prediction_engine.dart';

/// Holds the user's cycles, daily logs, profile, and live prediction.
class CycleProvider extends ChangeNotifier {
  CycleProvider({String? uid}) {
    if (uid != null) bind(uid);
  }

  CycleService? _service;
  StreamSubscription? _cyclesSub;
  StreamSubscription? _profileSub;
  StreamSubscription? _logsSub;

  UserProfile? _profile;
  List<Cycle> _cycles = const [];
  Map<String, DailyLog> _logsByDocId = const {};
  CyclePrediction? _prediction;
  bool _loading = true;

  UserProfile? get profile => _profile;
  List<Cycle> get cycles => _cycles;
  CyclePrediction? get prediction => _prediction;
  bool get loading => _loading;
  Cycle? get currentCycle => _cycles.isNotEmpty ? _cycles.first : null;

  /// Current tracking mode — null until the user picks one.
  TrackingMode? get trackingMode => _profile?.trackingMode;

  /// Computed pregnancy snapshot when the user is in pregnancy mode.
  /// Falls back to LMP-derived data if due date isn't set.
  PregnancyStatus? get pregnancyStatus {
    if (_profile?.trackingMode != TrackingMode.pregnancy) return null;
    if (_profile?.dueDate != null) {
      return PregnancyStatus.fromDueDate(_profile!.dueDate!);
    }
    if (_profile?.lastMenstrualPeriod != null) {
      return PregnancyStatus.fromLmp(_profile!.lastMenstrualPeriod!);
    }
    if (_cycles.isNotEmpty) {
      return PregnancyStatus.fromLmp(_cycles.first.startDate);
    }
    return null;
  }

  /// Baby-kick count for pregnancy mode (sum of all 'Baby kicks' entries
  /// stored in daily logs' notes field as a number).
  int get totalKicks {
    var total = 0;
    for (final log in _logsByDocId.values) {
      if (log.symptoms.contains('Baby kicks')) total++;
    }
    return total;
  }

  /// Today's logged kick count.
  int get todayKicks {
    final today = DateTime.now();
    final log = logForDay(today);
    if (log == null) return 0;
    return log.symptoms.where((s) => s == 'Baby kicks').length;
  }

  DailyLog? logForDay(DateTime day) {
    final id = DailyLog(date: day).docId;
    return _logsByDocId[id];
  }

  List<DailyLog> get allLogs => _logsByDocId.values.toList();

  /// Bind to a freshly signed-in user.
  void bind(String uid) {
    unbind();
    _service = CycleService(uid);
    _loading = true;
    notifyListeners();

    _profileSub = _service!.watchProfile().listen((p) {
      _profile = p;
      _recompute();
    });
    _cyclesSub = _service!.watchCycles().listen((cs) {
      _cycles = cs;
      _recompute();
    });
    final from =
        DateTime.now().subtract(const Duration(days: 365));
    _logsSub = _service!.watchLogs(from: from).listen((logs) {
      _logsByDocId = {for (final l in logs) l.docId: l};
      _loading = false;
      notifyListeners();
    });
  }

  void unbind() {
    _cyclesSub?.cancel();
    _profileSub?.cancel();
    _logsSub?.cancel();
    _service = null;
    _profile = null;
    _cycles = const [];
    _logsByDocId = const {};
    _prediction = null;
    _loading = false;
  }

  void _recompute() {
    _prediction = PredictionEngine.predict(
      cyclesNewestFirst: _cycles,
      fallbackCycleLength:
          _profile?.averageCycleLength ?? AppConstants.defaultCycleLength,
      fallbackPeriodLength:
          _profile?.averagePeriodLength ?? AppConstants.defaultPeriodLength,
    );
    _refreshNotifications();
    notifyListeners();
  }

  Future<void> _refreshNotifications() async {
    if (_profile?.notificationsEnabled == false) {
      await NotificationService.instance.cancelAll();
      return;
    }

    // Auto-request permission the first time we have a prediction or pregnancy.
    await NotificationService.instance.requestPermissions();

    // Respect the user's preferred reminder time before scheduling.
    NotificationService.instance.setReminderTime(
      hour: _profile?.reminderHour ?? 9,
      minute: _profile?.reminderMinute ?? 0,
    );

    final mode = _profile?.trackingMode ?? TrackingMode.period;
    final p = _prediction;

    if (mode == TrackingMode.pregnancy) {
      // Pregnancy: schedule next trimester reminder + daily nudge only.
      final status = pregnancyStatus;
      if (status != null) {
        final next = status.nextTrimesterStart;
        if (next != null) {
          await NotificationService.instance.scheduleTrimesterReminder(
            nextTrimesterStart: next,
            trimesterLabel: status.nextTrimesterLabel ?? 'Next trimester',
          );
        }
      }
    } else if (p != null) {
      // Period / Conception: schedule three reminders each at 3, 2, 1 days
      // before the next period and the fertile-window start.
      await NotificationService.instance
          .schedulePeriodReminder(nextPeriodStart: p.nextPeriodStart);
      await NotificationService.instance.scheduleFertileWindowReminder(
          fertileWindowStart: p.fertileWindowStart);
    }

    await NotificationService.instance.scheduleDailyLogReminder();
  }

  CyclePhase phaseFor(DateTime day) => PredictionEngine.phaseFor(
        day: day,
        cyclesNewestFirst: _cycles,
        prediction: _prediction,
      );

  // ----- Mutations -----
  Future<void> ensureProfile({
    required String uid,
    required String email,
    String? username,
    String? displayName,
  }) async {
    final existing = await _service!.getProfile();
    if (existing != null) {
      // Backfill username if missing (e.g. user signed up via Google).
      if (existing.username == null && username != null) {
        await _service!.saveProfile(existing.copyWith(username: username));
      }
      return;
    }
    await _service!.saveProfile(UserProfile(
      uid: uid,
      email: email,
      username: username,
      displayName: displayName ?? username,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> updateProfile(UserProfile p) async {
    await _service!.saveProfile(p);
  }

  Future<void> startPeriod(DateTime date) async {
    await _service!.startNewCycle(
      startDate: date,
      defaultPeriodLength:
          _profile?.averagePeriodLength ?? AppConstants.defaultPeriodLength,
    );
    final log = (logForDay(date) ?? DailyLog(date: date))
        .copyWith(flow: 'Medium');
    await _service!.saveLog(log);
  }

  Future<void> endPeriod(DateTime endDate) async {
    final c = currentCycle;
    if (c == null) return;
    await _service!.endPeriod(c, endDate);
  }

  Future<void> saveDailyLog(DailyLog log) async {
    await _service!.saveLog(log);
  }

  Future<void> deleteCycle(String cycleId) async {
    await _service!.deleteCycle(cycleId);
  }

  /// Wipe all Firestore data owned by the current user. Caller is responsible
  /// for deleting the Firebase Auth user separately (it may require recent
  /// login).
  Future<void> wipeAccountData() async {
    if (_service == null) return;
    await NotificationService.instance.cancelAll();
    await _service!.wipeAccountData();
    // Clear local cached state.
    _profile = null;
    _cycles = const [];
    _logsByDocId = const {};
    _prediction = null;
    notifyListeners();
  }

  /// Append a single "Baby kicks" marker to today's log.
  Future<void> logBabyKick() async {
    final today = DateTime.now();
    final existing = logForDay(today) ?? DailyLog(date: today);
    final updated = existing.copyWith(
      symptoms: [...existing.symptoms, 'Baby kicks'],
    );
    await _service!.saveLog(updated);
  }

  /// Switch tracking mode (period / conception / pregnancy).
  /// Used both for first-time setup and "change mode" later.
  Future<void> setTrackingMode(TrackingMode mode) async {
    if (_profile == null) return;
    await _service!.saveProfile(_profile!.copyWith(trackingMode: mode));
  }

  Future<void> markSetupComplete() async {
    if (_profile == null) return;
    await _service!.saveProfile(_profile!.copyWith(setupComplete: true));
  }

  @override
  void dispose() {
    unbind();
    super.dispose();
  }
}
