import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../models/issue.dart';
import '../../models/micro_task.dart';
import '../../models/user_profile.dart';
import '../../services/credits_service.dart';
import '../../services/firestore_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/contributor_popup.dart';
import '../../widgets/micro_task_tile.dart';
import '../../widgets/photo_view.dart';
import '../../widgets/status_chip.dart';

class IssueDetailScreen extends StatefulWidget {
  final String issueId;
  const IssueDetailScreen({super.key, required this.issueId});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final credits = context.read<CreditsService>();
    final userProvider = context.read<UserProvider>();
    final currentUserId = userProvider.currentUserId;
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<Issue>>(
      stream: fs.getIssuesStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final issue = snap.data!.where((i) => i.id == widget.issueId).firstOrNull;
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
              if (issue.status == IssueStatus.resolved)
                TextButton.icon(
                  onPressed: () => context.push('/verify/${issue.id}'),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Verify'),
                ),
            ],
          ),
          body: _buildBody(context, issue, fs, credits, currentUserId, cs),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    Issue issue,
    FirestoreService fs,
    CreditsService credits,
    String currentUserId,
    ColorScheme cs,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photo
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CivicPhoto(
            url: issue.photoUrl,
            height: 220,
            width: double.infinity,
            placeholder: _photoPlaceholder(cs),
          ),
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
        Text(issue.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),

        // Location + time
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: cs.outline),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                issue.address.isNotEmpty
                    ? issue.address
                    : '${issue.location.latitude.toStringAsFixed(5)}, ${issue.location.longitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
                      await fs.upvoteIssue(issue.id, currentUserId);
                      await credits.awardUpvote(currentUserId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Upvoted! +2 credits')),
                        );
                      }
                    },
              icon: const Icon(Icons.arrow_upward),
              label: Text(
                  '${issue.upvoterIds.length + 1} votes'),
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
                  Icon(Icons.bolt, size: 14, color: cs.onTertiaryContainer),
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

        // Status timeline
        _StatusTimeline(currentStatus: issue.status, issueId: issue.id, fs: fs),

        const SizedBox(height: 20),

        // Micro-tasks section
        _MicroTasksSection(
          issue: issue,
          fs: fs,
          credits: credits,
          currentUserId: currentUserId,
          taskController: _taskController,
        ),

        const SizedBox(height: 20),

        // Contributors section
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

class _StatusTimeline extends StatelessWidget {
  final IssueStatus currentStatus;
  final String issueId;
  final FirestoreService fs;

  const _StatusTimeline({
    required this.currentStatus,
    required this.issueId,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = IssueStatus.values;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status Timeline',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: statuses.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final currentIndex = statuses.indexOf(currentStatus);
            final isPast = i <= currentIndex;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isPast || i > currentIndex + 1
                          ? null
                          : () async {
                              await fs.updateIssueStatus(issueId, s.value);
                            },
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPast ? cs.primary : cs.surfaceContainerHighest,
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
                                          fontSize: 10, color: cs.outline),
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
                      color: i < statuses.indexOf(currentStatus)
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MicroTasksSection extends StatelessWidget {
  final Issue issue;
  final FirestoreService fs;
  final CreditsService credits;
  final String currentUserId;
  final TextEditingController taskController;

  const _MicroTasksSection({
    required this.issue,
    required this.fs,
    required this.credits,
    required this.currentUserId,
    required this.taskController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Micro-Tasks',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<List<MicroTask>>(
          stream: fs.getMicroTasksStream(issue.id),
          builder: (context, snap) {
            final tasks = snap.data ?? [];
            return Column(
              children: [
                ...tasks.map((t) => MicroTaskTile(
                      task: t,
                      currentUserId: currentUserId,
                      firestoreService: fs,
                      creditsService: credits,
                    )),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No tasks yet. Add one below.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: taskController,
                decoration: const InputDecoration(
                  hintText: 'Add a micro-task...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () async {
                final title = taskController.text.trim();
                if (title.isEmpty) return;
                final task = MicroTask(
                  id: '',
                  issueId: issue.id,
                  title: title,
                  completed: false,
                );
                await fs.addMicroTask(issue.id, task);
                taskController.clear();
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContributorsSection extends StatelessWidget {
  final Issue issue;
  final FirestoreService fs;

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
            Text('Contributors',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
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
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
