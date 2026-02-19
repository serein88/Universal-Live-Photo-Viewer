import 'dart:convert';
import 'dart:io';

import 'package:universal_live_photo_viewer/data/services/live_photo_parser_registry.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';

Future<Map<String, dynamic>> buildScanSummary(
  String rootPath, {
  LivePhotoParserRegistry? registry,
}) async {
  final effectiveRegistry = registry ?? LivePhotoParserRegistry.withDefaults();
  final result = await effectiveRegistry.scanDirectory(rootPath);

  final typeStats = <String, int>{};
  final items = <Map<String, dynamic>>[];
  final tempEntities = <LivePhotoEntity>[];

  for (final entity in result.entities) {
    final typeName = entity.type.name;
    typeStats[typeName] = (typeStats[typeName] ?? 0) + 1;

    items.add(<String, dynamic>{
      'id': entity.id,
      'imagePath': entity.imagePath,
      'type': typeName,
      'hasVideo': entity.videoPath != null && entity.videoPath!.isNotEmpty,
      'videoIsTemp': entity.videoPathIsTemp,
    });

    if (entity.videoPathIsTemp) {
      tempEntities.add(entity);
    }
  }

  // Prevent temp file accumulation after verification scans.
  for (final entity in tempEntities) {
    await entity.dispose();
  }

  return <String, dynamic>{
    'rootPath': rootPath,
    'totalFiles': result.totalFiles,
    'matchedCount': result.entities.length,
    'unmatchedCount': result.unmatchedFiles.length,
    'failedCount': result.failedFiles.length,
    'types': typeStats,
    'items': items,
  };
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bin/verify_live_photo.dart <directory>');
    exitCode = 64;
    return;
  }

  final summary = await buildScanSummary(args.first);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(summary));
}
