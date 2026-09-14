import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/local_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

enum DeleteAccountResult { success, requiresReauth, failed }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth) {
    _boot();
  }

  final AuthService _auth;
  StreamSubscription<LocalUser?>? _sub;

  AuthStatus _status = AuthStatus.unknown;
  LocalUser? _user;
  String? _error;
  bool _busy = false;
  bool _partnerIntent = false;

  AuthStatus get status => _status;
  LocalUser? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  /// True when the current sign-in/up was opened via "Unlock as a partner".
  bool get partnerIntent => _partnerIntent;

  Future<void> _boot() async {
    try {
      await _auth.restoreSession();
      _setSession(_auth.currentUser);
      notifyListeners();
      _sub = _auth.authStateChanges.listen((u) {
        // Never let a stale null event wipe a live session.
        final next = u ?? _auth.currentUser;
        if (next == null && _auth.currentUser != null) return;
        _setSession(next);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Auth boot failed: $e');
      _status = AuthStatus.signedOut;
      notifyListeners();
    }
  }

  void _setSession(LocalUser? u) {
    _user = u;
    _status = u == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    if (u == null) _partnerIntent = false;
  }

  Future<bool> signIn(
    String emailOrUsername,
    String password, {
    bool asPartner = false,
  }) async {
    _partnerIntent = asPartner;
    return _run(
        () => _auth.signInWithEmailOrUsername(emailOrUsername, password));
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
    String? username,
    bool asPartner = false,
  }) {
    _partnerIntent = asPartner;
    return _run(() => _auth.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
          username: username,
        ));
  }

  Future<void> signOut() async {
    _partnerIntent = false;
    await _auth.signOut();
    _setSession(null);
    notifyListeners();
  }

  Future<DeleteAccountResult> deleteLocalUser() async {
    try {
      await _auth.deleteCurrentUser();
      _partnerIntent = false;
      _setSession(null);
      notifyListeners();
      return DeleteAccountResult.success;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return DeleteAccountResult.failed;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return DeleteAccountResult.failed;
    }
  }

  /// Kept so existing screens compile; local accounts never need re-auth.
  Future<DeleteAccountResult> deleteFirebaseUser() => deleteLocalUser();

  Future<bool> _run(Future<LocalUser?> Function() op) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final u = await op();
      _setSession(u ?? _auth.currentUser);
      _busy = false;
      notifyListeners();
      return _user != null;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }
    _busy = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
