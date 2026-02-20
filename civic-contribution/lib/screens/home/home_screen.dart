import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/issue_provider.dart';
import '../../providers/report_flow_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/mock_auth_service.dart';
import '../../widgets/issue_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    if (_seeded) return;
    _seeded = true;
    final fs = context.read<FirestoreService>();
    await fs.seedDemoData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicPulse',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _UserSwitcher(),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Leaderboard',
            onPressed: () => context.push('/leaderboard'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: const [
          _FeedTab(),
          _ProfileTab(),
        ],
      ),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                context.read<ReportFlowProvider>().reset();
                context.push('/report/camera');
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Report Issue'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex == 0 ? 0 : 2,
        onDestinationSelected: (i) {
          if (i == 1) {
            context.push('/map');
          } else {
            setState(() => _navIndex = i == 0 ? 0 : 1);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _UserSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentMockUser;
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Switch User',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              child: Text(
                currentUser.displayName[0],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (_) => MockAuthService.mockUsers
          .map(
            (u) => PopupMenuItem(
              value: u.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: cs.primaryContainer,
                    child: Text(u.displayName[0],
                        style: const TextStyle(fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(u.displayName)),
                  if (u.id == userProvider.currentUserId)
                    const Icon(Icons.check, size: 16),
                ],
              ),
            ),
          )
          .toList(),
      onSelected: (userId) => userProvider.switchUser(userId),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    final issueProvider = context.watch<IssueProvider>();
    final issues = issueProvider.filteredIssues;

    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              FilterChip(
                label: const Text('All'),
                selected: issueProvider.statusFilter == null &&
                    issueProvider.categoryFilter == null,
                onSelected: (_) => issueProvider.clearFilters(),
              ),
              const SizedBox(width: 8),
              ...IssueStatus.values.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.label),
                    selected: issueProvider.statusFilter == s,
                    onSelected: (v) =>
                        issueProvider.setStatusFilter(v ? s : null),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Issues list
        Expanded(
          child: issueProvider.loading
              ? const Center(child: CircularProgressIndicator())
              : issues.isEmpty
                  ? _EmptyState(
                      hasFilter: issueProvider.statusFilter != null ||
                          issueProvider.categoryFilter != null,
                      onClear: issueProvider.clearFilters,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {},
                      child: ListView.builder(
                        itemCount: issues.length,
                        itemBuilder: (context, index) =>
                            IssueCard(issue: issues[index]),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'No issues match the filter'
                  : 'No issues reported yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (hasFilter)
              TextButton(onPressed: onClear, child: const Text('Clear filter'))
            else
              Text(
                'Tap the button below to report one!',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final cs = Theme.of(context).colorScheme;

    // Refresh live from Firestore each time profile tab is shown
    if (userProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = userProvider.currentUserProfile;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            const Text('Profile unavailable'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: userProvider.refreshCurrentUser,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final trustColor = user.trustScore >= 0.8
        ? Colors.green
        : user.trustScore >= 0.5
            ? Colors.orange
            : Colors.red;

    final nextBadgeCredits = user.civicCredits < 50
        ? 50
        : user.civicCredits < 200
            ? 200
            : user.civicCredits < 500
                ? 500
                : null;
    final progressValue = nextBadgeCredits == null
        ? 1.0
        : user.civicCredits / nextBadgeCredits;

    return RefreshIndicator(
      onRefresh: userProvider.refreshCurrentUser,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── Avatar + name ────────────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          user.displayName[0],
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      if (user.badges.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.outline, width: 1),
                            ),
                            child: Center(
                              child: Text(user.badges.last.emoji,
                                  style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  // Trust score pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: trustColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: trustColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: trustColor),
                        const SizedBox(width: 4),
                        Text(
                          'Trust Score: ${(user.trustScore * 100).toInt()}%',
                          style: TextStyle(
                              color: trustColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Credits + progress ───────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Civic Credits',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '⚡ ${user.civicCredits}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (nextBadgeCredits != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressValue.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${nextBadgeCredits - user.civicCredits} credits to next badge',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Stats row
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            icon: Icons.report_outlined,
                            value: '${user.issuesReported}',
                            label: 'Reported',
                            color: Colors.blue,
                          ),
                        ),
                        VerticalDivider(
                            color: cs.outlineVariant, width: 1),
                        Expanded(
                          child: _StatBox(
                            icon: Icons.verified_outlined,
                            value: '${user.verificationsCompleted}',
                            label: 'Verified',
                            color: Colors.green,
                          ),
                        ),
                        VerticalDivider(
                            color: cs.outlineVariant, width: 1),
                        Expanded(
                          child: _StatBox(
                            icon: Icons.task_alt_outlined,
                            value: '${user.tasksCompleted}',
                            label: 'Tasks',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Badges ───────────────────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Badges',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (user.badges.isEmpty)
                    Row(
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            color: cs.outline, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Earn 50 credits to unlock your first badge!',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.badges.map((b) {
                        return Chip(
                          avatar: Text(b.emoji,
                              style: const TextStyle(fontSize: 16)),
                          label: Text(b.label),
                          backgroundColor: cs.secondaryContainer,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── How to earn more ─────────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to Earn Credits',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _EarnRow(
                      icon: Icons.camera_alt_outlined,
                      label: 'Report an issue',
                      points: '+10',
                      color: Colors.blue),
                  _EarnRow(
                      icon: Icons.arrow_upward,
                      label: 'Upvote an issue',
                      points: '+2',
                      color: Colors.orange),
                  _EarnRow(
                      icon: Icons.verified_outlined,
                      label: 'Verify a resolved issue',
                      points: '+15',
                      color: Colors.green),
                  _EarnRow(
                      icon: Icons.task_alt_outlined,
                      label: 'Complete a micro-task',
                      points: '+5',
                      color: Colors.purple),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Quick actions ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/map'),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('View Map'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/leaderboard'),
                  icon: const Icon(Icons.leaderboard_outlined),
                  label: const Text('Leaderboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatBox(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String points;
  final Color color;
  const _EarnRow(
      {required this.icon,
      required this.label,
      required this.points,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13))),
          Text(points,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
