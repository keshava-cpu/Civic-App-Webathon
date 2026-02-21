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
      earnedAt: map['earned_at'] != null
          ? DateTime.parse(map['earned_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'emoji': emoji,
      'earned_at': earnedAt.toIso8601String(),
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
  final bool isAdmin;
  final String? communityId;

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
    this.isAdmin = false,
    this.communityId,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      displayName: data['display_name'] ?? '',
      avatarUrl: data['avatar_url'],
      trustScore: (data['trust_score'] ?? 0.5).toDouble(),
      civicCredits: (data['civic_credits'] ?? 0) as int,
      badges: (data['badges'] as List<dynamic>? ?? [])
          .map((b) => Badge.fromMap(b as Map<String, dynamic>))
          .toList(),
      issuesReported: (data['issues_reported'] ?? 0) as int,
      verificationsCompleted: (data['verifications_completed'] ?? 0) as int,
      tasksCompleted: (data['tasks_completed'] ?? 0) as int,
      isAdmin: (data['is_admin'] ?? false) as bool,
      communityId: data['community_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'trust_score': trustScore,
      'civic_credits': civicCredits,
      'badges': badges.map((b) => b.toMap()).toList(),
      'issues_reported': issuesReported,
      'verifications_completed': verificationsCompleted,
      'tasks_completed': tasksCompleted,
      'is_admin': isAdmin,
      'community_id': communityId,
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
    bool? isAdmin,
    String? communityId,
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
      isAdmin: isAdmin ?? this.isAdmin,
      communityId: communityId ?? this.communityId,
    );
  }
}
