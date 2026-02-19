import 'dart:convert';
import 'dart:io';

import 'package:universal_live_photo_viewer/data/parsers/parser_errors.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_entity.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_parser.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

class IOSParser implements LivePhotoParser {
  @override
  Future<bool> match(File file) async {
    if (!_isImage(file)) {
      return false;
    }

    final paired = await _findPairedMov(file);
    return paired != null;
  }

  @override
  Future<LivePhotoEntity> parse(File file) async {
    if (!_isImage(file)) {
      throw ParserException(
        ParserErrorCode.invalidInput,
        'Input is not a supported iOS image: ${file.path}',
      );
    }

    final pairedMov = await _findPairedMov(file);
    if (pairedMov == null) {
      throw ParserException(
        ParserErrorCode.pairNotFound,
        'Cannot find paired MOV for ${file.path}',
      );
    }

    return LivePhotoEntity(
      id: file.path,
      imagePath: file.path,
      videoPath: pairedMov.path,
      type: LivePhotoType.ios,
      videoPathIsTemp: false,
    );
  }

  Future<File?> _findPairedMov(File imageFile) async {
    final dir = imageFile.parent;
    if (!await dir.exists()) {
      return null;
    }

    final entries = await dir.list().where((e) => e is File).cast<File>().toList();
    final movFiles = entries.where(_isMov).toList();
    if (movFiles.isEmpty) {
      return null;
    }

    // Priority 1: UUID/AssetIdentifier match.
    final imageUuid = await _extractAssetIdentifier(imageFile);
    if (imageUuid != null) {
      for (final mov in movFiles) {
        final movUuid = await _extractAssetIdentifier(mov);
        if (movUuid != null && movUuid == imageUuid) {
          return mov;
        }
      }
    }

    // Priority 2: filename fallback.
    final imageBase = _baseNameWithoutExt(imageFile.path).toLowerCase();
    for (final mov in movFiles) {
      final movBase = _baseNameWithoutExt(mov.path).toLowerCase();
      if (movBase == imageBase) {
        return mov;
      }
    }

    return null;
  }

  Future<String?> _extractAssetIdentifier(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    final text = latin1.decode(bytes, allowInvalid: true);
    final uuid = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(text);

    return uuid?.group(0)?.toLowerCase();
  }

  bool _isImage(File file) {
    final lower = file.path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.heic');
  }

  bool _isMov(File file) => file.path.toLowerCase().endsWith('.mov');

  String _baseNameWithoutExt(String path) {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0) {
      return name;
    }
    return name.substring(0, dot);
  }
}
