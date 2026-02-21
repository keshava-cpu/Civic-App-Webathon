import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/domain/models/user_profile.dart';
import 'package:civic_contribution/data/services/database_service.dart';
import 'package:civic_contribution/application/providers/issue_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/core/utils/date_utils.dart';
import 'package:civic_contribution/presentation/widgets/contributor_popup.dart';
import 'package:civic_contribution/presentation/widgets/photo_view.dart';
import 'package:civic_contribution/presentation/widgets/status_chip.dart';

/// Issue detail screen. Single responsibility: full issue information display.
class IssueDetailScreen extends StatelessWidget {
  final String issueId;
  const IssueDetailScreen({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<DatabaseService>();
    final userProvider = context.read<UserProvider>();
    final currentUserId = userProvider.currentUserId;
    final isAdmin = userProvider.isAdmin;

    return StreamBuilder<List<Issue>>(
      stream: fs.getIssuesStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final issue =
            snap.data!.where((i) => i.id == issueId).firstOrNull;
        if (issue == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Issue not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(issue.category.label),
            actions: [
              // Only admins can verify resolved issues
              if (issue.status == IssueStatus.resolved && isAdmin)
                TextButton.icon(
                  onPressed: () => context.push('/verify/${issue.id}'),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Verify'),
                ),
            ],
          ),
          body: _IssueDetailBody(
            issue: issue,
            fs: fs,
            currentUserId: currentUserId,
            isAdmin: isAdmin,
          ),
        );
      },
    );
  }
}

Widget _photoPlaceholder(ColorScheme cs) {
  return Container(
    height: 220,
    width: double.infinity,
    color: cs.surfaceContainerHighest,
    child: Icon(
      Icons.image_outlined,
      size: 48,
      color: cs.outline,
    ),
  );
}

void _openFullScreenPhoto(BuildContext context, Issue issue) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Hero(
          tag: 'issue_photo_${issue.id}',
          child: PhotoView(
            imageProvider: issue.photoUrl!.startsWith('http')
                ? NetworkImage(issue.photoUrl!) as ImageProvider
                : FileImage(File(issue.photoUrl!)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    ),
  );
}

class _IssueDetailBody extends StatelessWidget {
  final Issue issue;
  final DatabaseService fs;
  final String currentUserId;
  final bool isAdmin;

  const _IssueDetailBody({
    required this.issue,
    required this.fs,
    required this.currentUserId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photo
        if (issue.photoUrl != null)
          GestureDetector(
            onTap: () => _openFullScreenPhoto(context, issue),
            child: Hero(
              tag: 'issue_photo_${issue.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CivicPhoto(
                  url: issue.photoUrl,
                  height: 220,
                  width: double.infinity,
                  placeholder: _photoPlaceholder(cs),
                ),
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _photoPlaceholder(cs),
          ),

        const SizedBox(height: 16),

        // Status + category row
        Row(
          children: [
            Text(
              '${issue.category.emoji} ${issue.category.label}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            StatusChip(status: issue.status),
          ],
        ),
        const SizedBox(height: 8),

        // Description
        Text(issue.description,
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),

        // Location
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: cs.outline),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                issue.address.isNotEmpty
                    ? issue.address
                    : '${issue.latitude.toStringAsFixed(5)}, ${issue.longitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Time
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: cs.outline),
            const SizedBox(width: 4),
            Text(
              AppDateUtils.formatDateTime(issue.createdAt),
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Upvote + priority
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: issue.upvoterIds.contains(currentUserId)
                  ? null
                  : () async {
                      await context
                          .read<IssueProvider>()
                          .upvoteIssue(issue.id, currentUserId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Upvoted! +2 credits')),
                        );
                      }
                    },
              icon: const Icon(Icons.arrow_upward),
              label: Text('${issue.upvoterIds.length + 1} votes'),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt,
                      size: 14, color: cs.onTertiaryContainer),
                  Text(
                    ' Priority ${issue.priorityScore}',
                    style: TextStyle(
                        fontSize: 12, color: cs.onTertiaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Status timeline — read-only for regular users, interactive for admins
        _StatusTimeline(
          currentStatus: issue.status,
          issueId: issue.id,
          fs: fs,
          isAdmin: isAdmin,
        ),

        const SizedBox(height: 20),

        // Contributors
        _ContributorsSection(issue: issue, fs: fs),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _photoPlaceholder(ColorScheme cs) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, size: 64, color: cs.outline),
      ),
    );
  }
}

/// Status timeline. Read-only for regular users; tappable for admins.
/// Single responsibility: status progression display + admin-only update.
class _StatusTimeline extends StatelessWidget {
  final IssueStatus currentStatus;
  final String issueId;
  final DatabaseService fs;
  final bool isAdmin;

  const _StatusTimeline({
    required this.currentStatus,
    required this.issueId,
    required this.fs,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = IssueStatus.values;
    final cs = Theme.of(context).colorScheme;
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Status Timeline',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: statuses.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isPast = i <= currentIndex;
            final isNext = i == currentIndex + 1;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: (isAdmin && isNext)
                          ? () async {
                              await fs.updateIssueStatus(issueId, s.value);
                            }
                          : null,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            width: 28,
                            height: 28,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPast
                                  ? cs.primary
                                  : cs.surfaceContainerHighest,
                              border: Border.all(
                                color: i == currentIndex
                                    ? cs.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isPast
                                  ? Icon(Icons.check,
                                      size: 14, color: cs.onPrimary)
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: cs.outline),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 9,
                              color: isPast ? cs.primary : cs.outline,
                              fontWeight: isPast
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < statuses.length - 1)
                    Container(
                      height: 2,
                      width: 8,
                      color: i < currentIndex
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        if (!isAdmin)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Status updates are managed by local authorities.',
              style: TextStyle(fontSize: 11, color: cs.outline),
            ),
          ),
      ],
    );
  }
}

class _ContributorsSection extends StatelessWidget {
  final Issue issue;
  final DatabaseService fs;

  const _ContributorsSection({required this.issue, required this.fs});

  @override
  Widget build(BuildContext context) {
    final allContributorIds = {
      issue.reporterId,
      ...issue.upvoterIds,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Contributors',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (issue.status == IssueStatus.verified)
              TextButton.icon(
                onPressed: () async {
                  final profiles = await Future.wait(
                    allContributorIds.map((id) => fs.getUser(id)),
                  );
                  final valid =
                      profiles.whereType<UserProfile>().toList();
                  if (context.mounted) {
                    ContributorPopup.show(
                      context,
                      contributors: valid,
                      issueTitle:
                          '${issue.category.emoji} ${issue.category.label}',
                    );
                  }
                },
                icon: const Icon(Icons.celebration_outlined, size: 16),
                label: const Text('Celebrate'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allContributorIds.take(10).map((uid) {
            return FutureBuilder<UserProfile?>(
              future: fs.getUser(uid),
              builder: (context, snap) {
                final user = snap.data;
                final name = user?.displayName ?? uid;
                final cs = Theme.of(context).colorScheme;
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(name[0],
                        style: const TextStyle(fontSize: 10)),
                  ),
                  label: Text(name,
                      style: const TextStyle(fontSize: 12)),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
