import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/application/providers/issue_provider.dart';
import 'package:civic_contribution/data/services/location_service.dart';
import 'package:civic_contribution/presentation/widgets/map/map_widget.dart';
import 'package:civic_contribution/presentation/widgets/status_chip.dart';
import 'package:civic_contribution/core/utils/date_utils.dart';
import 'package:civic_contribution/presentation/widgets/photo_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _defaultCenter = LatLng(12.9716, 77.5946);

  IssueStatus? _statusFilter;
  IssueCategory? _categoryFilter;
  bool _locating = false;
  LatLng? _userLocation;
  LatLng _stableCenter = _defaultCenter;
  bool _centeredOnLatestIssue = false;

  List<Issue> _applyFilters(List<Issue> all) {
    return all.where((i) {
      if (_statusFilter != null && i.status != _statusFilter) return false;
      if (_categoryFilter != null && i.category != _categoryFilter) return false;
      return true;
    }).toList();
  }

  void _jumpToNearestIssue(List<Issue> filteredIssues) {
    if (filteredIssues.isEmpty) return;
    // Find the issue closest to current center
    Issue nearest = filteredIssues.first;
    double minDist = double.infinity;
    for (final issue in filteredIssues) {
      if (!issue.hasValidLocation) continue;
      final dlat = issue.latitude - _stableCenter.latitude;
      final dlon = issue.longitude - _stableCenter.longitude;
      final dist = dlat * dlat + dlon * dlon; // squared distance is enough for comparison
      if (dist < minDist) {
        minDist = dist;
        nearest = issue;
      }
    }
    if (nearest.hasValidLocation) {
      setState(() {
        _stableCenter = LatLng(
          nearest.latitude,
          nearest.longitude,
        );
      });
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    final pos = await context.read<LocationService>().getCurrentPosition();
    if (mounted && pos != null) {
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _stableCenter = _userLocation!;
        _locating = false;
      });
    } else {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueProvider = context.watch<IssueProvider>();
    final allIssues = issueProvider.allIssues;

    // On first load, center map on the latest reported issue if available.
    if (!_centeredOnLatestIssue) {
      final latest = issueProvider.latestReportedIssue;
      if (latest != null && latest.hasValidLocation) {
        _stableCenter = LatLng(
          latest.latitude,
          latest.longitude,
        );
        _centeredOnLatestIssue = true;
      }
    }

    final filtered = _applyFilters(allIssues);
    
    // Filter only valid locations for display
    final validIssues = filtered.where((i) => i.hasValidLocation).toList();
    final hasActiveFilter = _statusFilter != null || _categoryFilter != null;
    final showNoResultsOverlay =
      !issueProvider.loading && hasActiveFilter && validIssues.isEmpty;
    
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Issues Map', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${validIssues.length} issue${validIssues.length != 1 ? 's' : ''} visible',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          // Category filter button
          IconButton(
            icon: Badge(
              isLabelVisible: _categoryFilter != null,
              label: const Text('1'),
              child: const Icon(Icons.category_outlined),
            ),
            tooltip: 'Filter by category',
            onPressed: () => _showCategoryFilter(context),
          ),
          // Legend
          IconButton(
            icon: const Icon(Icons.legend_toggle_outlined),
            tooltip: 'Legend',
            onPressed: () => _showLegend(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          issueProvider.loading
              ? const Center(child: CircularProgressIndicator())
              : MapWidget(
                  center: _stableCenter,
                  zoom: 14.0,
                  issues: validIssues,
                  onMarkerTap: (issue) => _showIssueSheet(context, issue),
                ),

          if (showNoResultsOverlay)
            Positioned(
              top: 56,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _emptyFilterMessage(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),

          // Status filter chips — horizontal scroll at top
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: _StatusFilterBar(
              selected: _statusFilter,
              onSelected: (s) {
                final newFilter = _statusFilter == s ? null : s;
                setState(() => _statusFilter = newFilter);
                if (newFilter != null) {
                  final filtered = _applyFilters(allIssues)
                      .where((i) => i.hasValidLocation)
                      .toList();
                  _jumpToNearestIssue(filtered);
                }
              },
            ),
          ),

          // Issue count summary cards at bottom-left
          Positioned(
            bottom: 16,
            left: 16,
            child: _SummaryBadges(issues: validIssues),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Report FAB
          FloatingActionButton.small(
            heroTag: 'report',
            onPressed: () => context.push('/report/camera'),
            tooltip: 'Report new issue',
            child: const Icon(Icons.add_a_photo_outlined),
          ),
          const SizedBox(height: 8),
          // My location FAB
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _locating ? null : _goToMyLocation,
            tooltip: 'My location',
            child: _locating
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _userLocation != null
                        ? Icons.my_location
                        : Icons.location_searching,
                  ),
          ),
        ],
      ),
    );
  }

  String _emptyFilterMessage() {
    final statusLabel = _statusFilter?.label;
    final categoryLabel = _categoryFilter?.label;

    if (statusLabel != null && categoryLabel != null) {
      return 'No $statusLabel $categoryLabel issues found';
    }
    if (statusLabel != null) {
      return 'No $statusLabel issues found';
    }
    if (categoryLabel != null) {
      return 'No $categoryLabel issues found';
    }
    return 'No matching issues found';
  }

  void _showIssueSheet(BuildContext context, Issue issue) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            // Drag handle
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Photo
            if (issue.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CivicPhoto(
                  url: issue.photoUrl,
                  height: 160,
                  width: double.infinity,
                ),
              ),
            if (issue.photoUrl != null) const SizedBox(height: 12),

            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(issue.category.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.category.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      StatusChip(status: issue.status, small: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(issue.description,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),

            // Address
            if (issue.address.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(issue.address,
                        style: TextStyle(fontSize: 12, color: cs.outline)),
                  ),
                ],
              ),
            const SizedBox(height: 4),

            // Meta row
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: cs.outline),
                Text(' ${AppDateUtils.timeAgo(issue.createdAt)}',
                    style: TextStyle(fontSize: 12, color: cs.outline)),
                const SizedBox(width: 16),
                Icon(Icons.arrow_upward, size: 14, color: cs.outline),
                Text(' ${issue.upvoterIds.length + 1} votes',
                    style: TextStyle(fontSize: 12, color: cs.outline)),
                const SizedBox(width: 16),
                Icon(Icons.bolt, size: 14, color: cs.tertiary),
                Text(' Priority ${issue.priorityScore}',
                    style: TextStyle(fontSize: 12, color: cs.tertiary)),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/issue/${issue.id}');
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View Details'),
                  ),
                ),
                if (issue.status == IssueStatus.resolved) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/verify/${issue.id}');
                      },
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Verify'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter by Category',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    setState(() => _categoryFilter = null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IssueCategory.values.map((cat) {
                final selected = _categoryFilter == cat;
                return FilterChip(
                  label: Text('${cat.emoji} ${cat.label}'),
                  selected: selected,
                  onSelected: (_) {
                    setState(() =>
                        _categoryFilter = selected ? null : cat);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...[
              (IssueStatus.pending, Colors.orange, 'Awaiting assignment'),
              (IssueStatus.assigned, Colors.blue, 'Assigned to official'),
              (IssueStatus.inProgress, Colors.purple, 'Being fixed'),
              (IssueStatus.resolved, Colors.teal, 'Fixed, needs verification'),
              (IssueStatus.verified, Colors.green, 'Community verified'),
            ].map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: e.$2,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(e.$1.label,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(e.$3,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.outline)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

// ── Status filter chips bar ───────────────────────────────────────────────────
class _StatusFilterBar extends StatelessWidget {
  final IssueStatus? selected;
  final ValueChanged<IssueStatus> onSelected;

  const _StatusFilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: IssueStatus.values.map((s) {
          final isSelected = selected == s;
          final color = _colorFor(s);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelected(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _colorFor(IssueStatus s) {
    switch (s) {
      case IssueStatus.pending: return Colors.orange;
      case IssueStatus.assigned: return Colors.blue;
      case IssueStatus.inProgress: return Colors.purple;
      case IssueStatus.resolved: return Colors.teal;
      case IssueStatus.verified: return Colors.green;
    }
  }
}

// ── Summary count badges ──────────────────────────────────────────────────────
class _SummaryBadges extends StatelessWidget {
  final List<Issue> issues;
  const _SummaryBadges({required this.issues});

  @override
  Widget build(BuildContext context) {
    final counts = <IssueStatus, int>{};
    for (final i in issues) {
      counts[i.status] = (counts[i.status] ?? 0) + 1;
    }
    final active = counts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: active.take(5).map((e) {
          final color = _colorFor(e.key);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 4),
                Text('${e.value}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _colorFor(IssueStatus s) {
    switch (s) {
      case IssueStatus.pending: return Colors.orange;
      case IssueStatus.assigned: return Colors.blue;
      case IssueStatus.inProgress: return Colors.purple;
      case IssueStatus.resolved: return Colors.teal;
      case IssueStatus.verified: return Colors.green;
    }
  }
}

