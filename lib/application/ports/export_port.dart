abstract class ExportPort {
  Future<String> exportVideo({
    required String sourceVideoPath,
    required String outputPath,
  });

  Future<String> exportImage({
    required String sourceImagePath,
    required String outputPath,
  });

  Future<String> exportGif({
    required String sourceVideoPath,
    required String outputPath,
    int fps = 10,
    int? width,
  });
}
