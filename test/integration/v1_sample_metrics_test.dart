import 'package:flutter_test/flutter_test.dart';
import '../../bin/evaluate_v1_samples.dart' as evaluator;

void main() {
  test('metrics summary includes key rates and counts', () async {
    final summary = await evaluator.buildV1MetricsSummary(
      sampleRootPath: 'sample',
      manifestPath: 'sample/v1-sample-manifest.csv',
    );

    expect(summary['total_manifest_items'], 12);
    expect(summary['expected_live_count'], 6);
    expect(summary['recognized_live_count'], greaterThanOrEqualTo(6));
    expect(summary['recognition_rate'], isA<double>());
    expect(summary['playable_rate'], isA<double>());
    expect(summary['failure_type_distribution'], isA<Map<String, int>>());
  });

  test('recognition and playable rates are within valid range', () async {
    final summary = await evaluator.buildV1MetricsSummary(
      sampleRootPath: 'sample',
      manifestPath: 'sample/v1-sample-manifest.csv',
    );

    final recognitionRate = summary['recognition_rate'] as double;
    final playableRate = summary['playable_rate'] as double;

    expect(recognitionRate, inInclusiveRange(0.0, 1.0));
    expect(playableRate, inInclusiveRange(0.0, 1.0));
  });
}
