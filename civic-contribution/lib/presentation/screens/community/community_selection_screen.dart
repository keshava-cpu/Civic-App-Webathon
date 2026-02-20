import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/application/providers/community_provider.dart';
import 'package:civic_contribution/application/providers/issue_provider.dart';
import 'package:civic_contribution/application/providers/leaderboard_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/domain/models/community.dart';
import 'package:civic_contribution/presentation/config/routes.dart';

/// Community search/select/create UI + role picker bottom sheet.
class CommunitySelectionScreen extends StatefulWidget {
  const CommunitySelectionScreen({super.key});

  @override
  State<CommunitySelectionScreen> createState() =>
      _CommunitySelectionScreenState();
}

class _CommunitySelectionScreenState extends State<CommunitySelectionScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        context.read<CommunityProvider>().searchCommunities(query.trim());
      }
    });
  }

  Future<void> _selectCommunity(Community community) async {
    final userProvider = context.read<UserProvider>();
    final communityProvider = context.read<CommunityProvider>();
    await communityProvider.selectCommunity(
        community, userProvider.currentUserId);
    if (!mounted) return;
    _showRolePicker(community.id, community.name);
  }

  Future<void> _createCommunity() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Community'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Community Name',
            hintText: 'e.g. Koramangala Ward 68',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final userProvider = context.read<UserProvider>();
    final communityProvider = context.read<CommunityProvider>();
    final community =
        await communityProvider.createCommunity(name, userProvider.currentUserId);
    if (community != null && mounted) {
      _showRolePicker(community.id, community.name);
    }
  }

  void _showRolePicker(String communityId, String communityName) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome to $communityName!',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('How would you like to join?'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final userProvider = context.read<UserProvider>();
                  await userProvider.setCommunity(communityId);
                  if (!mounted) return;
                  context
                      .read<IssueProvider>()
                      .reinitialize(communityId);
                  context
                      .read<LeaderboardProvider>()
                      .reinitialize(communityId);
                  context.go(AppRoutes.home);
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue as Citizen'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final userProvider = context.read<UserProvider>();
                  await userProvider.setCommunity(communityId);
                  await userProvider.setAdminFlag();
                  if (!mounted) return;
                  await context.read<CommunityProvider>().grantAdmin(
                      communityId, userProvider.currentUserId);
                  if (!mounted) return;
                  context
                      .read<IssueProvider>()
                      .reinitialize(communityId);
                  context
                      .read<LeaderboardProvider>()
                      .reinitialize(communityId);
                  context.go(AppRoutes.home);
                },
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Join as Admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityProvider = context.watch<CommunityProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () => context.read<UserProvider>().signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Search for your ward or community to get started.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search communities',
                hintText: 'e.g. Koramangala',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: communityProvider.loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            if (communityProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(communityProvider.error!,
                    style: TextStyle(color: cs.error)),
              ),
            Expanded(
              child: communityProvider.searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_city_outlined,
                              size: 64, color: cs.outline),
                          const SizedBox(height: 16),
                          Text('Start typing to search communities',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: communityProvider.searchResults.length,
                      itemBuilder: (context, index) {
                        final community =
                            communityProvider.searchResults[index];
                        return ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.location_city)),
                          title: Text(community.name),
                          subtitle: Text(
                              '${community.memberCount} member${community.memberCount != 1 ? 's' : ''}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectCommunity(community),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _createCommunity,
              icon: const Icon(Icons.add),
              label: const Text('Create New Community'),
            ),
          ],
        ),
      ),
    );
  }
}
