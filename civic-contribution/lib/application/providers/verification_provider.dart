import 'dart:io';
import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/verification.dart';
import 'package:civic_contribution/data/services/credits_service.dart';
import 'package:civic_contribution/data/services/database_service.dart';
import 'package:civic_contribution/data/services/storage_service.dart';

class VerificationProvider extends ChangeNotifier {
  final DatabaseService _firestoreService;
  final StorageService _storageService;
  final CreditsService _creditsService;

  bool _submitting = false;
  String? _lastError;

  bool get submitting => _submitting;
  String? get lastError => _lastError;

  VerificationProvider(
    this._firestoreService,
    this._storageService,
    this._creditsService,
  );

  /// F4: Get existing verification for a user on an issue.
  Future<Verification?> getExistingVerification(
      String issueId, String userId) async {
    return _firestoreService.getUserVerification(issueId, userId);
  }

  /// F4: Reverse a previous verification vote (one-time only).
  Future<bool> reverseVerification({
    required String issueId,
    required String userId,
    required bool newIsResolved,
    required String newComment,
  }) async {
    _submitting = true;
    _lastError = null;
    notifyListeners();

    try {
      final existing =
          await _firestoreService.getUserVerification(issueId, userId);
      if (existing == null) {
        throw Exception('No existing verification found');
      }
      if (existing.isLocked) {
        throw Exception('Verification is locked. Already changed once.');
      }

      // Deduct original credits, award partial
      await _creditsService.deductCredits(userId, existing.creditsAwarded);
      await _creditsService.awardVerificationReversal(userId);

      // Update verification doc
      await _firestoreService.updateVerification(issueId, existing.id, {
        'is_resolved': newIsResolved,
        'comment': newComment,
        'is_reversed': true,
        'is_locked': true,
        'credits_awarded': kPointsVerificationReversal,
      });

      // Re-check auto-verify
      await _checkAutoVerify(issueId);

      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitVerification({
    required String issueId,
    required String verifierId,
    required double verifierTrustScore,
    required bool isResolved,
    required String comment,
    File? photo,
  }) async {
    _submitting = true;
    _lastError = null;
    notifyListeners();

    try {
      String? photoUrl;
      if (photo != null) {
        photoUrl =
            await _storageService.uploadVerificationPhoto(photo, verifierId);
      }

      final verification = Verification(
        id: '',
        issueId: issueId,
        verifierId: verifierId,
        photoUrl: photoUrl,
        isResolved: isResolved,
        comment: comment,
        verifierTrustScore: verifierTrustScore,
        createdAt: DateTime.now(),
        creditsAwarded: kPointsVerify,
        isReversed: false,
        isLocked: false,
      );

      await _firestoreService.addVerification(issueId, verification);
      await _creditsService.awardVerification(verifierId);

      // Check if we should auto-verify the issue
      await _checkAutoVerify(issueId);

      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _checkAutoVerify(String issueId) async {
    final verifications =
        await _firestoreService.getVerificationsStream(issueId).first;

    if (verifications.length < kMinVerifications) return;

    double weightedYes = 0;
    double weightedTotal = 0;

    for (final v in verifications) {
      final weight = v.verifierTrustScore;
      weightedTotal += weight;
      if (v.isResolved) weightedYes += weight;
    }

    if (weightedTotal == 0) return;

    final ratio = weightedYes / weightedTotal;
    if (ratio >= kVerificationThreshold) {
      await _firestoreService.updateIssueStatus(
          issueId, IssueStatus.verified.value);
      return;
    }

    const reopenThreshold = 1 - kVerificationThreshold;
    if (ratio <= reopenThreshold) {
      await _firestoreService.updateIssueStatus(
          issueId, IssueStatus.inProgress.value);
    }
  }
}

