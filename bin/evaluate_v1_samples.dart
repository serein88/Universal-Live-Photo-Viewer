import 'dart:convert';
import 'dart:io';

import 'package:universal_live_photo_viewer/data/services/live_photo_parser_registry.dart';

Future<Map<String, dynamic>> buildV1MetricsSummary({
  required String sampleRootPath,
  required String manifestPath,
  LivePhotoParserRegistry? registry,
}) async {
  final effectiveRegistry = registry ?? LivePhotoParserRegistry.withDefaults();
  final scan = await effectiveRegistry.scanDirectory(sampleRootPath);
  final manifestRows = _readManifest(manifestPath);

  final expectedLiveRows = manifestRows
      .where((row) => (row['is_live_expected'] ?? '').toLowerCase() == 'true')
      .toList();

  final expectedLiveImageSet = expectedLiveRows
      .map((row) => _normalizePath('${sampleRootPath}/${row['image_file'] ?? ''}'))
      .toSet();

  final recognizedByImage = <String, dynamic>{};
  for (final entity in scan.entities) {
    recognizedByImage[_normalizePath(entity.imagePath)] = entity;
  }

  int recognizedLiveCount = 0;
  int playableCount = 0;
  final failureTypeDistribution = <String, int>{};

  for (final row in expectedLiveRows) {
    final imagePath = _normalizePath('${sampleRootPath}/${row['image_file'] ?? ''}');
    final entity = recognizedByImage[imagePath];
    if (entity == null) {
      failureTypeDistribution['not_recognized'] =
          (failureTypeDistribution['not_recognized'] ?? 0) + 1;
      continue;
    }

    recognizedLiveCount++;
    final hasVideo = entity.videoPath != null &&
        entity.videoPath.toString().isNotEmpty &&
        await File(entity.videoPath as String).exists();

    if (hasVideo) {
      playableCount++;
    } else {
      failureTypeDistribution['video_missing'] =
          (failureTypeDistribution['video_missing'] ?? 0) + 1;
    }
  }

  final expectedLiveCount = expectedLiveRows.length;
  final recognitionRate = expectedLiveCount == 0
      ? 0.0
      : recognizedLiveCount / expectedLiveCount;
  final playableRate =
      recognizedLiveCount == 0 ? 0.0 : playableCount / recognizedLiveCount;

  for (final entity in scan.entities) {
    await entity.dispose();
  }

  return <String, dynamic>{
    'sample_root': sampleRootPath,
    'manifest_path': manifestPath,
    'total_manifest_items': manifestRows.length,
    'expected_live_count': expectedLiveCount,
    'recognized_live_count': recognizedLiveCount,
    'playable_live_count': playableCount,
    'recognition_rate': recognitionRate,
    'playable_rate': playableRate,
    'failure_type_distribution': failureTypeDistribution,
    'matched_entities': scan.entities.length,
    'unmatched_files': scan.unmatchedFiles.length,
    'parser_failures': scan.failedFiles.length,
  };
}

List<Map<String, String>> _readManifest(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw ArgumentError('Manifest not found: $path');
  }

  final lines = file.readAsLinesSync();
  if (lines.isEmpty) {
    return <Map<String, String>>[];
  }

  final headers = _splitCsvLine(lines.first);
  final rows = <Map<String, String>>[];
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) {
      continue;
    }
    final values = _splitCsvLine(line);
    final row = <String, String>{};
    for (var i = 0; i < headers.length; i++) {
      row[headers[i]] = i < values.length ? values[i] : '';
    }
    rows.add(row);
  }
  return rows;
}

List<String> _splitCsvLine(String line) {
  final values = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (ch == ',' && !inQuotes) {
      values.add(buffer.toString());
      buffer.clear();
      continue;
    }
    buffer.write(ch);
  }
  values.add(buffer.toString());

  return values;
}

String _normalizePath(String path) {
  return path.replaceAll('\\', '/').toLowerCase();
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/evaluate_v1_samples.dart <sample_root> [manifest_path]',
    );
    exitCode = 64;
    return;
  }

  final sampleRoot = args[0];
  final manifestPath =
      args.length > 1 ? args[1] : '$sampleRoot/v1-sample-manifest.csv';

  final summary = await buildV1MetricsSummary(
    sampleRootPath: sampleRoot,
    manifestPath: manifestPath,
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(summary));
}
