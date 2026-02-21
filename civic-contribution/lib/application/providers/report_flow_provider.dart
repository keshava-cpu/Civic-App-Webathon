import 'dart:io';
import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/data/services/credits_service.dart';
import 'package:civic_contribution/data/services/duplicate_service.dart';
import 'package:civic_contribution/data/services/database_service.dart';
import 'package:civic_contribution/data/services/image_metadata_service.dart';
import 'package:civic_contribution/data/services/location_service.dart';
import 'package:civic_contribution/data/services/phash_service.dart';
import 'package:civic_contribution/data/services/storage_service.dart';

enum ReportStep { camera, form, confirm }

class ReportFlowProvider extends ChangeNotifier {
  final LocationService _locationService;
  final DatabaseService _firestoreService;
  final StorageService _storageService;
  final DuplicateService _duplicateService;
  final CreditsService _creditsService;
  final ImageMetadataService _metadataService;
  final PhashService _phashService;

  // Form state
  File? capturedImage;
  IssueCategory selectedCategory = IssueCategory.other;
  String description = '';
  double? latitude;
  double? longitude;
  String address = '';
  String? photoHash;
  String? pHashValue;
  Map<String, dynamic>? exifData;
  bool _fetchingLocation = false;
  bool _submitting = false;
  bool _checkingPHash = false;
  String? _lastError;
  String? _lastSubmittedIssueId;
  bool _wasDuplicate = false;
  PHashDuplicateResult? _pHashDuplicateResult;

  bool get submitting => _submitting;
  bool get fetchingLocation => _fetchingLocation;
  bool get checkingPHash => _checkingPHash;
  String? get lastError => _lastError;
  String? get lastSubmittedIssueId => _lastSubmittedIssueId;
  bool get wasDuplicate => _wasDuplicate;
  PHashDuplicateResult? get pHashDuplicateResult => _pHashDuplicateResult;
  bool get hasPHashWarning =>
      _pHashDuplicateResult != null && _pHashDuplicateResult!.isDuplicate;

  ReportFlowProvider({
    required LocationService locationService,
    required DatabaseService firestoreService,
    required StorageService storageService,
    required DuplicateService duplicateService,
    required CreditsService creditsService,
    required ImageMetadataService metadataService,
    required PhashService phashService,
  })  : _locationService = locationService,
        _firestoreService = firestoreService,
        _storageService = storageService,
        _duplicateService = duplicateService,
        _creditsService = creditsService,
        _metadataService = metadataService,
        _phashService = phashService;

  Future<void> onPhotoCaptured(File imageFile) async {
    capturedImage = imageFile;
    _fetchingLocation = true;
    notifyListeners();

    try {
      // Extract metadata (MD5 hash + EXIF + pHash)
      final metadata = await _metadataService.extract(imageFile);
      photoHash = metadata.hash;
      pHashValue = metadata.pHashValue;
      exifData = metadata.raw.isEmpty ? null : metadata.raw;

      // Use EXIF GPS if available and valid (not 0,0), otherwise get current position
      final hasValidExifLocation = metadata.latitude != null &&
          metadata.longitude != null &&
          (metadata.latitude! > 0 || metadata.latitude! < 0) &&
          (metadata.longitude! > 0 || metadata.longitude! < 0);

      if (hasValidExifLocation) {
        latitude = metadata.latitude;
        longitude = metadata.longitude;
      } else {
        await fetchCurrentLocation();
      }
    } catch (e) {
      await fetchCurrentLocation();
    } finally {
      _fetchingLocation = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentLocation() async {
    _fetchingLocation = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
      }
    } catch (_) {
    } finally {
      _fetchingLocation = false;
      notifyListeners();
    }
  }

  void setCategory(IssueCategory category) {
    selectedCategory = category;
    _pHashDuplicateResult = null;
    notifyListeners();
  }

  void setDescription(String desc) {
    description = desc;
    notifyListeners();
  }

  void setAddress(String addr) {
    address = addr;
    notifyListeners();
  }

  /// Runs pHash duplicate check against community issues.
  /// Call after photo is captured or category changes.
  Future<void> runPHashCheck(String? communityId) async {
    if (pHashValue == null) return;
    _checkingPHash = true;
    _pHashDuplicateResult = null;
    notifyListeners();

    try {
      final result = await _duplicateService.checkPHashDuplicate(
        newPHash: pHashValue,
        category: selectedCategory,
        communityId: communityId,
      );
      _pHashDuplicateResult = result;
    } catch (_) {
    } finally {
      _checkingPHash = false;
      notifyListeners();
    }
  }

  Future<bool> submit(String userId, String? communityId) async {
    _submitting = true;
    _lastError = null;
    notifyListeners();

    try {
      debugPrint('[Report] Starting submission: userId=$userId, community=$communityId');
      
      // Upload photo
      String? photoUrl;
      if (capturedImage != null) {
        debugPrint('[Report] Uploading photo...');
        photoUrl =
            await _storageService.uploadIssuePhoto(capturedImage!, userId);
        debugPrint('[Report] Photo uploaded: $photoUrl');
      }

      // Ensure location is valid (never submit 0,0)
      if (latitude == null || longitude == null) {
        throw Exception('Location is required. Please allow location access.');
      }

      debugPrint('[Report] Running duplicate check at ($latitude, $longitude)');
      // Check duplicate (pHash first, then MD5, then geo)
      final outcome = await _duplicateService.checkAndHandle(
        latitude: latitude!,
        longitude: longitude!,
        category: selectedCategory,
        photoHash: photoHash,
        pHashValue: pHashValue,
        reporterId: userId,
      );

      if (outcome.result == DuplicateResult.merged) {
        debugPrint('[Report] Duplicate detected, merged to ${outcome.existingIssueId}');
        _wasDuplicate = true;
        _lastSubmittedIssueId = outcome.existingIssueId;
        await _creditsService.awardUpvote(userId);
        _submitting = false;
        notifyListeners();
        return true;
      }

      // Create new issue
      debugPrint('[Report] Creating new issue...');
      final issue = Issue(
        id: '',
        reporterId: userId,
        category: selectedCategory,
        description: description,
        latitude: latitude!,
        longitude: longitude!,
        address: address,
        photoUrl: photoUrl,
        photoHash: photoHash,
        pHashValue: pHashValue,
        exifData: exifData,
        status: IssueStatus.pending,
        priorityScore: 1,
        upvoterIds: [],
        mergedIssueIds: [],
        assignedTo: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        communityId: communityId,
      );

      debugPrint('[Report] Issue data prepared, calling createIssue...');
      final issueId = await _firestoreService.createIssue(issue);
      debugPrint('[Report] Issue created: $issueId');
      
      await _creditsService.awardReport(userId);
      debugPrint('[Report] Credits awarded');

      _wasDuplicate = false;
      _lastSubmittedIssueId = issueId;
      _submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Report] ERROR during submission: $e');
      _lastError = e.toString();
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    capturedImage = null;
    selectedCategory = IssueCategory.other;
    description = '';
    latitude = null;
    longitude = null;
    address = '';
    photoHash = null;
    pHashValue = null;
    exifData = null;
    _checkingPHash = false;
    _pHashDuplicateResult = null;
    _submitting = false;
    _lastError = null;
    _lastSubmittedIssueId = null;
    _wasDuplicate = false;
    notifyListeners();
  }
}
