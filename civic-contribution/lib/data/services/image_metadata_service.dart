import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:exif/exif.dart';
import 'package:civic_contribution/data/services/phash_service.dart';

class ImageMetadata {
  final String hash;
  final String? pHashValue;
  final DateTime? capturedAt;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> raw;

  const ImageMetadata({
    required this.hash,
    this.pHashValue,
    this.capturedAt,
    this.latitude,
    this.longitude,
    required this.raw,
  });
}

/// Single responsibility: extracts MD5 hash, pHash, EXIF metadata from an image file.
class ImageMetadataService {
  final PhashService _phashService;

  ImageMetadataService(this._phashService);

  Future<ImageMetadata> extract(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final hash = _computeHash(bytes);

    // Compute perceptual hash in parallel with EXIF parsing
    final pHashFuture = _phashService.computeHash(imageFile);

    Map<String, dynamic> rawMap = {};
    DateTime? capturedAt;
    double? latitude;
    double? longitude;

    try {
      final tags = await readExifFromBytes(bytes);

      for (final entry in tags.entries) {
        rawMap[entry.key] = entry.value.toString();
      }

      // Parse datetime
      final dtTag = tags['Image DateTime'] ?? tags['EXIF DateTimeOriginal'];
      if (dtTag != null) {
        capturedAt = _parseExifDate(dtTag.toString());
      }

      // Parse GPS
      final latTag = tags['GPS GPSLatitude'];
      final latRef = tags['GPS GPSLatitudeRef'];
      final lonTag = tags['GPS GPSLongitude'];
      final lonRef = tags['GPS GPSLongitudeRef'];

      if (latTag != null && lonTag != null) {
        latitude = _parseGpsCoord(latTag.toString());
        longitude = _parseGpsCoord(lonTag.toString());

        if (latRef != null && latRef.toString() == 'S') {
          latitude = latitude != null ? -latitude : null;
        }
        if (lonRef != null && lonRef.toString() == 'W') {
          longitude = longitude != null ? -longitude : null;
        }
      }
    } catch (_) {
      // EXIF parsing failed — return just the hash
    }

    final pHashValue = await pHashFuture;

    return ImageMetadata(
      hash: hash,
      pHashValue: pHashValue,
      capturedAt: capturedAt,
      latitude: latitude,
      longitude: longitude,
      raw: rawMap,
    );
  }

  String _computeHash(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  DateTime? _parseExifDate(String s) {
    try {
      // Format: "2024:01:15 10:30:00"
      final parts = s.split(' ');
      if (parts.length != 2) return null;
      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  double? _parseGpsCoord(String s) {
    try {
      // Format: "[deg, min, sec]" or "deg/1, min/1, sec/100"
      final cleaned = s.replaceAll('[', '').replaceAll(']', '').trim();
      final parts = cleaned.split(', ');
      if (parts.length != 3) return null;

      double parseFraction(String frac) {
        final f = frac.split('/');
        if (f.length == 2) {
          return double.parse(f[0]) / double.parse(f[1]);
        }
        return double.parse(frac);
      }

      final deg = parseFraction(parts[0]);
      final min = parseFraction(parts[1]);
      final sec = parseFraction(parts[2]);
      return deg + (min / 60) + (sec / 3600);
    } catch (_) {
      return null;
    }
  }
}
