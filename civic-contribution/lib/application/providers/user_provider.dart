import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/models/auth_user.dart';
import 'package:civic_contribution/domain/models/user_profile.dart';
import 'package:civic_contribution/data/services/auth_service.dart';
import 'package:civic_contribution/data/services/firestore_service.dart';

/// Manages auth state and the current user's Firestore profile.
/// Single responsibility: bridges AuthService + FirestoreService into app state.
class UserProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthUser? _authUser;
  UserProfile? _currentUserProfile;
  bool _loading = false;

  UserProvider(this._authService, this._firestoreService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  AuthUser? get authUser => _authUser;
  UserProfile? get currentUserProfile => _currentUserProfile;
  bool get loading => _loading;
  bool get isSignedIn => _authUser != null;
  String get currentUserId => _authUser?.uid ?? '';
  bool get isAdmin => _currentUserProfile?.isAdmin ?? false;
  String? get communityId => _currentUserProfile?.communityId;

  Future<void> _onAuthStateChanged(AuthUser? user) async {
    _authUser = user;
    if (user == null) {
      _currentUserProfile = null;
      notifyListeners();
      return;
    }
    await _loadOrCreateProfile(user);
  }

  Future<void> _loadOrCreateProfile(AuthUser user) async {
    _loading = true;
    notifyListeners();

    var profile = await _firestoreService.getUser(user.uid);
    if (profile == null) {
      profile = UserProfile(
        id: user.uid,
        displayName: user.displayName,
        avatarUrl: user.photoUrl,
        trustScore: 0.5,
        civicCredits: 0,
        badges: [],
        issuesReported: 0,
        verificationsCompleted: 0,
        tasksCompleted: 0,
        isAdmin: false,
      );
      await _firestoreService.upsertUser(profile);
    }

    _currentUserProfile = profile;
    _loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> refreshCurrentUser() async {
    final uid = _authUser?.uid;
    if (uid == null) return;
    _loading = true;
    notifyListeners();
    final profile = await _firestoreService.getUser(uid);
    _currentUserProfile = profile ?? _currentUserProfile;
    _loading = false;
    notifyListeners();
  }

  Future<void> setAdminFlag() async {
    final uid = _authUser?.uid;
    if (uid == null) return;
    await _firestoreService.setUserAsAdmin(uid);
    await refreshCurrentUser();
  }

  Future<void> setCommunity(String communityId) async {
    final uid = _authUser?.uid;
    if (uid == null) return;
    await _firestoreService.updateUserCommunity(uid, communityId);
    await refreshCurrentUser();
  }
}
