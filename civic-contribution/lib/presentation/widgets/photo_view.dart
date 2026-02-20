import 'dart:io';
import 'package:flutter/material.dart';

/// Renders a photo from either a local file path or a network URL.
/// Firestore stores whichever string was returned by StorageService.
class CivicPhoto extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const CivicPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = placeholder ??
        Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
        );

    if (url == null || url!.isEmpty) return fallback;

    // Local file path (saved by StorageService)
    if (!url!.startsWith('http')) {
      final file = File(url!);
      if (!file.existsSync()) return fallback;
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    // Network URL (future Firebase Storage or other CDN)
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
