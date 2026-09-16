import 'package:flutter_test/flutter_test.dart';
import 'package:xystudio/core/stats.dart';

void main() {
  test('record menambah token Groq', () {
    const start = UsageStats();
    final next = start.record(
      modeId: 'judul',
      output: 'halo dunia',
      tokens: 120,
    );
    expect(next.totalTokens, 120);
    expect(next.totalGenerates, 1);
    expect(
      next.record(modeId: 'judul', output: 'lagi', tokens: 30).totalTokens,
      150,
    );
  });
}
