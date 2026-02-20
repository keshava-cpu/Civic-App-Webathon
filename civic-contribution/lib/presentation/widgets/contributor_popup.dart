import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/models/user_profile.dart';

class ContributorPopup extends StatelessWidget {
  final List<UserProfile> contributors;
  final String issueTitle;

  const ContributorPopup({
    super.key,
    required this.contributors,
    required this.issueTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required List<UserProfile> contributors,
    required String issueTitle,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ContributorPopup(
        contributors: contributors,
        issueTitle: issueTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            'Issue Verified!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            issueTitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thanks to these civic heroes:',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          ...contributors.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      c.displayName[0],
                      style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(c.displayName)),
                  ...c.badges
                      .take(2)
                      .map((b) => Text(b.emoji,
                          style: const TextStyle(fontSize: 16))),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Awesome!'),
        ),
      ],
    );
  }
}

