import 'dart:async';
import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/models/user_profile.dart';
import 'package:civic_contribution/data/services/firestore_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  StreamSubscription? _subscription;

  List<UserProfile> _users = [];
  bool _loading = true;

  LeaderboardProvider(this._firestoreService) {
    _subscription = _firestoreService.getLeaderboardStream().listen((users) {
      _users = users.where((u) => !u.isAdmin).toList();
      _loading = false;
      notifyListeners();
    });
  }

  /// Re-subscribe to a community-scoped or global leaderboard stream.
  void reinitialize(String? communityId) {
    _subscription?.cancel();
    _loading = true;
    notifyListeners();
    final stream = communityId != null
        ? _firestoreService.getLeaderboardByCommunityStream(communityId)
        : _firestoreService.getLeaderboardStream();
    _subscription = stream.listen((users) {
      _users = users.where((u) => !u.isAdmin).toList();
      _loading = false;
      notifyListeners();
    });
  }

  List<UserProfile> get users => _users;
  bool get loading => _loading;
}

