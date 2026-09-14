import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/local_user.dart';
import 'local_store.dart';

/// Fully local accounts. Username + password never leave this device.
class AuthService {
  AuthService();

  static const _uuid = Uuid();
  final _store = LocalStore.instance;
  final _authCtrl = StreamController<LocalUser?>.broadcast(sync: true);

  LocalUser? _current;
  Completer<void>? _ready;

  LocalUser? get currentUser => _current;

  Stream<LocalUser?> get authStateChanges => _authCtrl.stream;

  Future<void> restoreSession() async {
    if (_ready != null) return _ready!.future;
    _ready = Completer<void>();
    try {
      await _store.ready();
      final uid = await _store.getString(AppConstants.storeSession);
      if (uid != null && uid.isNotEmpty) {
        final accounts = await _accounts();
        for (final a in accounts) {
          if (a['uid'] == uid) {
            _current = LocalUser.fromMap(a);
            break;
          }
        }
      }
    } finally {
      if (!_ready!.isCompleted) _ready!.complete();
    }
  }

  Future<List<Map<String, dynamic>>> _accounts() =>
      _store.getJsonList(AppConstants.storeAccounts);

  Future<void> _saveAccounts(List<Map<String, dynamic>> list) =>
      _store.setJsonList(AppConstants.storeAccounts, list);

  Future<LocalUser?> signInWithEmailOrUsername(
      String identifier, String password) async {
    final id = identifier.trim().toLowerCase();
    if (id.isEmpty) {
      throw const AuthException('invalid', 'Enter your username.');
    }
    final accounts = await _accounts();
    Map<String, dynamic>? found;
    for (final a in accounts) {
      final username = (a['username'] as String? ?? '').toLowerCase();
      final email = (a['email'] as String? ?? '').toLowerCase();
      if (username == id || (email.isNotEmpty && email == id)) {
        found = a;
        break;
      }
    }
    if (found == null) {
      throw const AuthException(
          'user-not-found', 'No profile on this device matches that name.');
    }
    final hash = found['passwordHash'] as String? ?? '';
    final salt = found['salt'] as String? ?? '';
    if (hash != _hash(password, salt)) {
      throw const AuthException(
          'wrong-password', 'That password is incorrect.');
    }
    _current = LocalUser.fromMap(found);
    await _store.setString(AppConstants.storeSession, _current!.uid);
    _authCtrl.add(_current);
    return _current;
  }

  Future<LocalUser?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? username,
  }) async {
    final uname = (username ?? displayName ?? '').trim();
    if (uname.length < 3) {
      throw const AuthException(
          'invalid', 'Pick a name with at least 3 letters.');
    }
    if (password.length < 4) {
      throw const AuthException('weak-password', 'Use at least 4 characters.');
    }
    final accounts = [...await _accounts()];
    final key = _normalizeName(uname);
    final emailKey = email.trim().toLowerCase();
    Map<String, dynamic>? existing;
    for (final a in accounts) {
      final existingName = _normalizeName(a['username'] as String? ?? '');
      final existingEmail = (a['email'] as String? ?? '').toLowerCase();
      if (existingName == key) {
        existing = a;
        break;
      }
      if (emailKey.contains('@') && existingEmail == emailKey) {
        existing = a;
        break;
      }
    }
    if (existing != null) {
      final salt = existing['salt'] as String? ?? '';
      if (_hash(password, salt) ==
          (existing['passwordHash'] as String? ?? '')) {
        _current = LocalUser.fromMap(existing);
        await _store.setString(AppConstants.storeSession, _current!.uid);
        _authCtrl.add(_current);
        return _current;
      }
      throw const AuthException(
        'name-taken',
        'That name is already on this phone. Unlock the existing profile, or pick a different name.',
      );
    }
    final salt = _randomSalt();
    final uid = _uuid.v4();
    final storedEmail =
        emailKey.contains('@') ? email.trim() : '$key@cyclus.local';
    final record = <String, dynamic>{
      'uid': uid,
      'username': uname,
      'email': storedEmail,
      'displayName':
          displayName?.trim().isNotEmpty == true ? displayName!.trim() : uname,
      'passwordHash': _hash(password, salt),
      'salt': salt,
    };
    accounts.add(record);
    await _saveAccounts(accounts);
    _current = LocalUser.fromMap(record);
    await _store.setString(AppConstants.storeSession, uid);
    _authCtrl.add(_current);
    return _current;
  }

  Future<void> signOut() async {
    _current = null;
    await _store.remove(AppConstants.storeSession);
    _authCtrl.add(null);
  }

  Future<void> deleteCurrentUser() async {
    final user = _current;
    if (user == null) return;
    final accounts = [...await _accounts()];
    accounts.removeWhere((a) => a['uid'] == user.uid);
    await _saveAccounts(accounts);
    await signOut();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _current;
    if (user == null) {
      throw const AuthException('signed-out', 'Sign in first.');
    }
    if (newPassword.length < 4) {
      throw const AuthException('weak-password', 'Use at least 4 characters.');
    }
    final accounts = await _accounts();
    final idx = accounts.indexWhere((a) => a['uid'] == user.uid);
    if (idx < 0) {
      throw const AuthException('user-not-found', 'Profile missing.');
    }
    final salt = accounts[idx]['salt'] as String? ?? '';
    if (_hash(currentPassword, salt) != accounts[idx]['passwordHash']) {
      throw const AuthException('wrong-password', 'Current password is wrong.');
    }
    final nextSalt = _randomSalt();
    accounts[idx]['salt'] = nextSalt;
    accounts[idx]['passwordHash'] = _hash(newPassword, nextSalt);
    await _saveAccounts(accounts);
  }

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt::$password')).toString();
  }

  String _normalizeName(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  String _randomSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
