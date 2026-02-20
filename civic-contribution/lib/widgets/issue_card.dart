import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';
import '../models/issue.dart';
import '../utils/date_utils.dart';
import '../utils/geo_utils.dart';
import 'status_chip.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                    Text(
                      issue.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 12, color: cs.outline),
                        Text(
                          ' ${issue.upvoterIds.length + 1}',
                          style: TextStyle(fontSize: 11, color: cs.outline),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: 12, color: cs.outline),
                        Text(
                          ' ${AppDateUtils.timeAgo(issue.createdAt)}',
                          style: TextStyle(fontSize: 11, color: cs.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
