import 'dart:io';

import 'package:universal_live_photo_viewer/application/ports/file_system_port.dart';

class LocalFileSystemPort implements FileSystemPort {
  @override
  Future<List<File>> listFilesRecursively(String rootPath) async {
    final directory = Directory(rootPath);
    if (!await directory.exists()) {
      throw ArgumentError('Directory not found: $rootPath');
    }

    return directory
        .list(recursive: true, followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
