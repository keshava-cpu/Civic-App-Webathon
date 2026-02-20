import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:civic_contribution/domain/models/auth_user.dart';

/// Handles all authentication I/O: Google sign-in, sign-out, auth state stream.
/// Single responsibility: auth only — no Firestore, no storage.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of the currently signed-in user. Emits null when signed out.
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_toAuthUser);
  }

  /// The currently signed-in user, or null.
  AuthUser? get currentUser => _toAuthUser(_firebaseAuth.currentUser);

  /// Signs in with Google. Returns the signed-in [AuthUser], or null on failure.
  Future<AuthUser?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _firebaseAuth.signInWithCredential(credential);
    return _toAuthUser(result.user);
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  AuthUser? _toAuthUser(User? firebaseUser) {
    if (firebaseUser == null) return null;
    return AuthUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
    );
  }
}
