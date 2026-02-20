import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/application/providers/report_flow_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';

class ReportConfirmScreen extends StatelessWidget {
  const ReportConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportFlowProvider>();
    final userProvider = context.read<UserProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo preview
            if (provider.capturedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(provider.capturedImage!.path),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                    child: Icon(Icons.image_outlined, size: 48)),
              ),
            const SizedBox(height: 20),

            // Summary card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(context, 'Category',
                        '${provider.selectedCategory.emoji} ${provider.selectedCategory.label}'),
                    const Divider(height: 20),
                    _row(context, 'Description',
                        provider.description.isNotEmpty
                            ? provider.description
                            : '—'),
                    const Divider(height: 20),
                    _row(
                        context,
                        'Location',
                        provider.latitude != null
                            ? '${provider.latitude!.toStringAsFixed(5)}, ${provider.longitude!.toStringAsFixed(5)}'
                            : 'Not available'),
                    if (provider.address.isNotEmpty) ...[
                      const Divider(height: 20),
                      _row(context, 'Address', provider.address),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Once submitted, this issue will be visible to everyone in your community.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: provider.submitting
              ? const Center(child: CircularProgressIndicator())
              : FilledButton.icon(
                  onPressed: () async {
                    final communityId =
                        context.read<UserProvider>().communityId;
                    final success = await provider
                        .submit(userProvider.currentUserId, communityId);
                    if (!context.mounted) return;

                    if (success) {
                      if (provider.wasDuplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'A similar issue already exists — your upvote was added!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Issue reported! +10 credits')),
                        );
                      }
                      provider.reset();
                      context.go('/');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed: ${provider.lastError ?? "Unknown error"}'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Submit Report'),
                ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

