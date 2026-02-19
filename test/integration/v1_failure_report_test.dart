import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../../bin/report_v1_failures.dart' as reporter;

void main() {
  test('failure report contains file path, error code, stage and reproduce command', () async {
    final sourceManifest = File('sample/v1-sample-manifest.csv');
    final tempDir = await Directory.systemTemp.createTemp('ulpv-failure-report-test-');
    final tempManifest = File('${tempDir.path}/v1-sample-manifest.csv');

    try {
      final lines = await sourceManifest.readAsLines();
      lines.add(
        'fault_01,generic,live,true,missing-live-photo.jpg,,motionPhoto,,intentional missing sample',
      );
      await tempManifest.writeAsString(lines.join('\n'));

      final report = await reporter.buildV1FailureReport(
        sampleRootPath: 'sample',
        manifestPath: tempManifest.path,
      );

      expect(report['total_failures'], greaterThan(0));
      expect(report['failure_items'], isA<List<dynamic>>());

      final items = report['failure_items'] as List<dynamic>;
      final missingItem = items.cast<Map<String, dynamic>>().firstWhere(
            (item) => (item['file_path'] as String).contains('missing-live-photo.jpg'),
          );

      expect(missingItem['error_code'], 'not_recognized');
      expect(missingItem['stage'], 'recognition');
      expect((missingItem['reproduce_command'] as String), contains('report_v1_failures.dart'));
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
