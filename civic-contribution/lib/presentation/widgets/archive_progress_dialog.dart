import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/application/providers/archive_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';

/// Single responsibility: archive progress dialog with options.
class ArchiveProgressDialog extends StatelessWidget {
  const ArchiveProgressDialog({super.key});

  /// Show the dialog: first let user pick scope, then track progress.
  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ArchiveProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archiveProvider = context.watch<ArchiveProvider>();
    final cs = Theme.of(context).colorScheme;

    // If not archiving yet, show scope picker.
    if (!archiveProvider.isArchiving && archiveProvider.progress == 0.0) {
      return _ScopePicker(archiveProvider: archiveProvider);
    }

    // If done or error, show result.
    if (!archiveProvider.isArchiving && archiveProvider.progress > 0) {
      return AlertDialog(
        title: Text(
          archiveProvider.error != null ? 'Archive Failed' : 'Archive Complete',
        ),
        content: archiveProvider.error != null
            ? Text(archiveProvider.error!,
                style: TextStyle(color: cs.error, fontSize: 13))
            : Text(archiveProvider.statusMessage),
        actions: [
          TextButton(
            onPressed: () {
              archiveProvider.reset();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    }

    // Progress state.
    return AlertDialog(
      title: const Text('Creating Archive'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(archiveProvider.statusMessage,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: archiveProvider.progress,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(archiveProvider.progress * 100).toInt()}%',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ScopePicker extends StatelessWidget {
  final ArchiveProvider archiveProvider;
  const _ScopePicker({required this.archiveProvider});

  @override
  Widget build(BuildContext context) {
    final communityId = context.read<UserProvider>().communityId;

    return AlertDialog(
      title: const Text('Download Archive'),
      content: const Text(
        'Create a ZIP file with issue metadata (CSV) and photos.\n'
        'Choose which issues to include:',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: communityId == null
              ? null
              : () => archiveProvider.createAndShareArchive(
                    communityId,
                    unresolvedOnly: false,
                  ),
          child: const Text('All Issues'),
        ),
        FilledButton(
          onPressed: communityId == null
              ? null
              : () => archiveProvider.createAndShareArchive(
                    communityId,
                    unresolvedOnly: true,
                  ),
          child: const Text('Unresolved Only'),
        ),
      ],
    );
  }
}
