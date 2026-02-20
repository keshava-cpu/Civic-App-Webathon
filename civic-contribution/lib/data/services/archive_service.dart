import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';

/// Single responsibility: build a ZIP archive from issues + image bytes.
class ArchiveService {
  /// Creates a ZIP file containing metadata.csv and issue images.
  ///
  /// ZIP structure:
  /// ```
  /// archive_<timestamp>.zip
  /// ├── metadata.csv
  /// └── images/
  ///     ├── <issueId_1>.jpg
  ///     ├── <issueId_2>.jpg
  ///     └── ...
  /// ```
  ///
  /// Returns the path to the generated ZIP file.
  Future<String> createArchive({
    required List<Issue> issues,
    required Map<String, Uint8List> imageBytes,
  }) async {
    final archive = Archive();

    // 1. Add metadata CSV.
    final csv = _generateCsv(issues);
    final csvBytes = Uint8List.fromList(csv.codeUnits);
    archive.addFile(ArchiveFile('metadata.csv', csvBytes.length, csvBytes));

    // 2. Add images.
    for (final entry in imageBytes.entries) {
      archive.addFile(
        ArchiveFile(
          'images/${entry.key}.jpg',
          entry.value.length,
          entry.value,
        ),
      );
    }

    // 3. Encode to ZIP.
    final zipBytes = ZipEncoder().encode(archive);

    // 4. Write to temp directory.
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = File('${dir.path}/civic_archive_$timestamp.zip');
    await zipFile.writeAsBytes(zipBytes);

    return zipFile.path;
  }

  /// CSV with headers for metadata overview.
  String _generateCsv(List<Issue> issues) {
    final buf = StringBuffer();
    buf.writeln(
        'ID,Category,Status,Latitude,Longitude,Address,Description,CreatedAt,HasPhoto');
    for (final issue in issues) {
      final id = issue.id.length > 8 ? issue.id.substring(0, 8) : issue.id;
      final cat = issue.category.label;
      final status = issue.status.label;
      final lat = issue.location.latitude.toStringAsFixed(6);
      final lon = issue.location.longitude.toStringAsFixed(6);
      final addr = '"${issue.address.replaceAll('"', '""')}"';
      final desc = '"${issue.description.replaceAll('"', '""')}"';
      final created = issue.createdAt.toIso8601String();
      final hasPhoto = issue.photoUrl != null ? 'Yes' : 'No';
      buf.writeln('$id,$cat,$status,$lat,$lon,$addr,$desc,$created,$hasPhoto');
    }
    return buf.toString();
  }
}
