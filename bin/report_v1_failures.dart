import 'dart:convert';
import 'dart:io';

import 'package:universal_live_photo_viewer/data/services/live_photo_parser_registry.dart';

Future<Map<String, dynamic>> buildV1FailureReport({
  required String sampleRootPath,
  required String manifestPath,
  String? focusPath,
  LivePhotoParserRegistry? registry,
}) async {
  final effectiveRegistry = registry ?? LivePhotoParserRegistry.withDefaults();
  final scan = await effectiveRegistry.scanDirectory(sampleRootPath);
  final manifestRows = _readManifest(manifestPath);

  final expectedLiveRows = manifestRows
      .where((row) => (row['is_live_expected'] ?? '').toLowerCase() == 'true')
      .toList();

  final recognizedByImage = <String, dynamic>{};
  for (final entity in scan.entities) {
    recognizedByImage[_normalizePath(entity.imagePath)] = entity;
  }

  final failedByPath = <String, String>{};
  scan.failedFiles.forEach((path, error) {
    failedByPath[_normalizePath(path)] = error;
  });

  final failureItems = <Map<String, dynamic>>[];

  for (final row in expectedLiveRows) {
    final imageFile = row['image_file'] ?? '';
    if (imageFile.trim().isEmpty) {
      continue;
    }

    final imagePath = _joinPath(sampleRootPath, imageFile);
    final normalizedImagePath = _normalizePath(imagePath);

    final parserFailure = failedByPath[normalizedImagePath];
    if (parserFailure != null) {
      failureItems.add(<String, dynamic>{
        'file_path': imagePath,
        'error_code': _extractErrorCode(parserFailure),
        'stage': 'parsing',
        'details': parserFailure,
        'reproduce_command':
            'dart run bin/report_v1_failures.dart "$sampleRootPath" "$manifestPath" --focus "$imagePath"',
      });
      continue;
    }

    final entity = recognizedByImage[normalizedImagePath];
    if (entity == null) {
      failureItems.add(<String, dynamic>{
        'file_path': imagePath,
        'error_code': 'not_recognized',
        'stage': 'recognition',
        'details': 'Expected live sample was not recognized by any parser.',
        'reproduce_command':
            'dart run bin/report_v1_failures.dart "$sampleRootPath" "$manifestPath" --focus "$imagePath"',
      });
      continue;
    }

    final hasVideo = entity.videoPath != null &&
        entity.videoPath.toString().isNotEmpty &&
        await File(entity.videoPath as String).exists();

    if (!hasVideo) {
      failureItems.add(<String, dynamic>{
        'file_path': imagePath,
        'error_code': 'video_missing',
        'stage': 'playability',
        'details': 'Live sample recognized but no playable video output.',
        'reproduce_command':
            'dart run bin/report_v1_failures.dart "$sampleRootPath" "$manifestPath" --focus "$imagePath"',
      });
    }
  }

  // Include scan-time parser failures for files outside expected-live manifest rows.
  for (final entry in scan.failedFiles.entries) {
    final normalizedPath = _normalizePath(entry.key);
    final alreadyCaptured = failureItems.any(
      (item) => _normalizePath(item['file_path'] as String) == normalizedPath,
    );
    if (alreadyCaptured) {
      continue;
    }

    failureItems.add(<String, dynamic>{
      'file_path': entry.key,
      'error_code': _extractErrorCode(entry.value),
      'stage': 'parsing',
      'details': entry.value,
      'reproduce_command':
          'dart run bin/report_v1_failures.dart "$sampleRootPath" "$manifestPath" --focus "${entry.key}"',
    });
  }

  final filteredItems = _applyFocusFilter(failureItems, focusPath);
  final stageDistribution = <String, int>{};
  final errorDistribution = <String, int>{};
  for (final item in filteredItems) {
    final stage = item['stage'] as String? ?? 'unknown';
    final errorCode = item['error_code'] as String? ?? 'unknown';
    stageDistribution[stage] = (stageDistribution[stage] ?? 0) + 1;
    errorDistribution[errorCode] = (errorDistribution[errorCode] ?? 0) + 1;
  }

  for (final entity in scan.entities) {
    await entity.dispose();
  }

  return <String, dynamic>{
    'sample_root': sampleRootPath,
    'manifest_path': manifestPath,
    'focus_path': focusPath,
    'total_failures': filteredItems.length,
    'failures_by_stage': stageDistribution,
    'failures_by_error_code': errorDistribution,
    'failure_items': filteredItems,
  };
}

List<Map<String, dynamic>> _applyFocusFilter(
  List<Map<String, dynamic>> items,
  String? focusPath,
) {
  if (focusPath == null || focusPath.trim().isEmpty) {
    return items;
  }
  final normalizedFocus = _normalizePath(focusPath);
  return items
      .where(
        (item) => _normalizePath(item['file_path'] as String) == normalizedFocus,
      )
      .toList();
}

String _extractErrorCode(String errorText) {
  final match = RegExp(r'parser_error\.[a-z0-9_]+').firstMatch(errorText);
  if (match != null) {
    return match.group(0)!;
  }
  return 'parser_exception';
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

String _joinPath(String root, String fileName) {
  final normalizedRoot = root.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  final normalizedFile = fileName.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
  return '$normalizedRoot/$normalizedFile';
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/report_v1_failures.dart <sample_root> [manifest_path] [--focus <file_path>]',
    );
    exitCode = 64;
    return;
  }

  final sampleRoot = args.first;
  String? manifestPath;
  String? focusPath;

  if (args.length > 1 && !args[1].startsWith('--')) {
    manifestPath = args[1];
  }
  manifestPath ??= '$sampleRoot/v1-sample-manifest.csv';

  for (var i = 1; i < args.length; i++) {
    if (args[i] == '--focus' && i + 1 < args.length) {
      focusPath = args[i + 1];
    }
  }

  final report = await buildV1FailureReport(
    sampleRootPath: sampleRoot,
    manifestPath: manifestPath,
    focusPath: focusPath,
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
