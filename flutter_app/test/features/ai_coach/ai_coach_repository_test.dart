import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/ai_coach/data/ai_coach_repository.dart';
import 'package:gesundheitplus/src/features/privacy/data/local_privacy_repository.dart';

void main() {
  test('blocks health context when AI consent is disabled', () async {
    final db = AppDatabase.memory();
    final answer = await AiCoachRepository(db).ask('Was ist mit Medikamenten?');
    expect(answer.consentUsed, isFalse);
    expect(answer.content, contains('Kontextfreigabe'));
    expect(await AiCoachRepository(db).listMessages(), hasLength(2));
    db.close();
  });

  test('answers locally when AI consent is enabled', () async {
    final db = AppDatabase.memory();
    await LocalPrivacyRepository(db).setAiContextAllowed(true);
    final answer = await AiCoachRepository(db).ask('Termin planen');
    expect(answer.consentUsed, isTrue);
    expect(answer.content, contains('Termine'));
    db.close();
  });
}
