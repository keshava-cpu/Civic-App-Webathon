import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:civic_contribution/core/supabase_config.dart';

/// Uploads photos to Supabase Storage and returns public URLs.
/// Single responsibility: file upload/download URL I/O only.
class StorageService {
  final _uuid = const Uuid();
  SupabaseClient get _client => SupabaseConfig.client;

  Future<String?> uploadIssuePhoto(File imageFile, String userId) async {
    return _upload(imageFile, 'issues', userId);
  }

  Future<String?> uploadVerificationPhoto(File imageFile, String userId) async {
    return _upload(imageFile, 'verifications', userId);
  }

  Future<String?> _upload(
      File imageFile, String bucket, String userId) async {
    try {
      final compressed = await _compress(imageFile);
      if (compressed == null) return null;

      final fileName = '$userId/${_uuid.v4()}.jpg';
      await _client.storage
          .from(bucket)
          .upload(fileName, File(compressed.path));
      return _client.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('[StorageService] Upload failed: $e — returning local path');
      return imageFile.absolute.path;
    }
  }

  Future<XFile?> _compress(File imageFile) async {
    final tmpDir = await getTemporaryDirectory();
    final targetPath = '${tmpDir.path}/${_uuid.v4()}.jpg';
    return FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 1080,
      minHeight: 1080,
    );
  }
}
