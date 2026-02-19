import 'dart:io';

import 'package:universal_live_photo_viewer/application/ports/file_system_port.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_parser.dart';

class ScanLivePhotosUseCase {
  ScanLivePhotosUseCase({
    required FileSystemPort fileSystemPort,
    required List<LivePhotoParser> parsers,
  })  : _fileSystemPort = fileSystemPort,
        _parsers = parsers;

  final FileSystemPort _fileSystemPort;
  final List<LivePhotoParser> _parsers;

  Future<List<LivePhotoEntity>> execute(String rootPath) async {
    final files = await _fileSystemPort.listFilesRecursively(rootPath);
    final entities = <LivePhotoEntity>[];

    for (final file in files) {
      final parser = await _findMatchingParser(file);
      if (parser == null) {
        continue;
      }

      final entity = await parser.parse(file);
      entities.add(entity);
    }

    return entities;
  }

  Future<LivePhotoParser?> _findMatchingParser(File file) async {
    for (final parser in _parsers) {
      if (await parser.match(file)) {
        return parser;
      }
    }
    return null;
  }
}
