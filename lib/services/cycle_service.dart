import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/cycle.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';

/// All cycle & daily-log persistence lives here.
///
/// Firestore layout:
///   users/{uid}                      -> UserProfile
///   users/{uid}/cycles/{cycleId}     -> Cycle (one per period)
///   users/{uid}/logs/{yyyy-MM-dd}    -> DailyLog
class CycleService {
  CycleService(this.uid, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;
  static const _uuid = Uuid();

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _cyclesRef =>
      _userDoc.collection('cycles');

  CollectionReference<Map<String, dynamic>> get _logsRef =>
      _userDoc.collection('logs');

  // ---------- Profile ----------
  Future<UserProfile?> getProfile() async {
    final snap = await _userDoc.get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data()!);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _userDoc.set(profile.toMap(), SetOptions(merge: true));
    final username = profile.username;
    if (username != null && username.isNotEmpty) {
      // Best-effort write to the public lookup doc. If Firestore rules don't
      // allow it the core flow shouldn't break — sign-in by email still works.
      try {
        await _db
            .collection('usernames')
            .doc(username.toLowerCase())
            .set({'uid': profile.uid, 'email': profile.email});
      } catch (e) {
        // Log only — username login will fall back to email login.
        // ignore: avoid_print
        print('Username lookup doc write failed (rules?): $e');
      }
    }
  }

  Stream<UserProfile?> watchProfile() => _userDoc.snapshots().map(
        (snap) => snap.exists ? UserProfile.fromMap(snap.data()!) : null,
      );

  // ---------- Cycles ----------
  Stream<List<Cycle>> watchCycles() {
    return _cyclesRef
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Cycle.fromMap(d.data())).toList());
  }

  Future<List<Cycle>> getCycles() async {
    final snap =
        await _cyclesRef.orderBy('startDate', descending: true).get();
    return snap.docs.map((d) => Cycle.fromMap(d.data())).toList();
  }

  /// Marks today (or [startDate]) as the start of a new period.
  /// If the previous cycle has no end/length, we close it out with today's date.
  Future<Cycle> startNewCycle({
    required DateTime startDate,
    required int defaultPeriodLength,
  }) async {
    final cycles = await getCycles();
    if (cycles.isNotEmpty) {
      final prev = cycles.first;
      if (prev.cycleLength == null) {
        final length =
            startDate.difference(prev.startDate).inDays.clamp(1, 90);
        await _cyclesRef.doc(prev.id).update({
          'cycleLength': length,
          'endDate': Timestamp.fromDate(
              startDate.subtract(const Duration(days: 1))),
        });
      }
    }

    final cycle = Cycle(
      id: _uuid.v4(),
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      periodLength: defaultPeriodLength,
    );
    await _cyclesRef.doc(cycle.id).set(cycle.toMap());
    return cycle;
  }

  Future<void> updateCycle(Cycle cycle) =>
      _cyclesRef.doc(cycle.id).set(cycle.toMap());

  Future<void> deleteCycle(String cycleId) =>
      _cyclesRef.doc(cycleId).delete();

  /// End an in-progress period.
  Future<void> endPeriod(Cycle cycle, DateTime endDate) async {
    final periodLength =
        endDate.difference(cycle.startDate).inDays.abs() + 1;
    await _cyclesRef.doc(cycle.id).update({
      'periodLength': periodLength,
    });
  }

  // ---------- Daily logs ----------
  Stream<List<DailyLog>> watchLogs({DateTime? from, DateTime? to}) {
    Query<Map<String, dynamic>> q = _logsRef.orderBy('date');
    if (from != null) {
      q = q.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return q.snapshots().map(
          (snap) => snap.docs.map((d) => DailyLog.fromMap(d.data())).toList(),
        );
  }

  Future<DailyLog?> getLogForDay(DateTime date) async {
    final doc = DailyLog(date: date).docId;
    final snap = await _logsRef.doc(doc).get();
    if (!snap.exists) return null;
    return DailyLog.fromMap(snap.data()!);
  }

  Future<void> saveLog(DailyLog log) async {
    if (log.isEmpty) {
      await _logsRef.doc(log.docId).delete().catchError((_) {});
      return;
    }
    await _logsRef.doc(log.docId).set(log.toMap());
  }

  // ---------- Account wipe ----------
  /// Deletes all cycles, logs, share codes, and the user profile doc.
  /// Tries to also remove partnerships where this user is owner or viewer.
  /// Best-effort: ignores individual delete failures so a single rules issue
  /// doesn't strand the user.
  Future<void> wipeAccountData() async {
    Future<void> deleteCollection(
        CollectionReference<Map<String, dynamic>> ref) async {
      const batchSize = 200;
      while (true) {
        final snap = await ref.limit(batchSize).get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
        if (snap.docs.length < batchSize) break;
      }
    }

    try {
      await deleteCollection(_cyclesRef);
    } catch (_) {}
    try {
      await deleteCollection(_logsRef);
    } catch (_) {}

    // Share codes owned by this user.
    try {
      final codes =
          await _db.collection('share_codes').where('uid', isEqualTo: uid).get();
      for (final d in codes.docs) {
        await d.reference.delete().catchError((_) {});
      }
    } catch (_) {}

    // Partnerships where this user is viewer or owner.
    try {
      final asViewer = await _db
          .collection('partnerships')
          .where('viewerUid', isEqualTo: uid)
          .get();
      for (final d in asViewer.docs) {
        await d.reference.delete().catchError((_) {});
      }
      final asOwner = await _db
          .collection('partnerships')
          .where('ownerUid', isEqualTo: uid)
          .get();
      for (final d in asOwner.docs) {
        await d.reference.delete().catchError((_) {});
      }
    } catch (_) {}

    // Username lookup doc.
    try {
      final profile = await getProfile();
      final username = profile?.username;
      if (username != null && username.isNotEmpty) {
        await _db
            .collection('usernames')
            .doc(username.toLowerCase())
            .delete()
            .catchError((_) {});
      }
    } catch (_) {}

    // Finally the user doc itself.
    try {
      await _userDoc.delete();
    } catch (_) {}
  }
}
