import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/application/providers/issue_provider.dart';
import 'package:civic_contribution/application/providers/report_flow_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/presentation/config/routes.dart';
import 'package:civic_contribution/presentation/screens/leaderboard/leaderboard_screen.dart';
import 'package:civic_contribution/presentation/screens/map/map_screen.dart';
import 'package:civic_contribution/presentation/widgets/badge_icon.dart';
import 'package:civic_contribution/presentation/widgets/issue_card.dart';

/// Shell screen with bottom navigation bar.
/// Single responsibility: tab switching and FAB visibility only.
/// Each tab is a separate widget with its own responsibility.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  static const _tabs = [
    _FeedTab(),
    MapScreen(),
    LeaderboardScreen(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _navIndex == 1 || _navIndex == 2
          ? null // Map and Leaderboard have their own AppBars
          : AppBar(
              title: Text(
                _navIndex == 0 ? 'CivicPulse' : 'Profile',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (_navIndex == 3)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () => context.push(AppRoutes.settings),
                  ),
                IconButton(
                  icon: const Icon(Icons.logout_outlined),
                  tooltip: 'Sign out',
                  onPressed: () async {
                    await context.read<UserProvider>().signOut();
                  },
                ),
              ],
            ),
      body: IndexedStack(
        index: _navIndex,
        children: _tabs,
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
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
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
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contributors',
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

/// Feed tab. Single responsibility: issue list with filter chips.
class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    final issueProvider = context.watch<IssueProvider>();
    final issues = issueProvider.filteredIssues;

    return Column(
      children: [
        // Status filter chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              FilterChip(
                label: const Text('Active'),
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
                  ? _EmptyFeedState(
                      hasFilter: issueProvider.statusFilter != null ||
                          issueProvider.categoryFilter != null,
                      onClear: issueProvider.clearFilters,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {},
                      child: ListView.builder(
                        itemCount: issues.length,
                        itemBuilder: (context, index) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 300 + (index * 60).clamp(0, 500),
                            ),
                            curve: Curves.easeOut,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            ),
                            child: IssueCard(issue: issues[index]),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

/// Empty state for feed. Single responsibility: empty/no-results display only.
class _EmptyFeedState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyFeedState({required this.hasFilter, required this.onClear});

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
              TextButton(
                  onPressed: onClear, child: const Text('Clear filter'))
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

/// Profile tab. Single responsibility: current user profile display.
/// Does NOT show trust score (internal metric, not for self-display).
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final cs = Theme.of(context).colorScheme;

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
          // Avatar + name (no trust score shown to self)
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
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.displayName[0],
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      if (user.badges.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: cs.outline, width: 1),
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Credits + progress
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
                          style:
                              Theme.of(context).textTheme.titleMedium),
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
                  // Stats row — Reported and Verified only
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Admin navigation buttons
          if (userProvider.isAdmin) ...[            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Admin',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.adminData),
                      icon: const Icon(Icons.dashboard_outlined),
                      label: const Text('Admin Dashboard'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Badges — emoji icons with tooltip on hold (no label text beside icon)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Badges',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
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
                            style:
                                TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    )
                  else
                    // BadgeIcon shows tooltip (badge name) on long-press/hover
                    // No text label rendered beside the icon
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: user.badges
                          .map((b) => BadgeIcon(badge: b, size: 28))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat display box. Single responsibility: one stat (icon + value + label).
class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

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
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
