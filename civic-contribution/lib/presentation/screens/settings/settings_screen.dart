import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/application/providers/account_management_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';

/// Single responsibility: settings UI for community and account management.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final accountProvider = context.watch<AccountManagementProvider>();
    final cs = Theme.of(context).colorScheme;
    final isAdmin = userProvider.isAdmin;
    final communityId = userProvider.communityId;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: accountProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Community section ──────────────────────────────────
                Text('Community',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.group_outlined),
                        title: Text(communityId ?? 'None'),
                        subtitle: const Text('Current community'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.swap_horiz,
                            color: cs.primary),
                        title: const Text('Switch Community'),
                        subtitle: const Text(
                            'Leave current and pick a new community'),
                        onTap: communityId == null
                            ? null
                            : () => _confirmAction(
                                  context,
                                  title: 'Switch Community',
                                  message:
                                      'You will leave your current community '
                                      'and be taken to the community selection '
                                      'screen. Your admin status (if any) will '
                                      'be removed.\n\nContinue?',
                                  confirmLabel: 'Switch',
                                  onConfirm: () async {
                                    final success =
                                        await accountProvider.leaveCommunity();
                                    if (context.mounted && !success) {
                                      _showError(context,
                                          accountProvider.error);
                                    }
                                    // Router redirect handles navigation.
                                  },
                                ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.exit_to_app,
                            color: Colors.orange.shade700),
                        title: const Text('Leave Community'),
                        subtitle: const Text(
                            'Remove yourself from this community'),
                        onTap: communityId == null
                            ? null
                            : () => _confirmAction(
                                  context,
                                  title: 'Leave Community',
                                  message:
                                      'You will be removed from this community. '
                                      'Your admin status (if any) will be '
                                      'cleared.\n\nYou can join another '
                                      'community afterwards.',
                                  confirmLabel: 'Leave',
                                  isDestructive: true,
                                  onConfirm: () async {
                                    final success =
                                        await accountProvider.leaveCommunity();
                                    if (context.mounted && !success) {
                                      _showError(context,
                                          accountProvider.error);
                                    }
                                  },
                                ),
                      ),
                      if (isAdmin) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading:
                              Icon(Icons.delete_forever, color: cs.error),
                          title: const Text('Delete Community'),
                          subtitle: const Text(
                              'Permanently delete this community '
                              'and remove all members'),
                          onTap: () => _confirmAction(
                            context,
                            title: 'Delete Community',
                            message:
                                'This will permanently delete the community '
                                'and remove all members from it. '
                                'Reported issues will be preserved.\n\n'
                                'This action cannot be undone.',
                            confirmLabel: 'Delete Community',
                            isDestructive: true,
                            onConfirm: () async {
                              final success =
                                  await accountProvider.deleteCommunity();
                              if (context.mounted && !success) {
                                _showError(context, accountProvider.error);
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Account section ──────────────────────────────────
                Text('Account',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(
                            userProvider.currentUserProfile?.displayName ??
                                'User'),
                        subtitle: Text(
                            userProvider.authUser?.email ?? 'No email'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            Icon(Icons.delete_outline, color: cs.error),
                        title: Text('Delete Account',
                            style: TextStyle(color: cs.error)),
                        subtitle: const Text(
                            'Permanently delete your account and all data'),
                        onTap: () => _confirmAction(
                          context,
                          title: 'Delete Account',
                          message:
                              'This will permanently delete your account, '
                              'remove you from your community, and delete all '
                              'your profile data.\n\n'
                              'This action cannot be undone.',
                          confirmLabel: 'Delete My Account',
                          isDestructive: true,
                          onConfirm: () async {
                            final success =
                                await accountProvider.deleteAccount();
                            if (context.mounted && !success) {
                              _showError(context, accountProvider.error);
                            }
                            // Auth deletion auto-signs out → router
                            // redirect handles navigation to /login.
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (accountProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: cs.errorContainer,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: cs.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              accountProvider.error!,
                              style:
                                  TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
    bool isDestructive = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: cs.error)
                : null,
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String? error) {
    if (error == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
  }
}
