import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_parser.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

class _FakeMotionParser implements LivePhotoParser {
  @override
  Future<bool> match(File file) async => file.path.toLowerCase().endsWith('.jpg');

  @override
  Future<LivePhotoEntity> parse(File file) async => LivePhotoEntity(
        id: file.path,
        imagePath: file.path,
        videoPath: null,
        type: LivePhotoType.motionPhoto,
      );
}

void main() {
  test('parser contract supports match and parse flow', () async {
    final parser = _FakeMotionParser();
    final file = File('sample/xiaomi-live-1.jpg');

    final matched = await parser.match(file);
    final entity = await parser.parse(file);

    expect(matched, isTrue);
    expect(entity.imagePath, file.path);
    expect(entity.type, LivePhotoType.motionPhoto);
  });
}
