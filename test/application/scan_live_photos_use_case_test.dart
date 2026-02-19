import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/application/ports/file_system_port.dart';
import 'package:universal_live_photo_viewer/application/use_cases/scan_live_photos_use_case.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_parser.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

class _FakeFileSystemPort implements FileSystemPort {
  _FakeFileSystemPort(this.files);

  final List<File> files;

  @override
  Future<void> deleteFile(String path) async {}

  @override
  Future<List<File>> listFilesRecursively(String rootPath) async => files;
}

class _FakeParser implements LivePhotoParser {
  _FakeParser(this.matcher);

  final bool Function(File file) matcher;

  @override
  Future<bool> match(File file) async => matcher(file);

  @override
  Future<LivePhotoEntity> parse(File file) async => LivePhotoEntity(
        id: file.path,
        imagePath: file.path,
        videoPath: null,
        type: LivePhotoType.motionPhoto,
      );
}

void main() {
  test('scan use case returns parsed entities from parser registry', () async {
    final useCase = ScanLivePhotosUseCase(
      fileSystemPort: _FakeFileSystemPort(<File>[
        File('sample/xiaomi-live-1.jpg'),
        File('sample/normal-1.jpg'),
      ]),
      parsers: <LivePhotoParser>[
        _FakeParser((file) => file.path.contains('xiaomi-live')),
      ],
    );

    final result = await useCase.execute('sample');

    expect(result.length, 1);
    expect(result.first.imagePath, 'sample/xiaomi-live-1.jpg');
    expect(result.first.type, LivePhotoType.motionPhoto);
  });

  test('scan use case skips files when no parser matches', () async {
    final useCase = ScanLivePhotosUseCase(
      fileSystemPort: _FakeFileSystemPort(<File>[File('sample/normal-2.jpg')]),
      parsers: <LivePhotoParser>[
        _FakeParser((_) => false),
      ],
    );

    final result = await useCase.execute('sample');

    expect(result, isEmpty);
  });
}
