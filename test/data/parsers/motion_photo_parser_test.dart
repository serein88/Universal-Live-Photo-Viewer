import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/data/parsers/motion_photo_parser.dart';
import 'package:universal_live_photo_viewer/data/parsers/parser_errors.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

void main() {
  late MotionPhotoParser parser;

  setUp(() {
    parser = MotionPhotoParser();
  });

  test('match returns true for xiaomi live sample', () async {
    final file = File('sample/xiaomi-live-1.jpg');

    final matched = await parser.match(file);

    expect(matched, isTrue);
  });

  test('parse extracts temp mp4 for xiaomi sample', () async {
    final file = File('sample/xiaomi-live-2.jpg');

    final entity = await parser.parse(file);

    expect(entity.type, LivePhotoType.motionPhoto);
    expect(entity.videoPath, isNotNull);
    expect(entity.videoPathIsTemp, isTrue);

    final outFile = File(entity.videoPath!);
    expect(await outFile.exists(), isTrue);
    expect(await outFile.length(), greaterThan(1024));

    final bytes = await outFile.readAsBytes();
    final header = String.fromCharCodes(bytes.sublist(4, 8));
    expect(header, 'ftyp');

    await entity.dispose();
  });

  test('match returns false for normal image without micro video metadata', () async {
    final file = File('sample/normal-1.jpg');

    final matched = await parser.match(file);

    expect(matched, isFalse);
  });

  test('parse throws parser exception when metadata is missing', () async {
    final file = File('sample/normal-2.jpg');

    expect(
      () => parser.parse(file),
      throwsA(
        isA<ParserException>().having(
          (e) => e.code,
          'code',
          ParserErrorCode.metadataNotFound,
        ),
      ),
    );
  });
}
