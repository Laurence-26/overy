import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

enum DeleteAccountResult { success, requiresReauth, failed }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth) {
    try {
      _sub = _auth.authStateChanges.listen((u) {
        _user = u;
        _status = u == null ? AuthStatus.signedOut : AuthStatus.signedIn;
        notifyListeners();
      });
    } catch (e) {
      // Firebase isn't initialized (e.g. placeholder config) — surface as
      // signed-out so the app can still render its UI.
      debugPrint('Auth stream unavailable: $e');
      _status = AuthStatus.signedOut;
    }
  }

  final AuthService _auth;
  StreamSubscription<User?>? _sub;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  /// Accepts either email or username.
  Future<bool> signIn(String emailOrUsername, String password) async {
    return _run(() =>
        _auth.signInWithEmailOrUsername(emailOrUsername, password));
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _run(() => _auth.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        ));
  }

  Future<bool> signInWithGoogle() => _run(() => _auth.signInWithGoogle());

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete the Firebase Auth user. Returns
  /// `DeleteAccountResult.requiresReauth` if Firebase rejects because the
  /// session is too old — caller must prompt for re-auth before retrying.
  Future<DeleteAccountResult> deleteFirebaseUser() async {
    try {
      await _auth.deleteCurrentUser();
      return DeleteAccountResult.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return DeleteAccountResult.requiresReauth;
      }
      _error = e.message ?? 'Could not delete account';
      notifyListeners();
      return DeleteAccountResult.failed;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return DeleteAccountResult.failed;
    }
  }

  Future<bool> _run(Future<User?> Function() op) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final u = await op();
      _busy = false;
      notifyListeners();
      return u != null;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Authentication failed';
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
