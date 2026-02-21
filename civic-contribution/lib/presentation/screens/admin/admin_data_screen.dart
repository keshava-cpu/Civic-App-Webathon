import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/application/providers/admin_data_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/presentation/widgets/archive_progress_dialog.dart';

/// Admin community data table with export.
class AdminDataScreen extends StatefulWidget {
  const AdminDataScreen({super.key});

  @override
  State<AdminDataScreen> createState() => _AdminDataScreenState();
}

class _AdminDataScreenState extends State<AdminDataScreen> {
  @override
  void initState() {
    super.initState();
    final communityId = context.read<UserProvider>().communityId;
    if (communityId != null) {
      context.read<AdminDataProvider>().subscribeToIssues(communityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDataProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          if (provider.exporting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<String>(
              enabled: provider.issues.isNotEmpty && !provider.exporting,
              onSelected: (value) {
                if (value == 'csv') provider.exportCsv();
                if (value == 'images') provider.exportWithImages();
                if (value == 'archive') {
                  ArchiveProgressDialog.show(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'csv', child: Text('Export CSV only')),
                const PopupMenuItem(value: 'images', child: Text('Export CSV + Images')),
                const PopupMenuItem(value: 'archive', child: Text('Download Archive (ZIP)')),
              ],
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export',
            ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.issues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: cs.outline),
                      const SizedBox(height: 16),
                      const Text('No issues in this community yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: provider.issues.length,
                  itemBuilder: (context, index) {
                    final issue = provider.issues[index];
                    return _IssueRow(issue: issue);
                  },
                ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final Issue issue;
  const _IssueRow({required this.issue});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shortId =
        issue.id.length > 8 ? issue.id.substring(0, 8) : issue.id;

    Color statusColor;
    switch (issue.status) {
      case IssueStatus.pending:
        statusColor = Colors.orange;
        break;
      case IssueStatus.assigned:
        statusColor = Colors.blue;
        break;
      case IssueStatus.inProgress:
        statusColor = Colors.indigo;
        break;
      case IssueStatus.resolved:
        statusColor = Colors.green;
        break;
      case IssueStatus.verified:
        statusColor = Colors.teal;
        break;
    }

    return ListTile(
      leading: Text(issue.category.emoji, style: const TextStyle(fontSize: 24)),
      title: Row(
        children: [
          Text(shortId,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              issue.status.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
          if (issue.photoUrl != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.image_outlined, size: 16, color: cs.onSurfaceVariant),
          ],
        ],
      ),
      subtitle: Text(
        issue.address.isNotEmpty
            ? issue.address
            : '${issue.latitude.toStringAsFixed(4)}, ${issue.longitude.toStringAsFixed(4)}',
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => context.push('/issue/${issue.id}'),
    );
  }
}
