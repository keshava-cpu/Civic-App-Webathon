import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';

/// Single responsibility: generates CSV string + saves/shares file.
class ExportService {
  final _uuid = const Uuid();

  /// Header + rows with ID (first 8 chars), category, status, lat, lon, photoUrl,
  /// description, createdAt.
  String generateCsv(List<Issue> issues) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Category,Status,Latitude,Longitude,PhotoUrl,Description,CreatedAt');
    for (final issue in issues) {
      final id = issue.id.length > 8 ? issue.id.substring(0, 8) : issue.id;
      final category = issue.category.label;
      final status = issue.status.label;
      final lat = issue.latitude.toStringAsFixed(6);
      final lon = issue.longitude.toStringAsFixed(6);
      final photo = issue.photoUrl ?? '';
      // Escape description for CSV (wrap in quotes, escape inner quotes)
      final desc = '"${issue.description.replaceAll('"', '""')}"';
      final created = issue.createdAt.toIso8601String();
      buffer.writeln('$id,$category,$status,$lat,$lon,$photo,$desc,$created');
    }
    return buffer.toString();
  }

  /// Writes CSV to app documents directory and opens share sheet.
  Future<String> saveAndShare(String csv, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Community Issues Export');
    return file.path;
  }

  /// Exports CSV + downloads all photos and shares them together.
  Future<void> exportWithImages(List<Issue> issues) async {
    final dir = await getTemporaryDirectory();
    final files = <XFile>[];

    // 1. Write CSV
    final csv = generateCsv(issues);
    final csvFile = File('${dir.path}/civic_issues_${DateTime.now().millisecondsSinceEpoch}.csv');
    await csvFile.writeAsString(csv);
    files.add(XFile(csvFile.path));

    // 2. Download each photo
    for (final issue in issues) {
      if (issue.photoUrl == null) continue;
      try {
        final imgFile = File('${dir.path}/${_uuid.v4()}.jpg');
        if (issue.photoUrl!.startsWith('http')) {
          final response = await http.get(Uri.parse(issue.photoUrl!));
          await imgFile.writeAsBytes(response.bodyBytes);
        } else {
          // Local path fallback
          final localFile = File(issue.photoUrl!);
          if (localFile.existsSync()) {
            await localFile.copy(imgFile.path);
          } else {
            continue;
          }
        }
        files.add(XFile(imgFile.path, mimeType: 'image/jpeg'));
      } catch (e) {
        debugPrint('[ExportService] Failed to download image for ${issue.id}: $e');
      }
    }

    await Share.shareXFiles(files, text: 'Community Issues Export (${issues.length} issues, ${files.length - 1} photos)');
  }
}
