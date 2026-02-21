import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_hash/image_hash.dart';

/// Single responsibility: perceptual hash computation and comparison.
class PhashService {
  /// Computes the perceptual hash of [imageFile].
  /// Returns serialized hash string (for example: perceptual:abcd...), or null on failure.
  Future<String?> computeHash(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return ImageHasher.perceptual(decoded).toString();
    } catch (_) {
      return null;
    }
  }

  /// Returns the Hamming distance between two serialized pHash strings.
  /// Returns null if either is null or parsing fails.
  int? hammingDistance(String? a, String? b) {
    if (a == null || b == null) return null;
    try {
      return ImageHash.fromString(a).distance(ImageHash.fromString(b));
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the two hashes are visually similar.
  bool areSimilar(String? a, String? b, {double threshold = 0.85}) {
    if (a == null || b == null) return false;
    try {
      return ImageHash.fromString(a)
          .isSimilar(ImageHash.fromString(b), threshold: threshold);
    } catch (_) {
      return false;
    }
  }
}
