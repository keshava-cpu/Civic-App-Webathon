import 'package:cloud_firestore/cloud_firestore.dart';

class MicroTask {
  final String id;
  final String issueId;
  final String title;
  final String? assigneeId;
  final bool completed;
  final DateTime? completedAt;
  final GeoPoint? completedLocation;

  MicroTask({
    required this.id,
    required this.issueId,
    required this.title,
    this.assigneeId,
    required this.completed,
    this.completedAt,
    this.completedLocation,
  });

  factory MicroTask.fromFirestore(DocumentSnapshot doc, String issueId) {
    final data = doc.data() as Map<String, dynamic>;
    return MicroTask(
      id: doc.id,
      issueId: issueId,
      title: data['title'] ?? '',
      assigneeId: data['assigneeId'],
      completed: data['completed'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedLocation: data['completedLocation'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'assigneeId': assigneeId,
      'completed': completed,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedLocation': completedLocation,
    };
  }

  MicroTask copyWith({
    String? id,
    String? issueId,
    String? title,
    String? assigneeId,
    bool? completed,
    DateTime? completedAt,
    GeoPoint? completedLocation,
  }) {
    return MicroTask(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      title: title ?? this.title,
      assigneeId: assigneeId ?? this.assigneeId,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      completedLocation: completedLocation ?? this.completedLocation,
    );
  }
}
