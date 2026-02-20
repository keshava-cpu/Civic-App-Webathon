import 'dart:io';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/verification.dart';
import '../services/credits_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class VerificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
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
    }
  }
}
