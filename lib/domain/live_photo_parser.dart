import 'dart:io';

import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';

abstract class LivePhotoParser {
  Future<bool> match(File file);

  Future<LivePhotoEntity> parse(File file);
}
