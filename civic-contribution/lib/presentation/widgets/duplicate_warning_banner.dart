import 'package:flutter/material.dart';

/// Single responsibility: displays a non-blocking warning when a visually
/// similar issue has already been reported.
class DuplicateWarningBanner extends StatelessWidget {
  final String? existingDescription;
  final VoidCallback? onViewIssue;

  const DuplicateWarningBanner({
    super.key,
    this.existingDescription,
    this.onViewIssue,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final preview = existingDescription != null &&
            existingDescription!.isNotEmpty
        ? (existingDescription!.length > 80
            ? '${existingDescription!.substring(0, 80)}…'
            : existingDescription!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: cs.onErrorContainer, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Similar issue already reported',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The issue you are going to post is already posted. '
            'Your post will just be added as an upvote to that post.',
            style: TextStyle(
              color: cs.onErrorContainer,
              fontSize: 12,
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 6),
            Text(
              preview,
              style: TextStyle(
                color: cs.onErrorContainer.withOpacity(0.75),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (onViewIssue != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onViewIssue,
              style: TextButton.styleFrom(
                foregroundColor: cs.onErrorContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View existing issue →',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
