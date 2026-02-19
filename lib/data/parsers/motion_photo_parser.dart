import 'dart:convert';
import 'dart:io';

import 'package:universal_live_photo_viewer/data/parsers/parser_errors.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_parser.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

class MotionPhotoParser implements LivePhotoParser {
  static final RegExp _offsetPattern = RegExp(
    r'(?:GCamera:)?MicroVideoOffset\s*=\s*"(\d+)"',
  );

  @override
  Future<bool> match(File file) async {
    if (!_isJpeg(file)) {
      return false;
    }

    final offset = await _readOffset(file);
    return offset != null;
  }

  @override
  Future<LivePhotoEntity> parse(File file) async {
    if (!_isJpeg(file)) {
      throw ParserException(
        ParserErrorCode.invalidInput,
        'Input is not a JPEG motion photo: ${file.path}',
      );
    }

    final offset = await _readOffset(file);
    if (offset == null) {
      throw ParserException(
        ParserErrorCode.metadataNotFound,
        'MicroVideoOffset not found: ${file.path}',
      );
    }

    final bytes = await file.readAsBytes();
    if (offset <= 0 || offset >= bytes.length) {
      throw ParserException(
        ParserErrorCode.invalidInput,
        'Invalid MicroVideoOffset=$offset for ${file.path}',
      );
    }

    final start = bytes.length - offset;
    final mp4Bytes = bytes.sublist(start);
    final outFile = await _writeTempMp4(mp4Bytes);

    return LivePhotoEntity(
      id: file.path,
      imagePath: file.path,
      videoPath: outFile.path,
      type: LivePhotoType.motionPhoto,
      videoPathIsTemp: true,
    );
  }

  Future<int?> _readOffset(File file) async {
    final bytes = await file.readAsBytes();
    final text = latin1.decode(bytes, allowInvalid: true);
    final match = _offsetPattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1) ?? '');
  }

  Future<File> _writeTempMp4(List<int> bytes) async {
    final dir = await Directory.systemTemp.createTemp('ulpv_motion_photo');
    final out = File('${dir.path}${Platform.pathSeparator}motion.mp4');
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  bool _isJpeg(File file) {
    final lower = file.path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg');
  }
}
