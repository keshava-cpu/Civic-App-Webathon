import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/core/utils/geo_utils.dart';
import 'package:civic_contribution/data/services/database_service.dart';
import 'package:civic_contribution/data/services/phash_service.dart';

enum DuplicateResult { newIssue, merged }

class DuplicateCheckOutcome {
  final DuplicateResult result;
  final String? existingIssueId;

  const DuplicateCheckOutcome({required this.result, this.existingIssueId});
}

/// Result from an early pHash warning check.
class PHashDuplicateResult {
  final bool isDuplicate;
  final String? existingIssueId;
  final String? existingDescription;
  final int? hammingDistance;

  const PHashDuplicateResult({
    required this.isDuplicate,
    this.existingIssueId,
    this.existingDescription,
    this.hammingDistance,
  });
}

/// Single responsibility: duplicate detection — pHash, MD5 hash, and geo-proximity.
class DuplicateService {
  final DatabaseService _firestoreService;
  final PhashService _phashService;

  DuplicateService(this._firestoreService, this._phashService);

  /// Early-warning pHash check shown on the form screen before submission.
  /// Queries community-scoped issues filtered by category (active only),
  /// finds the minimum Hamming distance match, returns a result.
  Future<PHashDuplicateResult> checkPHashDuplicate({
    required String? newPHash,
    required IssueCategory category,
    required String? communityId,
  }) async {
    if (newPHash == null) {
      return const PHashDuplicateResult(isDuplicate: false);
    }

    final allIssues = communityId != null
        ? await _firestoreService.getAllIssuesByCommunityOnce(communityId)
        : await _firestoreService.getAllIssuesOnce();

    // Filter: same category, active, has pHash
    final candidates = allIssues.where((issue) {
      if (issue.category != category) return false;
      if (issue.status == IssueStatus.verified) return false;
      return issue.pHashValue != null;
    }).toList();

    if (candidates.isEmpty) {
      return const PHashDuplicateResult(isDuplicate: false);
    }

    // Find the minimum Hamming distance
    Issue? bestMatch;
    int bestDistance = 65; // max possible is 64

    for (final issue in candidates) {
      final dist = _phashService.hammingDistance(newPHash, issue.pHashValue);
      if (dist != null && dist < bestDistance) {
        bestDistance = dist;
        bestMatch = issue;
      }
    }

    if (bestMatch != null && bestDistance < kPHashHammingThreshold) {
      return PHashDuplicateResult(
        isDuplicate: true,
        existingIssueId: bestMatch.id,
        existingDescription: bestMatch.description,
        hammingDistance: bestDistance,
      );
    }

    return const PHashDuplicateResult(isDuplicate: false);
  }

  /// Full duplicate check run at submission time.
  /// Order: pHash → MD5 → geo-nearest.
  Future<DuplicateCheckOutcome> checkAndHandle({
    required double latitude,
    required double longitude,
    required IssueCategory category,
    required String? photoHash,
    required String? pHashValue,
    required String reporterId,
  }) async {
    final allIssues = await _firestoreService.getAllIssuesOnce();

    // Filter to same category within radius
    final nearby = allIssues.where((issue) {
      if (issue.category != category) return false;
      if (issue.status == IssueStatus.verified) return false;

      final dist = GeoUtils.distanceInMeters(
        issue.latitude,
        issue.longitude,
        latitude,
        longitude,
      );
      return dist <= kDuplicateRadiusMeters;
    }).toList();

    if (nearby.isEmpty) {
      return const DuplicateCheckOutcome(result: DuplicateResult.newIssue);
    }

    // 1. pHash similarity check (strongest signal)
    if (pHashValue != null) {
      for (final issue in nearby) {
        if (issue.pHashValue == null) continue;
        final dist =
            _phashService.hammingDistance(pHashValue, issue.pHashValue);
        if (dist != null && dist < kPHashHammingThreshold) {
          if (!issue.upvoterIds.contains(reporterId)) {
            await _firestoreService.upvoteIssue(issue.id, reporterId);
          }
          return DuplicateCheckOutcome(
            result: DuplicateResult.merged,
            existingIssueId: issue.id,
          );
        }
      }
    }

    // 2. Exact MD5 hash match
    if (photoHash != null) {
      final hashMatch =
          nearby.where((i) => i.photoHash == photoHash).toList();
      if (hashMatch.isNotEmpty) {
        final target = hashMatch.first;
        if (!target.upvoterIds.contains(reporterId)) {
          await _firestoreService.upvoteIssue(target.id, reporterId);
        }
        return DuplicateCheckOutcome(
          result: DuplicateResult.merged,
          existingIssueId: target.id,
        );
      }
    }

    // 3. Geo-nearest merge
    nearby.sort((a, b) {
      final distA = GeoUtils.distanceInMeters(
        a.latitude,
        a.longitude,
        latitude,
        longitude,
      );
      final distB = GeoUtils.distanceInMeters(
        b.latitude,
        b.longitude,
        latitude,
        longitude,
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
