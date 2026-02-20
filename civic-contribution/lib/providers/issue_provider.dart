import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/issue.dart';
import '../services/firestore_service.dart';

class IssueProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<Issue> _allIssues = [];
  IssueStatus? _statusFilter;
  IssueCategory? _categoryFilter;
  bool _loading = true;

  IssueProvider(this._firestoreService) {
    _firestoreService.getIssuesStream().listen((issues) {
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
    }
    if (_categoryFilter != null) {
      list = list.where((i) => i.category == _categoryFilter).toList();
    }

    list.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return list;
  }

  List<Issue> get allIssues => _allIssues;

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
}
