import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/ai_coach/data/ai_coach_responder_config.dart';

void main() {
  test('does not configure online responder without endpoint', () {
    const config = AiCoachResponderConfig(endpoint: '  ');

    expect(config.isConfigured, isFalse);
    expect(config.buildResponder(), isNull);
  });

  test('builds online responder from configured endpoint', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, 'https://example.test/ai');
            expect(options.data, {'prompt': 'Frage', 'context': 'Kontext'});
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {'answer': 'Online-Antwort'},
              ),
            );
          },
        ),
      );
    const config = AiCoachResponderConfig(
      endpoint: ' https://example.test/ai ',
    );

    expect(config.isConfigured, isTrue);
    final responder = config.buildResponder(dio: dio);

    expect(responder, isNotNull);
    await expectLater(
      responder!(prompt: 'Frage', context: 'Kontext'),
      completion('Online-Antwort'),
    );
  });
}
