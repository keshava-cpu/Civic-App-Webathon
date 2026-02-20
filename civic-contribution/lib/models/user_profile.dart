import 'package:cloud_firestore/cloud_firestore.dart';

class Badge {
  final String id;
  final String label;
  final String emoji;
  final DateTime earnedAt;

  Badge({
    required this.id,
    required this.label,
    required this.emoji,
    required this.earnedAt,
  });

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      emoji: map['emoji'] ?? '',
      earnedAt: (map['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'emoji': emoji,
      'earnedAt': Timestamp.fromDate(earnedAt),
    };
  }
}

class UserProfile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final double trustScore;
  final int civicCredits;
  final List<Badge> badges;
  final int issuesReported;
  final int verificationsCompleted;
  final int tasksCompleted;

  UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.trustScore,
    required this.civicCredits,
    required this.badges,
    required this.issuesReported,
    required this.verificationsCompleted,
    required this.tasksCompleted,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      trustScore: (data['trustScore'] ?? 0.5).toDouble(),
      civicCredits: (data['civicCredits'] ?? 0) as int,
      badges: (data['badges'] as List<dynamic>? ?? [])
          .map((b) => Badge.fromMap(b as Map<String, dynamic>))
          .toList(),
      issuesReported: (data['issuesReported'] ?? 0) as int,
      verificationsCompleted: (data['verificationsCompleted'] ?? 0) as int,
      tasksCompleted: (data['tasksCompleted'] ?? 0) as int,
    );
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      trustScore: (data['trustScore'] ?? 0.5).toDouble(),
      civicCredits: (data['civicCredits'] ?? 0) as int,
      badges: (data['badges'] as List<dynamic>? ?? [])
          .map((b) => Badge.fromMap(b as Map<String, dynamic>))
          .toList(),
      issuesReported: (data['issuesReported'] ?? 0) as int,
      verificationsCompleted: (data['verificationsCompleted'] ?? 0) as int,
      tasksCompleted: (data['tasksCompleted'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'trustScore': trustScore,
      'civicCredits': civicCredits,
      'badges': badges.map((b) => b.toMap()).toList(),
      'issuesReported': issuesReported,
      'verificationsCompleted': verificationsCompleted,
      'tasksCompleted': tasksCompleted,
    };
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    double? trustScore,
    int? civicCredits,
    List<Badge>? badges,
    int? issuesReported,
    int? verificationsCompleted,
    int? tasksCompleted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      trustScore: trustScore ?? this.trustScore,
      civicCredits: civicCredits ?? this.civicCredits,
      badges: badges ?? this.badges,
      issuesReported: issuesReported ?? this.issuesReported,
      verificationsCompleted:
          verificationsCompleted ?? this.verificationsCompleted,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
    );
  }
}
