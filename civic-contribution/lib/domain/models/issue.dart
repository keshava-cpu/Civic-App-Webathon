import 'package:civic_contribution/domain/constants.dart';

class Issue {
  final String id;
  final String reporterId;
  final IssueCategory category;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final String? photoUrl;
  final String? photoHash;
  final String? pHashValue;
  final Map<String, dynamic>? exifData;
  final IssueStatus status;
  final int priorityScore;
  final List<String> upvoterIds;
  final List<String> mergedIssueIds;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? communityId;

  Issue({
    required this.id,
    required this.reporterId,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.photoUrl,
    this.photoHash,
    this.pHashValue,
    this.exifData,
    required this.status,
    required this.priorityScore,
    required this.upvoterIds,
    required this.mergedIssueIds,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.communityId,
  });

  factory Issue.fromMap(String id, Map<String, dynamic> data) {
    double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    if (lat == 0.0 && lng == 0.0) {
      lat = 12.9716;
      lng = 77.5946;
    }
    return Issue(
      id: id,
      reporterId: data['reporter_id'] ?? '',
      category: categoryFromString(data['category'] ?? 'other'),
      description: data['description'] ?? '',
      latitude: lat,
      longitude: lng,
      address: data['address'] ?? '',
      photoUrl: data['photo_url'],
      photoHash: data['photo_hash'],
      pHashValue: data['p_hash_value'],
      exifData: data['exif_data'] != null
          ? Map<String, dynamic>.from(data['exif_data'] as Map)
          : null,
      status: issueStatusFromString(data['status'] ?? 'pending'),
      priorityScore: (data['priority_score'] ?? 0) as int,
      upvoterIds: List<String>.from(data['upvoter_ids'] ?? []),
      mergedIssueIds: List<String>.from(data['merged_issue_ids'] ?? []),
      assignedTo: data['assigned_to'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : DateTime.now(),
      communityId: data['community_id'],
    );
  }

  bool get hasValidLocation {
    return !(latitude == 0 && longitude == 0) &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  Map<String, dynamic> toMap() {
    return {
      'reporter_id': reporterId,
      'category': category.name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'photo_url': photoUrl,
      'photo_hash': photoHash,
      'p_hash_value': pHashValue,
      'exif_data': exifData,
      'status': status.value,
      'priority_score': priorityScore,
      'upvoter_ids': upvoterIds,
      'merged_issue_ids': mergedIssueIds,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'community_id': communityId,
    };
  }

  Issue copyWith({
    String? id,
    String? reporterId,
    IssueCategory? category,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    String? photoUrl,
    String? photoHash,
    String? pHashValue,
    Map<String, dynamic>? exifData,
    IssueStatus? status,
    int? priorityScore,
    List<String>? upvoterIds,
    List<String>? mergedIssueIds,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? communityId,
  }) {
    return Issue(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      category: category ?? this.category,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      photoHash: photoHash ?? this.photoHash,
      pHashValue: pHashValue ?? this.pHashValue,
      exifData: exifData ?? this.exifData,
      status: status ?? this.status,
      priorityScore: priorityScore ?? this.priorityScore,
      upvoterIds: upvoterIds ?? this.upvoterIds,
      mergedIssueIds: mergedIssueIds ?? this.mergedIssueIds,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      communityId: communityId ?? this.communityId,
    );
  }
}
