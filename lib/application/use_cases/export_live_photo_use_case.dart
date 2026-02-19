import 'package:universal_live_photo_viewer/application/ports/export_port.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';

class ExportLivePhotoUseCase {
  ExportLivePhotoUseCase({
    required ExportPort exportPort,
  }) : _exportPort = exportPort;

  final ExportPort _exportPort;

  Future<String> exportVideo({
    required LivePhotoEntity entity,
    required String outputPath,
  }) async {
    final videoPath = entity.videoPath;
    if (videoPath == null || videoPath.isEmpty) {
      throw StateError('Live photo has no videoPath');
    }

    return _exportPort.exportVideo(
      sourceVideoPath: videoPath,
      outputPath: outputPath,
    );
  }

  Future<String> exportImage({
    required LivePhotoEntity entity,
    required String outputPath,
  }) {
    return _exportPort.exportImage(
      sourceImagePath: entity.imagePath,
      outputPath: outputPath,
    );
  }

  Future<String> exportGif({
    required LivePhotoEntity entity,
    required String outputPath,
    int fps = 10,
    int? width,
  }) async {
    final videoPath = entity.videoPath;
    if (videoPath == null || videoPath.isEmpty) {
      throw StateError('Live photo has no videoPath');
    }

    return _exportPort.exportGif(
      sourceVideoPath: videoPath,
      outputPath: outputPath,
      fps: fps,
      width: width,
    );
  }
}
