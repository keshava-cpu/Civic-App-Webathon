import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/application/providers/issue_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/core/utils/date_utils.dart';
import 'package:civic_contribution/core/utils/geo_utils.dart';
import 'package:civic_contribution/presentation/widgets/photo_view.dart';
import 'status_chip.dart';

/// Card shown in the dashboard feed. Single responsibility: issue summary display.
/// Shows image thumbnail (if available), upvote button, status, and meta info.
/// Tapping the card navigates to IssueDetailScreen.
class IssueCard extends StatelessWidget {
  final Issue issue;
  final double? userLat;
  final double? userLon;

  const IssueCard({
    super.key,
    required this.issue,
    this.userLat,
    this.userLon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentUserId = context.read<UserProvider>().currentUserId;
    final hasUpvoted = issue.upvoterIds.contains(currentUserId);

    String? distanceText;
    if (userLat != null && userLon != null) {
      final meters = GeoUtils.distanceInMeters(
        userLat!,
        userLon!,
        issue.location.latitude,
        issue.location.longitude,
      );
      distanceText = GeoUtils.formatDistance(meters);
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/issue/${issue.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image thumbnail — only shown when a photo exists
            if (issue.photoUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CivicPhoto(
                  url: issue.photoUrl,
                  height: 140,
                  width: double.infinity,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon (only shown when no photo)
                  if (issue.photoUrl == null)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          issue.category.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  if (issue.photoUrl == null) const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            if (issue.photoUrl != null)
                              Text(
                                issue.category.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            if (issue.photoUrl != null)
                              const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                issue.category.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            StatusChip(status: issue.status, small: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Description
                        Text(
                          issue.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Location row
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: cs.outline),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                issue.address.isNotEmpty
                                    ? issue.address
                                    : '${issue.location.latitude.toStringAsFixed(4)}, ${issue.location.longitude.toStringAsFixed(4)}',
                                style: TextStyle(
                                    fontSize: 10, color: cs.outline),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (distanceText != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: cs.primary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Meta + upvote row
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: cs.outline),
                            Text(
                              ' ${AppDateUtils.timeAgo(issue.createdAt)}',
                              style:
                                  TextStyle(fontSize: 11, color: cs.outline),
                            ),
                            const Spacer(),
                            // Upvote button
                            _UpvoteButton(
                              issue: issue,
                              hasUpvoted: hasUpvoted,
                              currentUserId: currentUserId,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline upvote button for IssueCard.
/// Single responsibility: upvote action and count display only.
class _UpvoteButton extends StatelessWidget {
  final Issue issue;
  final bool hasUpvoted;
  final String currentUserId;

  const _UpvoteButton({
    required this.issue,
    required this.hasUpvoted,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final issueProvider = context.read<IssueProvider>();

    return GestureDetector(
      onTap: hasUpvoted
          ? null
          : () async {
              await issueProvider.upvoteIssue(issue.id, currentUserId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upvoted! +2 credits'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
            size: 14,
            color: hasUpvoted ? cs.primary : cs.outline,
          ),
          const SizedBox(width: 2),
          Text(
            '${issue.upvoterIds.length + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasUpvoted ? cs.primary : cs.outline,
            ),
          ),
        ],
      ),
    );
  }
}
