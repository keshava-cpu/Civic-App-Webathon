import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/application/providers/user_provider.dart';
import 'package:civic_contribution/application/providers/verification_provider.dart';
import 'package:civic_contribution/data/services/database_service.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'package:civic_contribution/domain/models/verification.dart';
import 'package:civic_contribution/presentation/widgets/trust_indicator.dart';

class VerifyScreen extends StatefulWidget {
  final String issueId;
  const VerifyScreen({super.key, required this.issueId});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  bool? _isResolved;
  File? _photo;
  final _commentController = TextEditingController();
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _showCamera = false;

  // F4: Existing verification state
  bool _loadingExisting = true;
  Verification? _existingVerification;

  @override
  void initState() {
    super.initState();
    _loadExistingVerification();
  }

  Future<void> _loadExistingVerification() async {
    final userId = context.read<UserProvider>().currentUserId;
    final vp = context.read<VerificationProvider>();
    final existing =
        await vp.getExistingVerification(widget.issueId, userId);
    if (mounted) {
      setState(() {
        _existingVerification = existing;
        _loadingExisting = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {}
  }

  Future<void> _capturePhoto() async {
    if (!_cameraReady || _cameraController == null) return;
    final xFile = await _cameraController!.takePicture();
    setState(() {
      _photo = File(xFile.path);
      _showCamera = false;
    });
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _photo = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final currentUserId = userProvider.currentUserId;
    final currentProfile = userProvider.currentUserProfile;
    final verifyProvider = context.watch<VerificationProvider>();
    final fs = context.read<DatabaseService>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Issue')),
      body: StreamBuilder<List<Issue>>(
        stream: fs.getIssuesStream(),
        builder: (context, snap) {
          final issue = snap.data
              ?.where((i) => i.id == widget.issueId)
              .firstOrNull;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // F4: Loading existing verification
                if (_loadingExisting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                // F4: Existing locked verification — cannot change
                else if (_existingVerification != null &&
                    _existingVerification!.isLocked) ...[
                  // Issue summary
                  if (issue != null)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(issue.category.emoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(issue.category.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  Text(issue.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Card(
                    color: cs.errorContainer,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: cs.onErrorContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your verification is locked. You\'ve already changed it once.',
                              style: TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ExistingVoteInfo(verification: _existingVerification!),
                ]
                // F4: Existing non-locked verification — can change once
                else if (_existingVerification != null &&
                    !_existingVerification!.isLocked) ...[
                  // Issue summary
                  if (issue != null)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(issue.category.emoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(issue.category.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  Text(issue.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _ExistingVoteInfo(verification: _existingVerification!),
                  const SizedBox(height: 16),
                  Card(
                    color: cs.tertiaryContainer,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change Your Vote (once only)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'You may change your verification once. This will deduct your original credits and award +5 correction credits. This action is irreversible.'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ChoiceCard(
                                  selected: _isResolved == true,
                                  color: Colors.green,
                                  icon: Icons.check_circle_outline,
                                  label: 'Yes, Resolved',
                                  onTap: () =>
                                      setState(() => _isResolved = true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ChoiceCard(
                                  selected: _isResolved == false,
                                  color: Colors.red,
                                  icon: Icons.cancel_outlined,
                                  label: 'No, Still Open',
                                  onTap: () =>
                                      setState(() => _isResolved = false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _commentController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Reason for changing your vote...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: verifyProvider.submitting
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : FilledButton.icon(
                                    onPressed: _isResolved == null
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Change Verification?'),
                                                content: const Text(
                                                    'This action cannot be undone. Your vote will be locked after this change.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child:
                                                        const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    child: const Text(
                                                        'Change Vote'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed != true ||
                                                !context.mounted) return;
                                            final vp = context.read<
                                                VerificationProvider>();
                                            final success =
                                                await vp.reverseVerification(
                                              issueId: widget.issueId,
                                              userId: currentUserId,
                                              newIsResolved: _isResolved!,
                                              newComment: _commentController
                                                  .text
                                                  .trim(),
                                            );
                                            if (!context.mounted) return;
                                            if (success) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Vote changed! +5 credits (correction)')),
                                              );
                                              context.pop();
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(vp
                                                            .lastError ??
                                                        'Failed to change vote')),
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.swap_horiz),
                                    label: const Text('Change My Vote'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
                // Normal flow: no existing verification
                else ...[
                // Issue summary
                if (issue != null)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(issue.category.emoji,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(issue.category.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                Text(issue.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Your trust score
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Verifying as ${currentProfile?.displayName ?? 'You'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TrustIndicator(trustScore: currentProfile?.trustScore ?? 0.5),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Has the issue been resolved?
                Text('Is this issue resolved?',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ChoiceCard(
                        selected: _isResolved == true,
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                        label: 'Yes, Resolved',
                        onTap: () => setState(() => _isResolved = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ChoiceCard(
                        selected: _isResolved == false,
                        color: Colors.red,
                        icon: Icons.cancel_outlined,
                        label: 'No, Still Open',
                        onTap: () => setState(() => _isResolved = false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Photo evidence
                Text('Photo Evidence (optional)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_photo != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_photo!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _photo = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_showCamera && _cameraReady)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _showCamera = false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton.icon(
                            onPressed: _capturePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capture'),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _initCamera();
                            setState(() => _showCamera = true);
                          },
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Comment
                Text('Comment (optional)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe what you observed...',
                  ),
                ),

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: verifyProvider.submitting
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          onPressed: _isResolved == null
                              ? null
                              : () async {
                                  final vp = context.read<VerificationProvider>();
                                  final success = await vp.submitVerification(
                                    issueId: widget.issueId,
                                    verifierId: currentUserId,
                                    verifierTrustScore: currentProfile?.trustScore ?? 0.5,
                                    isResolved: _isResolved!,
                                    comment: _commentController.text.trim(),
                                    photo: _photo,
                                  );
                                  if (!context.mounted) return;
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Verification submitted! +15 credits')),
                                    );
                                    context.pop();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(vp.lastError ??
                                              'Failed to submit')),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Submit Verification'),
                        ),
                ),
                const SizedBox(height: 40),
              ], // end else (normal flow)
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shows info about an existing verification vote.
class _ExistingVoteInfo extends StatelessWidget {
  final Verification verification;
  const _ExistingVoteInfo({required this.verification});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Previous Vote',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  verification.isResolved
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: verification.isResolved ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(verification.isResolved
                    ? 'Marked as Resolved'
                    : 'Marked as Still Open'),
              ],
            ),
            if (verification.comment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(verification.comment,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.selected,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : null, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : null,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

