import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:flutter/foundation.dart';
import 'package:civic_contribution/core/supabase_config.dart';
import 'package:civic_contribution/domain/models/auth_user.dart';

/// Handles all authentication I/O: Google sign-in, sign-out, auth state stream.
/// Single responsibility: auth only — no database, no storage.
class AuthService {
  SupabaseClient get _client => SupabaseConfig.client;

  /// Stream of the currently signed-in user. Emits null when signed out.
  Stream<AuthUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return _toAuthUser(user);
    });
  }

  /// The currently signed-in user, or null.
  AuthUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _toAuthUser(user);
  }

  /// Signs in with Google via Supabase OAuth.
  /// Opens the system browser; the session arrives via the deep-link callback
  /// and is emitted on [authStateChanges] — do NOT expect currentUser to be
  /// set immediately after this returns.
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Google sign-in could not be started. Please verify Supabase OAuth settings. Error: $e',
      );
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Signs out the user (full account deletion requires a server-side RPC).
  Future<void> deleteAccount() async {
    await _client.auth.signOut();
  }

  AuthUser? _toAuthUser(User user) {
    return AuthUser(
      uid: user.id,
      displayName: user.userMetadata?['full_name'] as String? ??
          user.email ??
          'User',
      email: user.email,
      photoUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }
}
