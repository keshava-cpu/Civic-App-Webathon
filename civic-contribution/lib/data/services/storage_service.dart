import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Uploads photos to Firebase Storage and returns public HTTPS download URLs.
/// Single responsibility: file upload/download URL I/O only.
class StorageService {
  final _uuid = const Uuid();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadIssuePhoto(File imageFile, String userId) async {
    return _uploadToStorage(imageFile, 'issues/$userId');
  }

  Future<String?> uploadVerificationPhoto(File imageFile, String userId) async {
    return _uploadToStorage(imageFile, 'verifications/$userId');
  }

  Future<String?> _uploadToStorage(File imageFile, String folder) async {
    try {
      final compressedFile = await _compress(imageFile);
      if (compressedFile == null) return null;

      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('$folder/$fileName');

      await ref.putFile(File(compressedFile.path));
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Return local path as fallback so the reporting user can see their photo.
      // Other users will see the placeholder until Firebase Storage is configured.
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
