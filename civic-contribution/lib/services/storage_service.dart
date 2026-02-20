import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Saves photos to the device's local documents directory.
/// The returned path (a local file path) is stored in Firestore as `photoUrl`.
/// Since this is a single-device demo, all mock users share the same filesystem.
class StorageService {
  final _uuid = const Uuid();

  Future<String?> uploadIssuePhoto(File imageFile, String userId) async {
    return _saveLocally(imageFile, 'issues');
  }

  Future<String?> uploadVerificationPhoto(File imageFile, String userId) async {
    return _saveLocally(imageFile, 'verifications');
  }

  Future<String?> _saveLocally(File imageFile, String folder) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}/civic_photos/$folder');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final fileName = '${_uuid.v4()}.jpg';
      final targetPath = '${dir.path}/$fileName';

      // Compress into the persistent docs directory
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (result != null) return result.path;

      // Fallback: copy original if compression failed
      final copied = await imageFile.copy(targetPath);
      return copied.path;
    } catch (_) {
      return null;
    }
  }
}
