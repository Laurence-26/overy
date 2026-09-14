import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/cycle.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import 'local_store.dart';

/// All cycle & daily-log persistence. Lives entirely on this device.
///
/// Layout (SharedPreferences keys):
/// cyclus.user.{uid}.profile -> UserProfile
/// cyclus.user.{uid}.cycles -> List<Cycle>
/// cyclus.user.{uid}.logs -> List<DailyLog>
class CycleService {
  CycleService(this.uid);

  final String uid;
  final _store = LocalStore.instance;
  static const _uuid = Uuid();

  String get _profileKey => 'cyclus.user.$uid.profile';
  String get _cyclesKey => 'cyclus.user.$uid.cycles';
  String get _logsKey => 'cyclus.user.$uid.logs';

  bool _isMine(String key) =>
      key == _profileKey || key == _cyclesKey || key == _logsKey;

  Stream<UserProfile?> watchProfile() async* {
    yield await getProfile();
    await for (final key in _store.changes) {
      if (_isMine(key)) yield await getProfile();
    }
  }

  Stream<List<Cycle>> watchCycles() async* {
    yield await getCycles();
    await for (final key in _store.changes) {
      if (_isMine(key)) yield await getCycles();
    }
  }

  Stream<List<DailyLog>> watchLogs({DateTime? from, DateTime? to}) async* {
    yield await _filteredLogs(from: from, to: to);
    await for (final key in _store.changes) {
      if (_isMine(key)) yield await _filteredLogs(from: from, to: to);
    }
  }

  Future<UserProfile?> getProfile() async {
    final m = await _store.getJson(_profileKey);
    if (m == null) return null;
    return UserProfile.fromMap(m);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _store.setJson(_profileKey, profile.toMap());
  }

  Future<List<Cycle>> getCycles() async {
    final list = await _store.getJsonList(_cyclesKey);
    final cycles = list.map(Cycle.fromMap).toList();
    cycles.sort((a, b) => b.startDate.compareTo(a.startDate));
    return cycles;
  }

  Future<void> _saveCycles(List<Cycle> cycles) async {
    await _store.setJsonList(
      _cyclesKey,
      cycles.map((c) => c.toMap()).toList(),
    );
  }

  Future<List<DailyLog>> _allLogs() async {
    final list = await _store.getJsonList(_logsKey);
    return list.map(DailyLog.fromMap).toList();
  }

  Future<List<DailyLog>> _filteredLogs({DateTime? from, DateTime? to}) async {
    var logs = await _allLogs();
    if (from != null) {
      logs = logs.where((l) => !l.date.isBefore(from)).toList();
    }
    if (to != null) {
      logs = logs.where((l) => !l.date.isAfter(to)).toList();
    }
    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  Future<void> _saveLogs(List<DailyLog> logs) async {
    await _store.setJsonList(_logsKey, logs.map((l) => l.toMap()).toList());
  }

  /// Marks today (or [startDate]) as the start of a new period.
  /// If the previous cycle has no end/length, we close it out with today's date.
  Future<Cycle> startNewCycle({
    required DateTime startDate,
    DateTime? startDateLatest,
    required int defaultPeriodLength,
  }) async {
    final cycles = await getCycles();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime? latest;
    if (startDateLatest != null) {
      latest = DateTime(
          startDateLatest.year, startDateLatest.month, startDateLatest.day);
      if (latest.isBefore(start)) latest = start;
    }
    if (cycles.isNotEmpty) {
      final prev = cycles.first;
      if (prev.cycleLength == null) {
        final length = start.difference(prev.startDate).inDays.clamp(1, 90);
        cycles[0] = prev.copyWith(
          cycleLength: length,
          endDate: start.subtract(const Duration(days: 1)),
        );
      }
    }

    final cycle = Cycle(
      id: _uuid.v4(),
      startDate: start,
      startDateLatest: latest != null && latest != start ? latest : null,
      periodLength: defaultPeriodLength,
    );
    cycles.insert(0, cycle);
    await _saveCycles(cycles);
    return cycle;
  }

  Future<void> updateCycle(Cycle cycle) async {
    final cycles = await getCycles();
    final i = cycles.indexWhere((c) => c.id == cycle.id);
    if (i >= 0) {
      cycles[i] = cycle;
      await _saveCycles(cycles);
    }
  }

  Future<void> deleteCycle(String cycleId) async {
    final cycles = await getCycles();
    cycles.removeWhere((c) => c.id == cycleId);
    await _saveCycles(cycles);
  }

  Future<void> endPeriod(Cycle cycle, DateTime endDate) async {
    final periodLength = endDate.difference(cycle.startDate).inDays.abs() + 1;
    await updateCycle(cycle.copyWith(periodLength: periodLength));
  }

  Future<DailyLog?> getLogForDay(DateTime date) async {
    final id = DailyLog(date: date).docId;
    final logs = await _allLogs();
    for (final l in logs) {
      if (l.docId == id) return l;
    }
    return null;
  }

  Future<void> saveLog(DailyLog log) async {
    final logs = await _allLogs();
    logs.removeWhere((l) => l.docId == log.docId);
    if (!log.isEmpty) logs.add(log);
    await _saveLogs(logs);
  }

  Future<void> wipeAccountData() async {
    await _store.remove(_profileKey);
    await _store.remove(_cyclesKey);
    await _store.remove(_logsKey);

    final codes = await _store.getJson(AppConstants.storeShareCodes) ?? {};
    final next = Map<String, dynamic>.from(codes)
      ..removeWhere((_, v) {
        if (v is Map && v['uid'] == uid) return true;
        return false;
      });
    await _store.setJson(AppConstants.storeShareCodes, next);
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    final profile = await getProfile();
    if (profile == null) {
      throw Exception('No cycle data to share yet.');
    }
    final cycles = await getCycles();
    final logs = await _allLogs();
    return {
      'kind': 'cyclus.partner.snapshot',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'ownerUid': uid,
      'profile': profile.toMap(),
      'cycles': cycles.map((c) => c.toMap()).toList(),
      'logs': logs.map((l) => l.toMap()).toList(),
    };
  }

  static String importedUidFor(String ownerUid) => 'imported_$ownerUid';

  /// Writes a received snapshot as a local read-only copy and returns its uid.
  static Future<String> importSnapshot(Map<String, dynamic> data) async {
    if (data['kind'] != 'cyclus.partner.snapshot') {
      throw Exception('That file is not a Cyclus share.');
    }
    final ownerUid = (data['ownerUid'] as String?)?.trim();
    if (ownerUid == null || ownerUid.isEmpty) {
      throw Exception('Share file is missing a profile id.');
    }
    final rawProfile = data['profile'];
    if (rawProfile is! Map) {
      throw Exception('Share file is missing profile data.');
    }
    final importedUid = importedUidFor(ownerUid);
    final profileMap = Map<String, dynamic>.from(rawProfile);
    profileMap['uid'] = importedUid;
    final cycles = <Cycle>[];
    final rawCycles = data['cycles'];
    if (rawCycles is List) {
      for (final item in rawCycles.whereType<Map>()) {
        cycles.add(Cycle.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    final logs = <DailyLog>[];
    final rawLogs = data['logs'];
    if (rawLogs is List) {
      for (final item in rawLogs.whereType<Map>()) {
        logs.add(DailyLog.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    final svc = CycleService(importedUid);
    await svc.saveProfile(UserProfile.fromMap(profileMap));
    await svc._saveCycles(cycles);
    await svc._saveLogs(logs);
    return importedUid;
  }
}
