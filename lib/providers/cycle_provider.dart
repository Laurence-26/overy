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
  String? _boundUid;

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

  TrackingMode? get trackingMode => _profile?.trackingMode;

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

  int get totalKicks {
    var total = 0;
    for (final log in _logsByDocId.values) {
      total += log.symptoms.where((s) => s == 'Baby kicks').length;
    }
    return total;
  }

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

  void bind(
    String uid, {
    String email = '',
    String? username,
    String? displayName,
    bool partnerOnly = false,
  }) {
    if (_boundUid == uid && _service != null) {
      unawaited(ensureProfile(
        uid: uid,
        email: email,
        username: username,
        displayName: displayName,
        partnerOnly: partnerOnly,
      ));
      return;
    }
    unbind();
    _boundUid = uid;
    _service = CycleService(uid);
    _loading = true;

    _profileSub = _service!.watchProfile().listen((p) {
      if (p != null) _profile = p;
      _recompute();
    });
    _cyclesSub = _service!.watchCycles().listen((cs) {
      _cycles = cs;
      _recompute();
    });
    final from = DateTime.now().subtract(const Duration(days: 400));
    _logsSub = _service!.watchLogs(from: from).listen((logs) {
      _logsByDocId = {for (final l in logs) l.docId: l};
      _loading = false;
      _recompute();
    });

    unawaited(ensureProfile(
      uid: uid,
      email: email,
      username: username,
      displayName: displayName,
      partnerOnly: partnerOnly,
    ));
  }

  void unbind() {
    _cyclesSub?.cancel();
    _profileSub?.cancel();
    _logsSub?.cancel();
    _service = null;
    _boundUid = null;
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
      logs: allLogs,
      userReportedIrregular: _profile?.hasIrregularCycles == true,
      age: _profile?.age,
    );
    _refreshNotifications();
    notifyListeners();
  }

  Future<void> _refreshNotifications() async {
    final profile = _profile;
    if (profile == null) return;
    if (profile.notificationsEnabled == false) {
      await NotificationService.instance.cancelAll();
      return;
    }

    await NotificationService.instance.requestPermissions();
    final mode = profile.trackingMode ?? TrackingMode.period;
    await NotificationService.instance.rescheduleForPerson(
      profile: profile,
      prediction: _prediction,
      phase: phaseFor(DateTime.now()),
      logs: allLogs,
      pregnancy: mode == TrackingMode.pregnancy ? pregnancyStatus : null,
    );
  }

  CyclePhase phaseFor(DateTime day) => PredictionEngine.phaseFor(
        day: day,
        cyclesNewestFirst: _cycles,
        prediction: _prediction,
      );

  Future<void> ensureProfile({
    required String uid,
    required String email,
    String? username,
    String? displayName,
    bool partnerOnly = false,
  }) async {
    final service = _service;
    if (service == null) return;
    try {
      final existing = await service.getProfile();
      if (existing != null) {
        UserProfile next = existing;
        if (existing.username == null && username != null) {
          next = next.copyWith(username: username);
        }
        // Only mark brand-new / empty profiles as partner-only. Never convert
        // an existing period tracker into partner mode.
        if (partnerOnly &&
            !existing.partnerOnlyMode &&
            existing.trackingMode == null &&
            existing.setupComplete != true) {
          next = next.copyWith(partnerOnlyMode: true, setupComplete: true);
        }
        if (!identical(next, existing) &&
            (next.username != existing.username ||
                next.partnerOnlyMode != existing.partnerOnlyMode ||
                next.setupComplete != existing.setupComplete)) {
          await service.saveProfile(next);
          _profile = next;
          _loading = false;
          notifyListeners();
        } else if (_profile == null) {
          _profile = existing;
          _loading = false;
          notifyListeners();
        }
        return;
      }
      final created = UserProfile(
        uid: uid,
        email: email,
        username: username,
        displayName: displayName ?? username,
        createdAt: DateTime.now(),
        partnerOnlyMode: partnerOnly,
        setupComplete: partnerOnly,
      );
      await service.saveProfile(created);
      _profile = created;
      _loading = false;
      notifyListeners();
    } catch (e, st) {
      debugPrint('ensureProfile failed: $e\n$st');
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile p) async {
    await _service!.saveProfile(p);
  }

  Future<void> startPeriod(DateTime date, {DateTime? dateLatest}) async {
    await _service!.startNewCycle(
      startDate: date,
      startDateLatest: dateLatest,
      defaultPeriodLength:
          _profile?.averagePeriodLength ?? AppConstants.defaultPeriodLength,
    );
    final log =
        (logForDay(date) ?? DailyLog(date: date)).copyWith(flow: 'Medium');
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

  Future<void> wipeAccountData() async {
    if (_service == null) return;
    await NotificationService.instance.cancelAll();
    await _service!.wipeAccountData();
    _profile = null;
    _cycles = const [];
    _logsByDocId = const {};
    _prediction = null;
    notifyListeners();
  }

  /// Seeds in-memory demo data for store screenshots (no disk I/O).
  @visibleForTesting
  void loadStoreDemo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStart = today.subtract(const Duration(days: 13));
    final prevStart = currentStart.subtract(const Duration(days: 28));
    final prev2Start = prevStart.subtract(const Duration(days: 29));
    final prev3Start = prev2Start.subtract(const Duration(days: 27));

    _cycles = [
      Cycle(
        id: 'demo-current',
        startDate: currentStart,
        periodLength: 5,
      ),
      Cycle(
        id: 'demo-1',
        startDate: prevStart,
        endDate: currentStart.subtract(const Duration(days: 1)),
        periodLength: 5,
        cycleLength: 28,
      ),
      Cycle(
        id: 'demo-2',
        startDate: prev2Start,
        endDate: prevStart.subtract(const Duration(days: 1)),
        periodLength: 5,
        cycleLength: 29,
      ),
      Cycle(
        id: 'demo-3',
        startDate: prev3Start,
        endDate: prev2Start.subtract(const Duration(days: 1)),
        periodLength: 4,
        cycleLength: 27,
      ),
    ];

    _profile = UserProfile(
      uid: 'demo-store',
      email: '',
      username: 'ROSE',
      displayName: 'ROSE',
      createdAt: today.subtract(const Duration(days: 120)),
      trackingMode: TrackingMode.period,
      setupComplete: true,
      hasSeenTutorial: true,
      averageCycleLength: 28,
      averagePeriodLength: 5,
      themeId: 'blossom',
      themePrefs: const {
        'lookId': 'blossom',
        'motifId': 'flowers',
        'cycleViewId': 'flower',
        'showBackground': true,
        'backgroundImageStrength': 0.55,
      },
    );

    _prediction = PredictionEngine.predict(
      cyclesNewestFirst: _cycles,
      fallbackCycleLength: 28,
      fallbackPeriodLength: 5,
      now: today,
    );
    _loading = false;
    notifyListeners();
  }

  Future<void> logBabyKick() async {
    final today = DateTime.now();
    final existing = logForDay(today) ?? DailyLog(date: today);
    final updated = existing.copyWith(
      symptoms: [...existing.symptoms, 'Baby kicks'],
    );
    await _service!.saveLog(updated);
  }

  Future<void> setTrackingMode(TrackingMode mode) async {
    if (_profile == null) return;
    await _service!.saveProfile(_profile!.copyWith(trackingMode: mode));
  }

  Future<void> markSetupComplete() async {
    if (_profile == null) return;
    await _service!.saveProfile(_profile!.copyWith(setupComplete: true));
  }

  Future<Map<String, dynamic>> exportPartnerSnapshot() async {
    if (_service == null) {
      throw Exception('No profile is open.');
    }
    return _service!.exportSnapshot();
  }

  Future<String> importPartnerSnapshot(Map<String, dynamic> data) async {
    final importedUid = await CycleService.importSnapshot(data);
    final profile = _profile;
    if (profile != null) {
      await updateProfile(profile.copyWith(addLinkedPartnerUid: importedUid));
    }
    return importedUid;
  }

  @override
  void dispose() {
    unbind();
    super.dispose();
  }
}
