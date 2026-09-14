import 'dart:math';

import '../core/constants.dart';
import '../core/json_dates.dart';
import 'local_store.dart';

/// Same-device partner invites. A 6-digit PIN lives on this phone for 24 hours
/// so a partner profile on the same device can follow her cycle - no cloud.
class PartnerService {
  PartnerService();

  final _store = LocalStore.instance;
  static const Duration codeTtl = Duration(hours: 24);

  /// Deterministic partnership id (kept for compatibility with older screens).
  static String partnershipId({
    required String viewerUid,
    required String ownerUid,
  }) =>
      '${viewerUid}_$ownerUid';

  Future<Map<String, dynamic>> _codes() async =>
      await _store.getJson(AppConstants.storeShareCodes) ?? <String, dynamic>{};

  Future<void> _saveCodes(Map<String, dynamic> codes) =>
      _store.setJson(AppConstants.storeShareCodes, codes);

  Future<String> generateInviteCode({
    required String uid,
    String? displayName,
  }) async {
    final codes = await _codes();
    for (final entry in codes.entries.toList()) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      if (data['uid'] == uid) {
        final expiresAt = JsonDates.decode(data['expiresAt']);
        if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
          return entry.key;
        }
        codes.remove(entry.key);
      }
    }

    final rng = Random.secure();
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = (rng.nextInt(900000) + 100000).toString();
      if (codes.containsKey(code)) continue;
      final now = DateTime.now();
      codes[code] = {
        'uid': uid,
        'displayName': displayName,
        'createdAt': JsonDates.encode(now),
        'expiresAt': JsonDates.encode(now.add(codeTtl)),
      };
      await _saveCodes(codes);
      return code;
    }
    throw Exception('Could not generate a unique invite code. Try again.');
  }

  Future<PartnerInvite> lookupCode(String code) async {
    final cleaned = code.trim();
    final codes = await _codes();
    final raw = codes[cleaned];
    if (raw is! Map) {
      throw Exception(
          'That code doesn\'t match any active invite on this device.');
    }
    final data = Map<String, dynamic>.from(raw);
    final expiresAt = JsonDates.decode(data['expiresAt']);
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw Exception('That code has expired. Ask her for a new one.');
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

  Future<void> revokeInviteCode(String code) async {
    final codes = await _codes();
    codes.remove(code);
    await _saveCodes(codes);
  }

  Future<PartnerInvite> linkPartner({
    required String code,
    required String viewerUid,
    String? viewerDisplayName,
  }) async {
    final invite = await lookupCode(code);
    if (invite.partnerUid == viewerUid) {
      throw Exception('That\'s your own code.');
    }
    return invite;
  }

  Future<void> unlinkPartner({
    required String viewerUid,
    required String ownerUid,
  }) async {
    // Partnership is stored on the viewer's profile (linkedPartnerUids).
  }

  Future<void> ensurePartnership({
    required String viewerUid,
    required String ownerUid,
  }) async {
    if (viewerUid == ownerUid) {
      throw Exception('Cannot create a partnership with yourself.');
    }
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
