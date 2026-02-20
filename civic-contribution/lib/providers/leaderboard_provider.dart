import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<UserProfile> _users = [];
  bool _loading = true;

  LeaderboardProvider(this._firestoreService) {
    _firestoreService.getLeaderboardStream().listen((users) {
      _users = users;
      _loading = false;
      notifyListeners();
    });
  }

  List<UserProfile> get users => _users;
  bool get loading => _loading;
}
