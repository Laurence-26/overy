import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages partner-sharing invite codes and links.
///
/// Firestore layout:
///   share_codes/{code}  -> { uid, displayName, createdAt, expiresAt }
///       Readable by any signed-in user so a partner can look up whose code
///       it is. Only the owner can write/delete.
///   partnerships/{viewerUid_ownerUid} -> { viewerUid, ownerUid, createdAt }
///       Created when a viewer redeems a code. Readable by EITHER party.
///       This doc is what unlocks read-access on /users/{ownerUid} via rules:
///         allow read: if request.auth.uid == uid ||
///           exists(/databases/$(db)/documents/partnerships/$(request.auth.uid + '_' + uid));
///   users/{uid}.linkedPartnerUids -> list of partner uids the user is
///       following (multi-partner supported).
///
/// Codes are 6-digit numeric, valid for 24 hours.
class PartnerService {
  PartnerService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const Duration codeTtl = Duration(hours: 24);

  CollectionReference<Map<String, dynamic>> get _codesRef =>
      _db.collection('share_codes');

  CollectionReference<Map<String, dynamic>> get _partnershipsRef =>
      _db.collection('partnerships');

  /// Deterministic partnership doc id for a (viewer, owner) pair.
  static String partnershipId({
    required String viewerUid,
    required String ownerUid,
  }) =>
      '${viewerUid}_$ownerUid';

  /// Generate (or refresh) the invite code for [uid].
  /// Returns the 6-digit code. Cleans up any expired prior code for the user.
  Future<String> generateInviteCode({
    required String uid,
    String? displayName,
  }) async {
    // Reuse an unexpired code if one exists.
    final existing = await _codesRef
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final expiresAt = (doc.data()['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
        return doc.id;
      }
      // Expired — clean it up so a new unique one can be issued.
      await doc.reference.delete();
    }

    // Try a few times to avoid the rare collision on 6 digits.
    final rng = Random.secure();
    for (var attempt = 0; attempt < 6; attempt++) {
      final code = (rng.nextInt(900000) + 100000).toString();
      final ref = _codesRef.doc(code);
      final snap = await ref.get();
      if (snap.exists) continue;
      final now = DateTime.now();
      await ref.set({
        'uid': uid,
        'displayName': displayName,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(codeTtl)),
      });
      return code;
    }
    throw Exception('Could not generate a unique invite code. Try again.');
  }

  /// Resolve a code to its owner uid. Throws if missing or expired.
  Future<PartnerInvite> lookupCode(String code) async {
    final cleaned = code.trim();
    final snap = await _codesRef.doc(cleaned).get();
    if (!snap.exists) {
      throw Exception('That code doesn\'t match any active invite.');
    }
    final data = snap.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw Exception('That code has expired. Ask your partner for a new one.');
    }
    final uid = data['uid'] as String?;
    if (uid == null || uid.isEmpty) {
      throw Exception('Invite code is malformed.');
    }
    return PartnerInvite(
      code: cleaned,
      partnerUid: uid,
      partnerDisplayName: data['displayName'] as String?,
    );
  }

  /// Revoke the user's own invite code.
  Future<void> revokeInviteCode(String code) async {
    await _codesRef.doc(code).delete().catchError((_) {});
  }

  /// Redeem [code] on behalf of [viewerUid]: look up the owner, then create
  /// the partnerships doc that unlocks cross-user reads via the security
  /// rules. Returns the resolved invite.
  Future<PartnerInvite> linkPartner({
    required String code,
    required String viewerUid,
    String? viewerDisplayName,
  }) async {
    final invite = await lookupCode(code);
    if (invite.partnerUid == viewerUid) {
      throw Exception('That\'s your own code.');
    }
    final id = partnershipId(
      viewerUid: viewerUid,
      ownerUid: invite.partnerUid,
    );
    await _partnershipsRef.doc(id).set({
      'viewerUid': viewerUid,
      'ownerUid': invite.partnerUid,
      'viewerDisplayName': viewerDisplayName,
      'ownerDisplayName': invite.partnerDisplayName,
      'createdAt': Timestamp.now(),
    });
    return invite;
  }

  /// Tear down the partnership doc when a viewer disconnects.
  Future<void> unlinkPartner({
    required String viewerUid,
    required String ownerUid,
  }) async {
    final id = partnershipId(viewerUid: viewerUid, ownerUid: ownerUid);
    await _partnershipsRef.doc(id).delete().catchError((_) {});
  }

  /// Self-heal: idempotently make sure a partnerships doc exists for the
  /// (viewer, owner) pair. Used to repair links created before linkPartner()
  /// existed — those old links carry the partner uid in the profile but no
  /// matching partnerships doc, so security rules block every read.
  ///
  /// Throws if the write itself is rejected (in which case the user almost
  /// certainly needs to publish the new Firestore rules in the console).
  Future<void> ensurePartnership({
    required String viewerUid,
    required String ownerUid,
  }) async {
    if (viewerUid == ownerUid) {
      throw Exception('Cannot create a partnership with yourself.');
    }
    final id = partnershipId(viewerUid: viewerUid, ownerUid: ownerUid);
    final ref = _partnershipsRef.doc(id);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'viewerUid': viewerUid,
      'ownerUid': ownerUid,
      'createdAt': Timestamp.now(),
      'repaired': true,
    });
  }
}

class PartnerInvite {
  final String code;
  final String partnerUid;
  final String? partnerDisplayName;

  const PartnerInvite({
    required this.code,
    required this.partnerUid,
    this.partnerDisplayName,
  });
}
