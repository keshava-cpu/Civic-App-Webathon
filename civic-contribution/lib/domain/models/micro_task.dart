class MicroTask {
  final String id;
  final String issueId;
  final String title;
  final String? assigneeId;
  final bool completed;
  final DateTime? completedAt;
  final double? completedLatitude;
  final double? completedLongitude;

  MicroTask({
    required this.id,
    required this.issueId,
    required this.title,
    this.assigneeId,
    required this.completed,
    this.completedAt,
    this.completedLatitude,
    this.completedLongitude,
  });

  factory MicroTask.fromMap(String id, Map<String, dynamic> data) {
    return MicroTask(
      id: id,
      issueId: data['issue_id'] ?? '',
      title: data['title'] ?? '',
      assigneeId: data['assignee_id'],
      completed: data['completed'] ?? false,
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'] as String)
          : null,
      completedLatitude: (data['completed_latitude'] as num?)?.toDouble(),
      completedLongitude: (data['completed_longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issue_id': issueId,
      'title': title,
      'assignee_id': assigneeId,
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
      'completed_latitude': completedLatitude,
      'completed_longitude': completedLongitude,
    };
  }

  MicroTask copyWith({
    String? id,
    String? issueId,
    String? title,
    String? assigneeId,
    bool? completed,
    DateTime? completedAt,
    double? completedLatitude,
    double? completedLongitude,
  }) {
    return MicroTask(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      title: title ?? this.title,
      assigneeId: assigneeId ?? this.assigneeId,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      completedLatitude: completedLatitude ?? this.completedLatitude,
      completedLongitude: completedLongitude ?? this.completedLongitude,
    );
  }
}
