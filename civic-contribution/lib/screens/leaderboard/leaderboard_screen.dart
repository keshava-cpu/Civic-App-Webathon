import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/user_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaderboardProvider>();
    final currentUserId = context.read<UserProvider>().currentUserId;
    final users = provider.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('This Week\'s Leaderboard'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text('No data yet'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final rank = index + 1;
                    final isCurrentUser = user.id == currentUserId;

                    return _LeaderboardTile(
                      user: user,
                      rank: rank,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final UserProfile user;
  final int rank;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.user,
    required this.rank,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTopThree = rank <= 3;

    final rankEmoji = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '$rank';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? cs.primaryContainer.withOpacity(0.4)
            : isTopThree
                ? cs.surfaceContainerHighest
                : null,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: cs.primary, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(
              rankEmoji,
              style: TextStyle(
                fontSize: isTopThree ? 24 : 16,
                fontWeight:
                    isTopThree ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.displayName,
              style: TextStyle(
                fontWeight:
                    isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Icon(Icons.assignment_outlined,
                size: 12, color: cs.outline),
            Text(' ${user.issuesReported} reported  ',
                style: TextStyle(fontSize: 11, color: cs.outline)),
            Icon(Icons.verified_outlined, size: 12, color: cs.outline),
            Text(' ${user.verificationsCompleted} verified',
                style: TextStyle(fontSize: 11, color: cs.outline)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '⚡ ${user.civicCredits}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isTopThree ? cs.primary : cs.onSurface,
              ),
            ),
            if (user.badges.isNotEmpty)
              Text(
                user.badges.take(3).map((b) => b.emoji).join(''),
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
