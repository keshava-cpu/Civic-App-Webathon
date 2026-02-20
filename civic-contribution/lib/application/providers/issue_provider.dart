import 'dart:async';
import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/data/services/credits_service.dart';
import 'package:civic_contribution/data/services/firestore_service.dart';

/// Manages the list of issues and filter state.
/// Single responsibility: issue list state + filter logic.
class IssueProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final CreditsService _creditsService;
  StreamSubscription? _subscription;

  List<Issue> _allIssues = [];
  IssueStatus? _statusFilter;
  IssueCategory? _categoryFilter;
  bool _loading = true;

  IssueProvider(this._firestoreService, this._creditsService) {
    _subscription = _firestoreService.getIssuesStream().listen((issues) {
      _allIssues = issues;
      _loading = false;
      notifyListeners();
    });
  }

  /// Re-subscribe to a community-scoped or global issue stream.
  void reinitialize(String? communityId) {
    _subscription?.cancel();
    _loading = true;
    notifyListeners();
    final stream = communityId != null
        ? _firestoreService.getIssuesByCommunityStream(communityId)
        : _firestoreService.getIssuesStream();
    _subscription = stream.listen((issues) {
      _allIssues = issues;
      _loading = false;
      notifyListeners();
    });
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
}
