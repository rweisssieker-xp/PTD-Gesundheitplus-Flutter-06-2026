import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/health_record/data/health_record_repository.dart';
import 'package:gesundheitplus/src/features/ai_coach/data/ai_coach_repository.dart';
import 'package:gesundheitplus/src/features/medication/data/medication_repository.dart';
import 'package:gesundheitplus/src/features/medication/domain/medication.dart';
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
    expect(answer.content, contains('lokal auf dem Gerät erzeugt'));
    db.close();
  });

  test(
    'sends bounded local context to configured AI responder after consent',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await LocalPrivacyRepository(db).setAiContextAllowed(true);
      await MedicationRepository(db).save(
        Medication(
          id: 'm1',
          name: 'Ramipril',
          dosage: '5mg',
          frequency: '1x taeglich',
          schedule: null,
          startDate: null,
          endDate: null,
          prescribedBy: null,
          reason: null,
          reminderEnabled: false,
          reminderTimes: const [],
          supplyDurationDays: null,
          refillReminderDays: null,
          notes: null,
          active: true,
        ),
      );
      await HealthRecordRepository(db).addAllergy(
        substance: 'Penicillin',
        category: 'Medikament',
        reaction: 'Ausschlag',
        severity: 'Schwer',
      );
      String? capturedContext;
      final answer = await AiCoachRepository(
        db,
        responder: ({required prompt, required context}) async {
          capturedContext = context;
          return 'Online-Antwort: $prompt';
        },
      ).ask('Was ist wichtig?');

      expect(answer.content, 'Online-Antwort: Was ist wichtig?');
      expect(answer.consentUsed, isTrue);
      expect(capturedContext, contains('Ramipril 5mg'));
      expect(capturedContext, contains('Penicillin'));
    },
  );

  test('shows clear AI failure without corrupting local history', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await LocalPrivacyRepository(db).setAiContextAllowed(true);

    final repo = AiCoachRepository(
      db,
      responder: ({required prompt, required context}) async {
        throw StateError('network down');
      },
    );
    final answer = await repo.ask('Bitte zusammenfassen');
    final messages = await repo.listMessages();

    expect(
      answer.content,
      contains('Online-KI-Dienst ist gerade nicht erreichbar'),
    );
    expect(answer.content, contains('Gesundheitsdaten wurden nicht verändert'));
    expect(messages, hasLength(2));
    expect(messages.last.content, answer.content);
  });
}
