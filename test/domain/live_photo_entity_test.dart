import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

void main() {
  test('live photo types include v1 and future vendors', () {
    final names = LivePhotoType.values.map((e) => e.name).toSet();
    expect(
      names,
      containsAll(<String>[
        'ios',
        'motionPhoto',
        'xiaomi',
        'vivo',
        'huawei',
        'oppo',
        'unknown',
      ]),
    );
  });

  test('dispose deletes temp video file when flagged', () async {
    final tempDir = await Directory.systemTemp.createTemp('ulpv_entity_test');
    final tempVideo = File('${tempDir.path}${Platform.pathSeparator}video.mp4');
    await tempVideo.writeAsString('temp-video');

    final entity = LivePhotoEntity(
      id: '1',
      imagePath: '/image.jpg',
      videoPath: tempVideo.path,
      type: LivePhotoType.motionPhoto,
      videoPathIsTemp: true,
    );

    await entity.dispose();

    expect(await tempVideo.exists(), isFalse);
    await tempDir.delete(recursive: true);
  });

  test('dispose keeps non-temp video file', () async {
    final tempDir = await Directory.systemTemp.createTemp('ulpv_entity_test_keep');
    final tempVideo = File('${tempDir.path}${Platform.pathSeparator}video.mp4');
    await tempVideo.writeAsString('keep-video');

    final entity = LivePhotoEntity(
      id: '2',
      imagePath: '/image.jpg',
      videoPath: tempVideo.path,
      type: LivePhotoType.ios,
      videoPathIsTemp: false,
    );

    await entity.dispose();

    expect(await tempVideo.exists(), isTrue);
    await tempVideo.delete();
    await tempDir.delete(recursive: true);
  });
}
