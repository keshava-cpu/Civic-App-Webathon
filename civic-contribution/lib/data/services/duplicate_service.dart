import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/core/utils/geo_utils.dart';
import 'package:civic_contribution/data/services/firestore_service.dart';

enum DuplicateResult { newIssue, merged }

class DuplicateCheckOutcome {
  final DuplicateResult result;
  final String? existingIssueId;

  const DuplicateCheckOutcome({required this.result, this.existingIssueId});
}

class DuplicateService {
  final FirestoreService _firestoreService;

  DuplicateService(this._firestoreService);

  Future<DuplicateCheckOutcome> checkAndHandle({
    required GeoPoint location,
    required IssueCategory category,
    required String? photoHash,
    required String reporterId,
  }) async {
    final allIssues = await _firestoreService.getAllIssuesOnce();

    // Filter to same category within radius
    final nearby = allIssues.where((issue) {
      if (issue.category != category) return false;
      if (issue.status == IssueStatus.verified) return false;

      final dist = GeoUtils.distanceInMeters(
        issue.location.latitude,
        issue.location.longitude,
        location.latitude,
        location.longitude,
      );
      return dist <= kDuplicateRadiusMeters;
    }).toList();

    if (nearby.isEmpty) {
      return const DuplicateCheckOutcome(result: DuplicateResult.newIssue);
    }

    // Check for exact hash match first
    if (photoHash != null) {
      final hashMatch = nearby.where((i) => i.photoHash == photoHash).toList();
      if (hashMatch.isNotEmpty) {
        final target = hashMatch.first;
        await _firestoreService.upvoteIssue(target.id, reporterId);
        return DuplicateCheckOutcome(
          result: DuplicateResult.merged,
          existingIssueId: target.id,
        );
      }
    }

    // Merge as upvote to closest existing
    nearby.sort((a, b) {
      final distA = GeoUtils.distanceInMeters(
        a.location.latitude,
        a.location.longitude,
        location.latitude,
        location.longitude,
      );
      final distB = GeoUtils.distanceInMeters(
        b.location.latitude,
        b.location.longitude,
        location.latitude,
        location.longitude,
      );
      return distA.compareTo(distB);
    });

    final target = nearby.first;

    // Don't merge if user already upvoted
    if (target.upvoterIds.contains(reporterId)) {
      return const DuplicateCheckOutcome(result: DuplicateResult.newIssue);
    }

    await _firestoreService.upvoteIssue(target.id, reporterId);
    return DuplicateCheckOutcome(
      result: DuplicateResult.merged,
      existingIssueId: target.id,
    );
  }
}

