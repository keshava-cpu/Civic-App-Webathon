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

  Verification({
    required this.id,
    required this.issueId,
    required this.verifierId,
    this.photoUrl,
    required this.isResolved,
    required this.comment,
    required this.verifierTrustScore,
    required this.createdAt,
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
    };
  }
}
