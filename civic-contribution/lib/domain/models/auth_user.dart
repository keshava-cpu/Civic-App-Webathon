/// Immutable value object representing an authenticated user.
/// No Flutter or Firebase imports — pure domain data.
class AuthUser {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;

  const AuthUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
  });
}
