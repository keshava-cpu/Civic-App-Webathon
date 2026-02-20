import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Single responsibility: download image bytes from URLs or local paths.
class ArchiveStorageService {
  /// Maximum concurrent image downloads.
  static const int _maxConcurrent = 5;

  /// Downloads images for the given [urls] map (issueId → photoUrl).
  /// Returns a map of issueId → image bytes for successful downloads.
  /// Calls [onProgress] with (completed, total) after each download.
  Future<Map<String, Uint8List>> downloadImages(
    Map<String, String> urls, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final result = <String, Uint8List>{};
    final entries = urls.entries.toList();
    int completed = 0;

    // Process in batches of _maxConcurrent.
    for (int i = 0; i < entries.length; i += _maxConcurrent) {
      final batch = entries.skip(i).take(_maxConcurrent);
      final futures = batch.map((entry) async {
        try {
          final bytes = await _fetchBytes(entry.value);
          if (bytes != null) {
            result[entry.key] = bytes;
          }
        } catch (e) {
          debugPrint(
              '[ArchiveStorageService] Failed to download ${entry.key}: $e');
        } finally {
          completed++;
          onProgress?.call(completed, entries.length);
        }
      });
      await Future.wait(futures);
    }
    return result;
  }

  Future<Uint8List?> _fetchBytes(String url) async {
    if (url.startsWith('http')) {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    }
    // Local file fallback.
    final file = File(url);
    if (file.existsSync()) return file.readAsBytes();
    return null;
  }
}
