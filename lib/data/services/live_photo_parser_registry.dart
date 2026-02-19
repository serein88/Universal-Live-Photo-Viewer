import 'dart:io';

import 'package:universal_live_photo_viewer/data/parsers/ios_parser.dart';
import 'package:universal_live_photo_viewer/data/parsers/motion_photo_parser.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_parser.dart';

class LivePhotoScanResult {
  LivePhotoScanResult({
    required this.totalFiles,
    required this.entities,
    required this.unmatchedFiles,
    required this.failedFiles,
  });

  final int totalFiles;
  final List<LivePhotoEntity> entities;
  final List<String> unmatchedFiles;
  final Map<String, String> failedFiles;
}

class LivePhotoParserRegistry {
  LivePhotoParserRegistry({
    required List<LivePhotoParser> parsers,
  }) : _parsers = parsers;

  factory LivePhotoParserRegistry.withDefaults() {
    return LivePhotoParserRegistry(
      parsers: <LivePhotoParser>[
        IOSParser(),
        MotionPhotoParser(),
      ],
    );
  }

  final List<LivePhotoParser> _parsers;

  Future<LivePhotoScanResult> scanDirectory(String rootPath) async {
    final dir = Directory(rootPath);
    if (!await dir.exists()) {
      throw ArgumentError('Directory not found: $rootPath');
    }

    final files = await dir
        .list(recursive: true, followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    final entities = <LivePhotoEntity>[];
    final unmatched = <String>[];
    final failed = <String, String>{};

    for (final file in files) {
      try {
        final parsed = await _tryParse(file);
        if (parsed == null) {
          unmatched.add(file.path);
          continue;
        }
        entities.add(parsed);
      } catch (e) {
        failed[file.path] = e.toString();
      }
    }

    return LivePhotoScanResult(
      totalFiles: files.length,
      entities: entities,
      unmatchedFiles: unmatched,
      failedFiles: failed,
    );
  }

  Future<LivePhotoEntity?> _tryParse(File file) async {
    for (final parser in _parsers) {
      if (await parser.match(file)) {
        return parser.parse(file);
      }
    }
    return null;
  }
}
