import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/data/parsers/ios_parser.dart';
import 'package:universal_live_photo_viewer/data/parsers/parser_errors.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';

void main() {
  late IOSParser parser;

  setUp(() {
    parser = IOSParser();
  });

  test('match returns true for sample iphone image with paired mov', () async {
    final image = File('sample/iphone-13p-live-1.JPG');

    final matched = await parser.match(image);

    expect(matched, isTrue);
  });

  test('parse returns ios entity with paired mov path', () async {
    final image = File('sample/iphone-13p-live-2.JPG');

    final entity = await parser.parse(image);

    expect(entity.type, LivePhotoType.ios);
    expect(entity.imagePath.toLowerCase(), endsWith('iphone-13p-live-2.jpg'));
    expect(entity.videoPath?.toLowerCase(), endsWith('iphone-13p-live-2.mov'));
    expect(entity.videoPathIsTemp, isFalse);
  });

  test('parse throws parser exception with code when pair not found', () async {
    final image = File('sample/normal-1.jpg');

    expect(
      () => parser.parse(image),
      throwsA(
        isA<ParserException>().having(
          (e) => e.code,
          'code',
          ParserErrorCode.pairNotFound,
        ),
      ),
    );
  });

  test('uuid pair has priority over filename fallback', () async {
    final dir = await Directory.systemTemp.createTemp('ulpv_ios_parser_uuid');
    const uuidTarget = '123e4567-e89b-12d3-a456-426614174000';
    const uuidOther = '123e4567-e89b-12d3-a456-426614174111';

    final image = File('${dir.path}${Platform.pathSeparator}same-name.JPG');
    final movByName = File('${dir.path}${Platform.pathSeparator}same-name.MOV');
    final movByUuid = File('${dir.path}${Platform.pathSeparator}different-name.MOV');

    await image.writeAsString('AssetIdentifier:$uuidTarget');
    await movByName.writeAsString('AssetIdentifier:$uuidOther');
    await movByUuid.writeAsString('AssetIdentifier:$uuidTarget');

    final entity = await parser.parse(image);

    expect(entity.videoPath, movByUuid.path);
    await dir.delete(recursive: true);
  });
}
