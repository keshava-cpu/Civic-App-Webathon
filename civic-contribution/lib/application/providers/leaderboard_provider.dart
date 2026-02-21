import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:civic_contribution/domain/models/user_profile.dart';
import 'package:civic_contribution/data/services/database_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final DatabaseService _firestoreService;
  StreamSubscription? _subscription;

  List<UserProfile> _users = [];
  bool _loading = true;
  String? _currentCommunityId;

  LeaderboardProvider(this._firestoreService) {
    _initializeStream(null);
  }

  /// Initialize or reinitialize the leaderboard stream.
  void _initializeStream(String? communityId) {
    debugPrint('[LeaderboardProvider] Initializing stream for community: $communityId');
    
    _subscription?.cancel();
    _subscription = null;
    _loading = true;
    _currentCommunityId = communityId;
    notifyListeners();

    final stream = communityId != null
        ? _firestoreService.getLeaderboardByCommunityStream(communityId)
        : _firestoreService.getLeaderboardStream();
    
    _subscription = stream.listen(
      (users) {
        final nonAdmins = users.where((u) => !u.isAdmin).toList();
        debugPrint('[LeaderboardProvider] Received ${nonAdmins.length} users (${users.length} total, filtered admins)');
        _users = nonAdmins;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[LeaderboardProvider] Stream error: $e');
        _loading = false;
        notifyListeners();
      },
      onDone: () {
        debugPrint('[LeaderboardProvider] Stream closed');
      },
    );
  }

  /// Re-subscribe to a community-scoped or global leaderboard stream.
  void reinitialize(String? communityId) {
    if (_currentCommunityId == communityId) {
      debugPrint('[LeaderboardProvider] Already subscribed to community: $communityId');
      return;
    }
    _initializeStream(communityId);
  }

  List<UserProfile> get users => _users;
  bool get loading => _loading;

  @override
  void dispose() {
    debugPrint('[LeaderboardProvider] Disposing (cancelling stream)');
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

