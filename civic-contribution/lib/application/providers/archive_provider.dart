import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/data/services/archive_service.dart';
import 'package:civic_contribution/data/services/archive_storage_service.dart';
import 'package:civic_contribution/data/services/firestore_service.dart';

/// Single responsibility: orchestrates archive creation with progress tracking.
class ArchiveProvider extends ChangeNotifier {
  final ArchiveService _archiveService;
  final ArchiveStorageService _archiveStorageService;
  final FirestoreService _firestoreService;

  ArchiveProvider(
    this._archiveService,
    this._archiveStorageService,
    this._firestoreService,
  );

  bool _isArchiving = false;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _error;

  bool get isArchiving => _isArchiving;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String? get error => _error;

  /// Creates a ZIP archive of unresolved issues for [communityId],
  /// then opens the system share sheet.
  ///
  /// Set [unresolvedOnly] to false to include all issues.
  Future<void> createAndShareArchive(
    String communityId, {
    bool unresolvedOnly = true,
  }) async {
    if (_isArchiving) return;

    _isArchiving = true;
    _progress = 0.0;
    _error = null;
    _statusMessage = 'Fetching issues…';
    notifyListeners();

    try {
      // 1. Fetch issues (one-time read from the appropriate stream).
      final issues = await _fetchIssues(communityId, unresolvedOnly);

      if (issues.isEmpty) {
        _statusMessage = 'No issues to archive';
        _isArchiving = false;
        notifyListeners();
        return;
      }

      // 2. Collect photo URLs.
      final photoUrls = <String, String>{};
      for (final issue in issues) {
        if (issue.photoUrl != null) {
          photoUrls[issue.id] = issue.photoUrl!;
        }
      }

      // 3. Download images.
      _statusMessage = 'Downloading images…';
      _progress = 0.1;
      notifyListeners();

      final imageBytes = await _archiveStorageService.downloadImages(
        photoUrls,
        onProgress: (completed, total) {
          // Images take 10%–70% of total progress.
          _progress = 0.1 + (completed / total) * 0.6;
          _statusMessage = 'Downloading images ($completed/$total)…';
          notifyListeners();
        },
      );

      // 4. Build ZIP.
      _statusMessage = 'Building archive…';
      _progress = 0.75;
      notifyListeners();

      final zipPath = await _archiveService.createArchive(
        issues: issues,
        imageBytes: imageBytes,
      );

      _progress = 0.95;
      _statusMessage = 'Sharing…';
      notifyListeners();

      // 5. Share.
      final label = unresolvedOnly ? 'Unresolved' : 'All';
      await Share.shareXFiles(
        [XFile(zipPath)],
        text: '$label Issues Archive (${issues.length} issues, '
            '${imageBytes.length} photos)',
      );

      _progress = 1.0;
      _statusMessage = 'Done';
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _statusMessage = 'Failed';
      notifyListeners();
    } finally {
      _isArchiving = false;
      notifyListeners();
    }
  }

  Future<List<Issue>> _fetchIssues(
      String communityId, bool unresolvedOnly) async {
    final stream = unresolvedOnly
        ? _firestoreService.getUnresolvedIssuesByCommunityStream(communityId)
        : _firestoreService.getIssuesByCommunityStream(communityId);
    return stream.first;
  }

  void reset() {
    _isArchiving = false;
    _progress = 0.0;
    _statusMessage = '';
    _error = null;
    notifyListeners();
  }
}
