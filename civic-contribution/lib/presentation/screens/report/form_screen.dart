import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/application/providers/report_flow_provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/presentation/widgets/category_picker.dart';
import 'package:civic_contribution/presentation/widgets/duplicate_warning_banner.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ReportFlowProvider>();
    _descController.text = provider.description;
    _addressController.text = provider.address;
    // Auto-fetch location if not already available, then run pHash check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final communityId = context.read<UserProvider>().communityId;
      if (provider.latitude == null || provider.longitude == null) {
        provider.fetchCurrentLocation();
      }
      provider.runPHashCheck(communityId);
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _canProceed(ReportFlowProvider provider) {
    return _descController.text.trim().isNotEmpty &&
        provider.capturedImage != null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportFlowProvider>();
    final cs = Theme.of(context).colorScheme;
    final communityId = context.read<UserProvider>().communityId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          TextButton(
            onPressed: _canProceed(provider)
                ? () {
                    provider.setDescription(_descController.text.trim());
                    provider.setAddress(_addressController.text.trim());
                    context.push('/report/confirm');
                  }
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // pHash duplicate warning — shown above everything else
            if (provider.checkingPHash)
              const LinearProgressIndicator()
            else if (provider.hasPHashWarning)
              DuplicateWarningBanner(
                existingDescription:
                    provider.pHashDuplicateResult?.existingDescription,
                onViewIssue: provider.pHashDuplicateResult?.existingIssueId !=
                        null
                    ? () => context.push(
                        '/issue/${provider.pHashDuplicateResult!.existingIssueId}')
                    : null,
              ),

            // Photo preview
            if (provider.capturedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(provider.capturedImage!.path),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            // Category
            Text('Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 10),
            CategoryPicker(
              selected: provider.selectedCategory,
              onSelected: (category) {
                provider.setCategory(category);
                provider.runPHashCheck(communityId);
              },
            ),
            const SizedBox(height: 20),

            // Description
            Text('Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Describe the issue clearly...',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Location section with better messaging
            Text('Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            if (provider.fetchingLocation)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Getting your location...',
                            style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Make sure location services are enabled',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    cs.onPrimaryContainer.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (provider.latitude != null && provider.longitude != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: cs.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${provider.latitude!.toStringAsFixed(5)}, ${provider.longitude!.toStringAsFixed(5)}',
                            style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                                fontSize: 14),
                          ),
                          Text(
                            'Location captured',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    cs.onPrimaryContainer.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: cs.primary, size: 20),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_outlined,
                        color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location not available',
                            style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Enable GPS and allow location permission',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: provider.fetchCurrentLocation,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Street address (optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _canProceed(provider)
                ? () {
                    provider.setDescription(_descController.text.trim());
                    provider.setAddress(_addressController.text.trim());
                    context.push('/report/confirm');
                  }
                : null,
            child: const Text('Review & Submit'),
          ),
        ),
      ),
    );
  }
}
