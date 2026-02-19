import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/application/ports/export_port.dart';
import 'package:universal_live_photo_viewer/application/use_cases/export_live_photo_use_case.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

class _FakeExportPort implements ExportPort {
  String? lastCall;

  @override
  Future<String> exportGif({
    required String sourceVideoPath,
    required String outputPath,
    int fps = 10,
    int? width,
  }) async {
    lastCall = 'gif:$sourceVideoPath:$outputPath:$fps:${width ?? -1}';
    return outputPath;
  }

  @override
  Future<String> exportImage({
    required String sourceImagePath,
    required String outputPath,
  }) async {
    lastCall = 'image:$sourceImagePath:$outputPath';
    return outputPath;
  }

  @override
  Future<String> exportVideo({
    required String sourceVideoPath,
    required String outputPath,
  }) async {
    lastCall = 'video:$sourceVideoPath:$outputPath';
    return outputPath;
  }
}

void main() {
  test('export use case routes to video export when entity has video', () async {
    final port = _FakeExportPort();
    final useCase = ExportLivePhotoUseCase(exportPort: port);
    final entity = LivePhotoEntity(
      id: 'id-1',
      imagePath: 'sample/iphone-13p-live-1.JPG',
      videoPath: 'sample/iphone-13p-live-1.MOV',
      type: LivePhotoType.ios,
    );

    final result = await useCase.exportVideo(
      entity: entity,
      outputPath: 'output/video.mov',
    );

    expect(result, 'output/video.mov');
    expect(port.lastCall, 'video:sample/iphone-13p-live-1.MOV:output/video.mov');
  });

  test('export use case throws when exporting video without videoPath', () async {
    final port = _FakeExportPort();
    final useCase = ExportLivePhotoUseCase(exportPort: port);
    final entity = LivePhotoEntity(
      id: 'id-2',
      imagePath: 'sample/normal-1.jpg',
      videoPath: null,
      type: LivePhotoType.unknown,
    );

    expect(
      () => useCase.exportVideo(entity: entity, outputPath: 'output/video.mp4'),
      throwsA(isA<StateError>()),
    );
  });
}
