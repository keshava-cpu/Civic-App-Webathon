import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/issue.dart';
import '../services/credits_service.dart';
import '../services/duplicate_service.dart';
import '../services/firestore_service.dart';
import '../services/image_metadata_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

enum ReportStep { camera, form, confirm }

class ReportFlowProvider extends ChangeNotifier {
  final LocationService _locationService;
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final DuplicateService _duplicateService;
  final CreditsService _creditsService;
  final ImageMetadataService _metadataService;

  // Form state
  File? capturedImage;
  IssueCategory selectedCategory = IssueCategory.other;
  String description = '';
  double? latitude;
  double? longitude;
  String address = '';
  String? photoHash;
  Map<String, dynamic>? exifData;
  bool _fetchingLocation = false;
  bool _submitting = false;
  String? _lastError;
  String? _lastSubmittedIssueId;
  bool _wasDuplicate = false;

  bool get submitting => _submitting;
  bool get fetchingLocation => _fetchingLocation;
  String? get lastError => _lastError;
  String? get lastSubmittedIssueId => _lastSubmittedIssueId;
  bool get wasDuplicate => _wasDuplicate;

  ReportFlowProvider({
    required LocationService locationService,
    required FirestoreService firestoreService,
    required StorageService storageService,
    required DuplicateService duplicateService,
    required CreditsService creditsService,
    required ImageMetadataService metadataService,
  })  : _locationService = locationService,
        _firestoreService = firestoreService,
        _storageService = storageService,
        _duplicateService = duplicateService,
        _creditsService = creditsService,
        _metadataService = metadataService;

  Future<void> onPhotoCaptured(File imageFile) async {
    capturedImage = imageFile;
    _fetchingLocation = true;
    notifyListeners();

    try {
      // Extract metadata
      final metadata = await _metadataService.extract(imageFile);
      photoHash = metadata.hash;
      exifData = metadata.raw.isEmpty ? null : metadata.raw;

      // Use EXIF GPS if available and valid (not 0,0), otherwise get current position
      final hasValidExifLocation = metadata.latitude != null && 
          metadata.longitude != null &&
          (metadata.latitude! > 0 || metadata.latitude! < 0) &&
          (metadata.longitude! > 0 || metadata.longitude! < 0);
          
      if (hasValidExifLocation) {
        latitude = metadata.latitude;
        longitude = metadata.longitude;
        print('Using EXIF location: $latitude, $longitude');
      } else {
        print('EXIF location invalid or missing, fetching from GPS...');
        await fetchCurrentLocation();
      }
    } catch (e) {
      print('Error in onPhotoCaptured: $e');
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
        print('Location fetched: $latitude, $longitude');
      } else {
        print('Failed to get position - services may be disabled or permission denied');
      }
    } catch (e) {
      print('Error fetching location: $e');
    } finally {
      _fetchingLocation = false;
      notifyListeners();
    }
  }

  void setCategory(IssueCategory category) {
    selectedCategory = category;
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

  Future<bool> submit(String userId) async {
    _submitting = true;
    _lastError = null;
    notifyListeners();

    try {
      // Upload photo
      String? photoUrl;
      if (capturedImage != null) {
        photoUrl = await _storageService.uploadIssuePhoto(capturedImage!, userId);
      }

      // Ensure location is valid (never submit 0,0)
      if (latitude == null || longitude == null) {
        throw Exception('Location is required. Please allow location access.');
      }
      final location = GeoPoint(latitude!, longitude!);

      // Check duplicate
      final outcome = await _duplicateService.checkAndHandle(
        location: location,
        category: selectedCategory,
        photoHash: photoHash,
        reporterId: userId,
      );

      if (outcome.result == DuplicateResult.merged) {
        _wasDuplicate = true;
        _lastSubmittedIssueId = outcome.existingIssueId;
        await _creditsService.awardUpvote(userId);
        _submitting = false;
        notifyListeners();
        return true;
      }

      // Create new issue
      final issue = Issue(
        id: '',
        reporterId: userId,
        category: selectedCategory,
        description: description,
        location: location,
        address: address,
        photoUrl: photoUrl,
        photoHash: photoHash,
        exifData: exifData,
        status: IssueStatus.pending,
        priorityScore: 1,
        upvoterIds: [],
        mergedIssueIds: [],
        assignedTo: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final issueId = await _firestoreService.createIssue(issue);
      await _creditsService.awardReport(userId);

      _wasDuplicate = false;
      _lastSubmittedIssueId = issueId;
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

  void reset() {
    capturedImage = null;
    selectedCategory = IssueCategory.other;
    description = '';
    latitude = null;
    longitude = null;
    address = '';
    photoHash = null;
    exifData = null;
    _submitting = false;
    _lastError = null;
    _lastSubmittedIssueId = null;
    _wasDuplicate = false;
    notifyListeners();
  }
}
