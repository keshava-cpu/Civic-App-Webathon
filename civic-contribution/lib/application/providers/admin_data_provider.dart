import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/data/services/database_service.dart';
import 'package:civic_contribution/data/services/export_service.dart';

/// Single responsibility: admin data table state + CSV export trigger.
class AdminDataProvider extends ChangeNotifier {
  final DatabaseService _firestoreService;
  final ExportService _exportService;
  StreamSubscription<List<Issue>>? _subscription;

  List<Issue> _issues = [];
  bool _loading = false;
  bool _exporting = false;
  String? _exportError;
  String? _currentCommunityId;

  AdminDataProvider(this._firestoreService, this._exportService);

  List<Issue> get issues => _issues;
  bool get loading => _loading;
  bool get exporting => _exporting;
  String? get exportError => _exportError;

  void subscribeToIssues(String communityId) {
    if (_currentCommunityId == communityId && _subscription != null) {
      debugPrint('[AdminDataProvider] Already subscribed to community: $communityId');
      return;
    }
    
    debugPrint('[AdminDataProvider] Subscribing to community: $communityId');
    _subscription?.cancel();
    _loading = true;
    _currentCommunityId = communityId;
    notifyListeners();

    _subscription =
        _firestoreService.getIssuesByCommunityStream(communityId).listen(
      (issues) {
        debugPrint('[AdminDataProvider] Received ${issues.length} issues');
        _issues = issues;
        _loading = false;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('[AdminDataProvider] Stream error: $error');
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
