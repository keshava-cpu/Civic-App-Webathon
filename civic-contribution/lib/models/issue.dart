import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class Issue {
  final String id;
  final String reporterId;
  final IssueCategory category;
  final String description;
  final GeoPoint location;
  final String address;
  final String? photoUrl;
  final String? photoHash;
  final Map<String, dynamic>? exifData;
  final IssueStatus status;
  final int priorityScore;
  final List<String> upvoterIds;
  final List<String> mergedIssueIds;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Issue({
    required this.id,
    required this.reporterId,
    required this.category,
    required this.description,
    required this.location,
    required this.address,
    this.photoUrl,
    this.photoHash,
    this.exifData,
    required this.status,
    required this.priorityScore,
    required this.upvoterIds,
    required this.mergedIssueIds,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Issue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Validate location - must have valid lat/long, not 0,0
    GeoPoint location = data['location'] as GeoPoint? ?? const GeoPoint(0, 0);
    if (location.latitude == 0 && location.longitude == 0) {
      // Use a default center location for India instead of 0,0
      location = const GeoPoint(12.9716, 77.5946);
    }
    return Issue(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      category: categoryFromString(data['category'] ?? 'other'),
      description: data['description'] ?? '',
      location: location,
      address: data['address'] ?? '',
      photoUrl: data['photoUrl'],
      photoHash: data['photoHash'],
      exifData: data['exifData'] as Map<String, dynamic>?,
      status: issueStatusFromString(data['status'] ?? 'pending'),
      priorityScore: (data['priorityScore'] ?? 0) as int,
      upvoterIds: List<String>.from(data['upvoterIds'] ?? []),
      mergedIssueIds: List<String>.from(data['mergedIssueIds'] ?? []),
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Check if location is valid (not default/invalid coordinates)
  bool get hasValidLocation {
    return !(location.latitude == 0 && location.longitude == 0) &&
        location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'category': category.name,
      'description': description,
      'location': location,
      'address': address,
      'photoUrl': photoUrl,
      'photoHash': photoHash,
      'exifData': exifData,
      'status': status.value,
      'priorityScore': priorityScore,
      'upvoterIds': upvoterIds,
      'mergedIssueIds': mergedIssueIds,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Issue copyWith({
    String? id,
    String? reporterId,
    IssueCategory? category,
    String? description,
    GeoPoint? location,
    String? address,
    String? photoUrl,
    String? photoHash,
    Map<String, dynamic>? exifData,
    IssueStatus? status,
    int? priorityScore,
    List<String>? upvoterIds,
    List<String>? mergedIssueIds,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Issue(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      photoHash: photoHash ?? this.photoHash,
      exifData: exifData ?? this.exifData,
      status: status ?? this.status,
      priorityScore: priorityScore ?? this.priorityScore,
      upvoterIds: upvoterIds ?? this.upvoterIds,
      mergedIssueIds: mergedIssueIds ?? this.mergedIssueIds,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
