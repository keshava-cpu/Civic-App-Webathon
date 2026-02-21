import 'package:flutter/material.dart';
import 'package:civic_contribution/data/services/auth_service.dart';
import 'package:civic_contribution/data/services/community_service.dart';
import 'package:civic_contribution/data/services/database_service.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';

/// Single responsibility: orchestrates community leave/switch,
/// community deletion, and account deletion.
class AccountManagementProvider extends ChangeNotifier {
  final CommunityService _communityService;
  final DatabaseService _firestoreService;
  final AuthService _authService;
  final UserProvider _userProvider;

  bool _loading = false;
  String? _error;

  AccountManagementProvider(
    this._communityService,
    this._firestoreService,
    this._authService,
    this._userProvider,
  );

  bool get loading => _loading;
  String? get error => _error;

  /// Leaves the current community.
  /// After this, communityId becomes null and the router redirects to
  /// community-select automatically.
  Future<bool> leaveCommunity() async {
    final uid = _userProvider.currentUserId;
    final communityId = _userProvider.communityId;
    if (uid.isEmpty || communityId == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _communityService.leaveCommunity(communityId, uid);
      await _firestoreService.clearUserCommunity(uid);
      await _userProvider.refreshCurrentUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes the entire community and resets all its members.
  /// Only callable by an admin of the community.
  Future<bool> deleteCommunity() async {
    final uid = _userProvider.currentUserId;
    final communityId = _userProvider.communityId;
    if (uid.isEmpty || communityId == null) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Reset all users in this community first.
      await _firestoreService.resetCommunityUsers(communityId);
      // Then delete the community doc.
      await _communityService.deleteCommunity(communityId);
      // Refresh to pick up null communityId.
      await _userProvider.refreshCurrentUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Permanently deletes the user's account.
  /// Leaves the community first, then deletes Firestore doc, then Firebase Auth.
  Future<bool> deleteAccount() async {
    final uid = _userProvider.currentUserId;
    if (uid.isEmpty) return false;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Leave community if in one.
      final communityId = _userProvider.communityId;
      if (communityId != null) {
        await _communityService.leaveCommunity(communityId, uid);
      }
      // Delete Firestore profile.
      await _firestoreService.deleteUser(uid);
      // Delete Firebase Auth account (signs user out automatically).
      await _authService.deleteAccount();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
