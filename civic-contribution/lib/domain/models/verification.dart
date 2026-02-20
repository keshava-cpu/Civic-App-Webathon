import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Verification.fromFirestore(DocumentSnapshot doc, String issueId) {
    final data = doc.data() as Map<String, dynamic>;
    return Verification(
      id: doc.id,
      issueId: issueId,
      verifierId: data['verifierId'] ?? '',
      photoUrl: data['photoUrl'],
      isResolved: data['isResolved'] ?? false,
      comment: data['comment'] ?? '',
      verifierTrustScore: (data['verifierTrustScore'] ?? 0.5).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creditsAwarded: (data['creditsAwarded'] ?? 0) as int,
      isReversed: (data['isReversed'] ?? false) as bool,
      isLocked: (data['isLocked'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'verifierId': verifierId,
      'photoUrl': photoUrl,
      'isResolved': isResolved,
      'comment': comment,
      'verifierTrustScore': verifierTrustScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'creditsAwarded': creditsAwarded,
      'isReversed': isReversed,
      'isLocked': isLocked,
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
