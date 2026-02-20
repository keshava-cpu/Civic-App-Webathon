import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/mock_auth_service.dart';

class UserProvider extends ChangeNotifier {
  final MockAuthService _authService;
  final FirestoreService _firestoreService;

  UserProfile? _currentUserProfile;
  bool _loading = false;

  UserProvider(this._authService, this._firestoreService) {
    _loadCurrentUser();
  }

  UserProfile? get currentUserProfile => _currentUserProfile;
  bool get loading => _loading;
  String get currentUserId => _authService.currentUserId;
  MockUser get currentMockUser => _authService.currentUser;
  List<MockUser> get allUsers => MockAuthService.mockUsers;

  Future<void> _loadCurrentUser() async {
    _loading = true;
    notifyListeners();

    final userId = _authService.currentUserId;
    var profile = await _firestoreService.getUser(userId);

    if (profile == null) {
      // Create profile from mock user
      final mockUser = _authService.currentUser;
      profile = UserProfile(
        id: mockUser.id,
        displayName: mockUser.displayName,
        avatarUrl: mockUser.avatarUrl,
        trustScore: mockUser.trustScore,
        civicCredits: 0,
        badges: [],
        issuesReported: 0,
        verificationsCompleted: 0,
        tasksCompleted: 0,
      );
      await _firestoreService.upsertUser(profile);
    }

    _currentUserProfile = profile;
    _loading = false;
    notifyListeners();
  }

  Future<void> switchUser(String userId) async {
    _authService.switchUser(userId);
    await _loadCurrentUser();
  }

  Future<void> refreshCurrentUser() async {
    _loading = true;
    notifyListeners();
    final profile = await _firestoreService.getUser(_authService.currentUserId);
    _currentUserProfile = profile ?? _currentUserProfile;
    _loading = false;
    notifyListeners();
  }
}
