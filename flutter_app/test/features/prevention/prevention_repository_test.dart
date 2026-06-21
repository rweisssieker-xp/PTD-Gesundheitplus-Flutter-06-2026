import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/onboarding/data/local_profile_repository.dart';
import 'package:gesundheitplus/src/features/prevention/data/prevention_repository.dart';

void main() {
  test('stores vaccination records', () async {
    final db = AppDatabase.memory();
    final repo = PreventionRepository(db);
    await repo.addVaccination(
      vaccineName: 'Tetanus',
      targetDisease: 'Wundstarrkrampf',
      vaccinatedAt: DateTime(2026, 1, 10),
      nextDueAt: DateTime(2026, 6, 1),
    );
    final records = await repo.listVaccinations();
    expect(records.single.vaccineName, 'Tetanus');
    expect(records.single.targetDisease, 'Wundstarrkrampf');
    expect(records.single.boosterDue, isTrue);
    db.close();
  });

  test('stores and completes preventive care items', () async {
    final db = AppDatabase.memory();
    final repo = PreventionRepository(db);
    await repo.addPreventiveCare(
      title: 'Hautscreening',
      category: 'Screening',
      dueAt: DateTime(2026, 6, 1),
      intervalMonths: 24,
    );
    final created = await repo.listPreventiveCare();
    expect(created.single.isDue, isTrue);
    await repo.markPreventiveCareDone(created.single.id);
    final completed = await repo.listPreventiveCare();
    expect(completed.single.isDone, isTrue);
    db.close();
  });

  test('stores updates and deletes local health passes', () async {
    final db = AppDatabase.memory();
    final repo = PreventionRepository(db);
    final created = await repo.addHealthPass(
      passType: 'Implantatpass',
      title: 'Implantatpass Knie',
      implantedAt: DateTime(2024, 5, 1),
      manufacturer: 'MediCorp',
      model: 'K-42',
      material: 'Titan',
      serialNumber: 'SN123',
      notes: 'MRT-Hinweis beachten',
    );

    var passes = await repo.listHealthPasses();
    expect(passes.single.title, 'Implantatpass Knie');
    expect(passes.single.manufacturer, 'MediCorp');
    expect(passes.single.serialNumber, 'SN123');

    await repo.updateHealthPass(
      created.id,
      passType: 'Endoprothese',
      title: 'Knie-Endoprothese',
      implantedAt: DateTime(2024, 5, 2),
      manufacturer: 'MediCorp',
      model: 'K-43',
      material: 'Keramik',
      serialNumber: 'SN124',
      notes: 'Kontrolle jaehrlich',
    );

    passes = await repo.listHealthPasses();
    expect(passes.single.passType, 'Endoprothese');
    expect(passes.single.title, 'Knie-Endoprothese');
    expect(passes.single.model, 'K-43');
    expect(passes.single.material, 'Keramik');

    await repo.deleteHealthPass(created.id);
    expect(await repo.listHealthPasses(), isEmpty);
    db.close();
  });

  test('generates local age-based prevention recommendations', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await LocalProfileRepository(
      db,
    ).saveProfile(fullName: 'Patient', dateOfBirth: DateTime(1960, 1, 1));
    final repo = PreventionRepository(db);
    await repo.addVaccination(
      vaccineName: 'Tetanus',
      vaccinatedAt: DateTime(2025, 1, 1),
    );

    final recommendations = await repo.generateRecommendations(
      now: DateTime(2026, 6, 17),
    );

    expect(recommendations.map((item) => item.title), contains('Influenza'));
    expect(recommendations.map((item) => item.title), contains('Gürtelrose'));
    expect(
      recommendations.map((item) => item.title),
      contains('Darmkrebsvorsorge'),
    );
    expect(
      recommendations.map((item) => item.title),
      isNot(contains('Tetanus')),
    );
  });

  test(
    'does not recommend screenings without profile or when already planned',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final repo = PreventionRepository(db);

      expect(
        await repo.generateRecommendations(now: DateTime(2026, 6, 17)),
        isEmpty,
      );

      await LocalProfileRepository(
        db,
      ).saveProfile(fullName: 'Patient', dateOfBirth: DateTime(1980, 1, 1));
      await repo.addPreventiveCare(
        title: 'Gesundheits-Check-up',
        category: 'Check-up',
        dueAt: DateTime(2026, 7, 1),
      );

      final recommendations = await repo.generateRecommendations(
        now: DateTime(2026, 6, 17),
      );

      expect(
        recommendations.map((item) => item.title),
        isNot(contains('Gesundheits-Check-up')),
      );
      expect(
        recommendations.map((item) => item.title),
        contains('Hautkrebsvorsorge'),
      );
    },
  );
}
