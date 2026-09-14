/// On-device account. Nothing is sent anywhere.
class LocalUser {
  final String uid;
  final String username;
  final String email;
  final String? displayName;

  const LocalUser({
    required this.uid,
    required this.username,
    required this.email,
    this.displayName,
  });

  Map<String, dynamic> toPublicMap() => {
        'uid': uid,
        'username': username,
        'email': email,
        'displayName': displayName,
      };

  factory LocalUser.fromMap(Map<String, dynamic> m) => LocalUser(
        uid: m['uid'] as String,
        username: m['username'] as String? ?? '',
        email: m['email'] as String? ?? '',
        displayName: m['displayName'] as String?,
      );
}

class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}
