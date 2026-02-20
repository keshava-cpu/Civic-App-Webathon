import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import 'firestore_service.dart';

class CreditsService {
  final FirestoreService _firestoreService;

  CreditsService(this._firestoreService);

  Future<void> awardReport(String userId) async {
    await _firestoreService.incrementUserCredits(userId, kPointsReport);
    await _firestoreService.incrementUserStat(userId, 'issuesReported');
    await _checkBadges(userId);
  }

  Future<void> awardUpvote(String userId) async {
    await _firestoreService.incrementUserCredits(userId, kPointsUpvote);
    await _checkBadges(userId);
  }

  Future<void> awardVerification(String userId) async {
    await _firestoreService.incrementUserCredits(userId, kPointsVerify);
    await _firestoreService.incrementUserStat(userId, 'verificationsCompleted');
    await _checkBadges(userId);
  }

  Future<void> awardTask(String userId) async {
    await _firestoreService.incrementUserCredits(userId, kPointsTask);
    await _firestoreService.incrementUserStat(userId, 'tasksCompleted');
    await _checkBadges(userId);
  }

  Future<void> _checkBadges(String userId) async {
    final user = await _firestoreService.getUser(userId);
    if (user == null) return;

    final credits = user.civicCredits;
    final existingBadgeIds = user.badges.map((b) => b.id).toSet();

    if (credits >= kBadgeGoldCredits && !existingBadgeIds.contains('gold')) {
      await _firestoreService.addBadge(userId, {
        'id': 'gold',
        'label': 'Gold Civic',
        'emoji': '🥇',
        'earnedAt': Timestamp.now(),
      });
    } else if (credits >= kBadgeSilverCredits &&
        !existingBadgeIds.contains('silver')) {
      await _firestoreService.addBadge(userId, {
        'id': 'silver',
        'label': 'Silver Civic',
        'emoji': '🥈',
        'earnedAt': Timestamp.now(),
      });
    } else if (credits >= kBadgeBronzeCredits &&
        !existingBadgeIds.contains('bronze')) {
      await _firestoreService.addBadge(userId, {
        'id': 'bronze',
        'label': 'Bronze Civic',
        'emoji': '🥉',
        'earnedAt': Timestamp.now(),
      });
    }
  }
}
