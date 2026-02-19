import 'package:flutter_test/flutter_test.dart';
import 'package:universal_live_photo_viewer/data/services/live_photo_parser_registry.dart';
import 'package:universal_live_photo_viewer/domain/live_photo_type.dart';
import '../../bin/verify_live_photo.dart' as cli;

void main() {
  test('registry scans sample directory and finds v1 live photos', () async {
    final registry = LivePhotoParserRegistry.withDefaults();
    final result = await registry.scanDirectory('sample');

    expect(result.totalFiles, greaterThanOrEqualTo(15));
    expect(result.entities.length, greaterThanOrEqualTo(6));

    final types = result.entities.map((e) => e.type).toSet();
    expect(types, contains(LivePhotoType.ios));
    expect(types, contains(LivePhotoType.motionPhoto));

    for (final entity in result.entities) {
      await entity.dispose();
    }
  });

  test('cli summary provides structured output fields', () async {
    final summary = await cli.buildScanSummary('sample');

    expect(summary['rootPath'], 'sample');
    expect(summary['totalFiles'], greaterThan(0));
    expect(summary['matchedCount'], greaterThan(0));
    expect(summary['types'], isA<Map<String, int>>());
    expect(summary['items'], isA<List<dynamic>>());
  });
}
