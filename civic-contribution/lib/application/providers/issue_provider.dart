import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/data/services/credits_service.dart';
import 'package:civic_contribution/data/services/database_service.dart';

/// Manages the list of issues and filter state.
/// Single responsibility: issue list state + filter logic.
class IssueProvider extends ChangeNotifier {
  final DatabaseService _firestoreService;
  final CreditsService _creditsService;
  StreamSubscription? _subscription;

  List<Issue> _allIssues = [];
  IssueStatus? _statusFilter;
  IssueCategory? _categoryFilter;
  bool _loading = true;
  String? _currentCommunityId;

  IssueProvider(this._firestoreService, this._creditsService) {
    _initializeStream(null);
  }

  /// Initialize or reinitialize the issue stream.
  /// Automatically unsubscribes from old stream and subscribes to new one.
  void _initializeStream(String? communityId) {
    debugPrint('[IssueProvider] Initializing stream for community: $communityId');
    
    // Cancel old subscription
    _subscription?.cancel();
    _subscription = null;
    
    // Set loading state
    _loading = true;
    _currentCommunityId = communityId;
    notifyListeners();

    // Subscribe to appropriate stream
    final stream = communityId != null
        ? _firestoreService.getIssuesByCommunityStream(communityId)
        : _firestoreService.getIssuesStream();

    _subscription = stream.listen(
      (issues) {
        debugPrint('[IssueProvider] Received ${issues.length} issues');
        _allIssues = issues;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[IssueProvider] Stream error: $e');
        _loading = false;
        notifyListeners();
        // Don't rethrow — allow UI to show empty state
      },
      onDone: () {
        debugPrint('[IssueProvider] Stream closed');
      },
    );
  }

  /// Re-subscribe to a community-scoped or global issue stream.
  /// Call this when the user's community selection changes.
  void reinitialize(String? communityId) {
    if (_currentCommunityId == communityId) {
      debugPrint('[IssueProvider] Already subscribed to community: $communityId');
      return;
    }
    _initializeStream(communityId);
  }

  bool get loading => _loading;
  IssueStatus? get statusFilter => _statusFilter;
  IssueCategory? get categoryFilter => _categoryFilter;

  List<Issue> get filteredIssues {
    var list = List<Issue>.from(_allIssues);
    if (_statusFilter != null) {
      list = list.where((i) => i.status == _statusFilter).toList();
    } else {
      // F3: Default — show only active issues (hide verified/resolved)
      list = list
          .where((i) =>
              i.status != IssueStatus.verified &&
              i.status != IssueStatus.resolved)
          .toList();
    }
    if (_categoryFilter != null) {
      list = list.where((i) => i.category == _categoryFilter).toList();
    }
    list.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return list;
  }

  List<Issue> get allIssues => _allIssues;

  /// The most recently created issue (stream already sorted by createdAt desc).
  Issue? get latestReportedIssue =>
      _allIssues.isNotEmpty ? _allIssues.first : null;

  void setStatusFilter(IssueStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(IssueCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  /// Upvotes an issue and awards credits. Prevents double-upvoting.
  Future<void> upvoteIssue(String issueId, String userId) async {
    await _firestoreService.upvoteIssue(issueId, userId);
    await _creditsService.awardUpvote(userId);
  }

  @override
  void dispose() {
    debugPrint('[IssueProvider] Disposing (cancelling stream)');
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
