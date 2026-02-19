import 'dart:io';

import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

class LivePhotoEntity {
  const LivePhotoEntity({
    required this.id,
    required this.imagePath,
    required this.type,
    this.videoPath,
    this.videoPathIsTemp = false,
  });

  final String id;
  final String imagePath;
  final String? videoPath;
  final LivePhotoType type;
  final bool videoPathIsTemp;

  Future<void> dispose() async {
    if (!videoPathIsTemp || videoPath == null) {
      return;
    }

    final file = File(videoPath!);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
