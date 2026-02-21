class Verification {
  final String id;
  final String issueId;
  final String verifierId;
  final String? photoUrl;
  final bool isResolved;
  final String comment;
  final double verifierTrustScore;
  final DateTime createdAt;
  final int creditsAwarded;
  final bool isReversed;
  final bool isLocked;

  Verification({
    required this.id,
    required this.issueId,
    required this.verifierId,
    this.photoUrl,
    required this.isResolved,
    required this.comment,
    required this.verifierTrustScore,
    required this.createdAt,
    required this.creditsAwarded,
    required this.isReversed,
    required this.isLocked,
  });

  factory Verification.fromMap(String id, Map<String, dynamic> data) {
    return Verification(
      id: id,
      issueId: data['issue_id'] ?? '',
      verifierId: data['verifier_id'] ?? '',
      photoUrl: data['photo_url'],
      isResolved: data['is_resolved'] ?? false,
      comment: data['comment'] ?? '',
      verifierTrustScore: (data['verifier_trust_score'] ?? 0.5).toDouble(),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
      creditsAwarded: (data['credits_awarded'] ?? 0) as int,
      isReversed: (data['is_reversed'] ?? false) as bool,
      isLocked: (data['is_locked'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issue_id': issueId,
      'verifier_id': verifierId,
      'photo_url': photoUrl,
      'is_resolved': isResolved,
      'comment': comment,
      'verifier_trust_score': verifierTrustScore,
      'created_at': createdAt.toIso8601String(),
      'credits_awarded': creditsAwarded,
      'is_reversed': isReversed,
      'is_locked': isLocked,
    };
  }

  Verification copyWith({
    String? id,
    String? issueId,
    String? verifierId,
    String? photoUrl,
    bool? isResolved,
    String? comment,
    double? verifierTrustScore,
    DateTime? createdAt,
    int? creditsAwarded,
    bool? isReversed,
    bool? isLocked,
  }) {
    return Verification(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      verifierId: verifierId ?? this.verifierId,
      photoUrl: photoUrl ?? this.photoUrl,
      isResolved: isResolved ?? this.isResolved,
      comment: comment ?? this.comment,
      verifierTrustScore: verifierTrustScore ?? this.verifierTrustScore,
      createdAt: createdAt ?? this.createdAt,
      creditsAwarded: creditsAwarded ?? this.creditsAwarded,
      isReversed: isReversed ?? this.isReversed,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
