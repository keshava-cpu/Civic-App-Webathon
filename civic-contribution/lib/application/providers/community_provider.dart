import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/models/community.dart';
import 'package:civic_contribution/data/services/community_service.dart';
import 'package:civic_contribution/data/services/database_service.dart';

/// Single responsibility: community search, selection, and admin grant state.
class CommunityProvider extends ChangeNotifier {
  final CommunityService _communityService;
  final DatabaseService _firestoreService;

  List<Community> _searchResults = [];
  Community? _selectedCommunity;
  bool _loading = false;
  String? _error;

  CommunityProvider(this._communityService, this._firestoreService);

  List<Community> get searchResults => _searchResults;
  Community? get selectedCommunity => _selectedCommunity;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> searchCommunities(String query) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _searchResults = await _communityService.searchCommunities(query);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  /// Joins the community and updates the user's communityId.
  Future<void> selectCommunity(Community community, String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _communityService.joinCommunity(community.id);
      await _firestoreService.updateUserCommunity(userId, community.id);
      _selectedCommunity = community;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  /// Creates a new community, joins it, and returns it.
  Future<Community?> createCommunity(String name, String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final id = await _communityService.createCommunity(name, userId);
      await _firestoreService.updateUserCommunity(userId, id);
      final community = Community(
        id: id,
        name: name,
        createdBy: userId,
        adminUids: [],
        memberCount: 1,
      );
      _selectedCommunity = community;
      _loading = false;
      notifyListeners();
      return community;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  /// Adds userId to community's adminUids array.
  Future<void> grantAdmin(String communityId, String userId) async {
    await _communityService.addAdminToCommunity(communityId, userId);
    notifyListeners();
  }
}
