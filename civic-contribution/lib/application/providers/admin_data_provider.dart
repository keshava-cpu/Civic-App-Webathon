import 'dart:async';

import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/data/services/firestore_service.dart';
import 'package:civic_contribution/data/services/export_service.dart';

/// Single responsibility: admin data table state + CSV export trigger.
class AdminDataProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final ExportService _exportService;
  StreamSubscription<List<Issue>>? _subscription;

  List<Issue> _issues = [];
  bool _loading = false;
  bool _exporting = false;
  String? _exportError;

  AdminDataProvider(this._firestoreService, this._exportService);

  List<Issue> get issues => _issues;
  bool get loading => _loading;
  bool get exporting => _exporting;
  String? get exportError => _exportError;

  void subscribeToIssues(String communityId) {
    _subscription?.cancel();
    _loading = true;
    notifyListeners();

    _subscription =
        _firestoreService.getIssuesByCommunityStream(communityId).listen(
      (issues) {
        _issues = issues;
        _loading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _exportError = error.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> exportCsv() async {
    if (_issues.isEmpty) return;
    _exporting = true;
    _exportError = null;
    notifyListeners();
    try {
      final csv = _exportService.generateCsv(_issues);
      final filename =
          'civic_issues_${DateTime.now().millisecondsSinceEpoch}.csv';
      await _exportService.saveAndShare(csv, filename);
    } catch (e) {
      _exportError = e.toString();
    }
    _exporting = false;
    notifyListeners();
  }

  Future<void> exportWithImages() async {
    if (_issues.isEmpty) return;
    _exporting = true;
    _exportError = null;
    notifyListeners();
    try {
      await _exportService.exportWithImages(_issues);
    } catch (e) {
      _exportError = e.toString();
    }
    _exporting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
