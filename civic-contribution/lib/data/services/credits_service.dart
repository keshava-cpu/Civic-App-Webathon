import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/data/services/database_service.dart';

/// Single responsibility: award civic credits and check badge thresholds.
class CreditsService {
  final DatabaseService _databaseService;

  CreditsService(this._databaseService);

  Future<void> awardReport(String userId) async {
    await _databaseService.incrementUserCredits(userId, kPointsReport);
    await _databaseService.incrementUserStat(userId, 'issues_reported');
    await _checkBadges(userId);
  }

  Future<void> awardUpvote(String userId) async {
    await _databaseService.incrementUserCredits(userId, kPointsUpvote);
    await _checkBadges(userId);
  }

  Future<void> awardVerification(String userId) async {
    await _databaseService.incrementUserCredits(userId, kPointsVerify);
    await _databaseService.incrementUserStat(userId, 'verifications_completed');
    await _checkBadges(userId);
  }

  Future<void> awardTask(String userId) async {
    await _databaseService.incrementUserCredits(userId, kPointsTask);
    await _databaseService.incrementUserStat(userId, 'tasks_completed');
    await _checkBadges(userId);
  }

  Future<void> deductCredits(String userId, int amount) async {
    await _databaseService.incrementUserCredits(userId, -amount);
  }

  Future<void> awardVerificationReversal(String userId) async {
    await _databaseService.incrementUserCredits(
        userId, kPointsVerificationReversal);
    await _checkBadges(userId);
  }

  Future<void> _checkBadges(String userId) async {
    final user = await _databaseService.getUser(userId);
    if (user == null) return;

    final credits = user.civicCredits;
    final existingBadgeIds = user.badges.map((b) => b.id).toSet();
    final now = DateTime.now().toIso8601String();

    if (credits >= kBadgeGoldCredits && !existingBadgeIds.contains('gold')) {
      await _databaseService.addBadge(userId, {
        'id': 'gold',
        'label': 'Gold Civic',
        'emoji': '🥇',
        'earned_at': now,
      });
    } else if (credits >= kBadgeSilverCredits &&
        !existingBadgeIds.contains('silver')) {
      await _databaseService.addBadge(userId, {
        'id': 'silver',
        'label': 'Silver Civic',
        'emoji': '🥈',
        'earned_at': now,
      });
    } else if (credits >= kBadgeBronzeCredits &&
        !existingBadgeIds.contains('bronze')) {
      await _databaseService.addBadge(userId, {
        'id': 'bronze',
        'label': 'Bronze Civic',
        'emoji': '🥉',
        'earned_at': now,
      });
    }
  }
}
