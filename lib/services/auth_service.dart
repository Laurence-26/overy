import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around FirebaseAuth + Google sign-in.
///
/// FirebaseAuth.instance is resolved lazily so that constructing this service
/// does not crash on platforms where Firebase wasn't initialized (e.g. web
/// without web config). Errors then surface inside AuthProvider's try/catch
/// instead of taking down the whole widget tree.
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _explicitAuth = auth,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth? _explicitAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuth get _auth => _explicitAuth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user;
  }

  /// Accepts either an email (contains '@') or a username. If a username is
  /// passed, looks up the matching email in the top-level `usernames/{lower}`
  /// document and then signs in with that email.
  Future<User?> signInWithEmailOrUsername(
      String identifier, String password) async {
    final id = identifier.trim();
    if (id.contains('@')) {
      return signInWithEmail(id, password);
    }
    final snap = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(id.toLowerCase())
        .get();
    final email = snap.data()?['email'] as String?;
    if (email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account found for that username.',
      );
    }
    return signInWithEmail(email, password);
  }

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
    }
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user canceled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return cred.user;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Deletes the current Firebase Auth user. Throws
  /// FirebaseAuthException(code: 'requires-recent-login') if the user signed
  /// in too long ago — caller should prompt them to re-authenticate.
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
    // Also sign out of Google so no stale session remains.
    await _googleSignIn.signOut().catchError((_) => null);
  }
}
