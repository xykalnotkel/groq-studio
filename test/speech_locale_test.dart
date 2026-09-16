import 'package:flutter_test/flutter_test.dart';
import 'package:xystudio/core/speech.dart';

void main() {
  test('ttsLocale maps short codes to BCP-47', () {
    expect(SpeechService.ttsLocale('id'), 'id-ID');
    expect(SpeechService.ttsLocale('en'), 'en-US');
    expect(SpeechService.ttsLocale('ms'), 'ms-MY');
    expect(SpeechService.ttsLocale('ja'), 'ja-JP');
    expect(SpeechService.ttsLocale('zh'), 'zh-CN');
    expect(SpeechService.ttsLocale('ar'), 'ar-SA');
    expect(SpeechService.ttsLocale('es'), 'es-ES');
    expect(SpeechService.ttsLocale('id-ID'), 'id-ID');
  });
}
