import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/prevention.dart';

class PreventionRepository {
  PreventionRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addVaccination({
    required String vaccineName,
    String? targetDisease,
    DateTime? vaccinatedAt,
    DateTime? nextDueAt,
    String? batchNumber,
    String? doctorName,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO vaccinations (
        id, vaccine_name, target_disease, vaccinated_at, next_due_at,
        batch_number, doctor_name, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        vaccineName,
        targetDisease,
        (vaccinatedAt ?? DateTime.now()).toIso8601String(),
        nextDueAt?.toIso8601String(),
        batchNumber,
        doctorName,
        notes,
        now,
        now,
      ],
    );
  }

  Future<List<VaccinationRecord>> listVaccinations() async {
    final rows = _db.select('''
      SELECT id, vaccine_name, target_disease, vaccinated_at, next_due_at,
             batch_number, doctor_name, notes
      FROM vaccinations
      ORDER BY vaccinated_at DESC
      ''');
    return rows
        .map(
          (row) => VaccinationRecord(
            id: row['id'] as String,
            vaccineName: row['vaccine_name'] as String,
            targetDisease: row['target_disease'] as String?,
            vaccinatedAt: DateTime.parse(row['vaccinated_at'] as String),
            nextDueAt: _date(row['next_due_at']),
            batchNumber: row['batch_number'] as String?,
            doctorName: row['doctor_name'] as String?,
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<PreventiveCareItem> addPreventiveCare({
    required String title,
    required String category,
    required DateTime dueAt,
    int? intervalMonths,
    String? doctorName,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    _db.execute(
      '''
      INSERT INTO preventive_care_items (
        id, title, category, due_at, interval_months, status,
        doctor_name, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, 'offen', ?, ?, ?, ?)
      ''',
      [
        id,
        title,
        category,
        dueAt.toIso8601String(),
        intervalMonths,
        doctorName,
        notes,
        now,
        now,
      ],
    );
    return PreventiveCareItem(
      id: id,
      title: title,
      category: category,
      dueAt: dueAt,
      intervalMonths: intervalMonths,
      status: 'offen',
      doctorName: doctorName,
      notes: notes,
    );
  }

  Future<List<PreventiveCareItem>> listPreventiveCare() async {
    final rows = _db.select('''
      SELECT id, title, category, due_at, interval_months, status, doctor_name, notes
      FROM preventive_care_items
      ORDER BY due_at ASC
      ''');
    return rows
        .map(
          (row) => PreventiveCareItem(
            id: row['id'] as String,
            title: row['title'] as String,
            category: row['category'] as String,
            dueAt: DateTime.parse(row['due_at'] as String),
            intervalMonths: row['interval_months'] as int?,
            status: row['status'] as String,
            doctorName: row['doctor_name'] as String?,
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<PreventiveCareSnapshot> snapshot({DateTime? now}) async {
    final items = await listPreventiveCare();
    final recommendations = await generateRecommendations(now: now);
    return PreventiveCareSnapshot(
      items: items,
      recommendations: recommendations,
    );
  }

  Future<List<PreventionRecommendation>> generateRecommendations({
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final age = _currentAge(today);
    if (age == null) return const [];

    final vaccinations = await listVaccinations();
    final careItems = await listPreventiveCare();
    final recommendations = <PreventionRecommendation>[];

    void addVaccination({
      required String title,
      required int intervalYears,
      required String reasonIfMissing,
      String urgency = 'mittel',
    }) {
      final last = _lastVaccination(vaccinations, title);
      final dueAt = last == null
          ? today
          : DateTime(
              last.vaccinatedAt.year + intervalYears,
              last.vaccinatedAt.month,
              last.vaccinatedAt.day,
            );
      if (last == null || !dueAt.isAfter(today)) {
        recommendations.add(
          PreventionRecommendation(
            title: title,
            category: 'Impfung',
            reason: last == null
                ? reasonIfMissing
                : 'Auffrischung fällig: letzte Impfung vor ${today.year - last.vaccinatedAt.year} Jahren.',
            urgency: urgency,
            dueAt: dueAt,
            intervalMonths: intervalYears * 12,
            doctorName: 'Hausarztpraxis',
          ),
        );
      }
    }

    addVaccination(
      title: 'Tetanus',
      intervalYears: 10,
      reasonIfMissing: 'Grundimmunisierung oder Auffrischung dokumentieren.',
      urgency: 'hoch',
    );
    addVaccination(
      title: 'Diphtherie',
      intervalYears: 10,
      reasonIfMissing: 'Schutzstatus dokumentieren.',
      urgency: 'hoch',
    );
    addVaccination(
      title: 'Pertussis',
      intervalYears: 10,
      reasonIfMissing: 'Keuchhusten-Schutz prüfen.',
    );
    addVaccination(
      title: 'COVID-19',
      intervalYears: 1,
      reasonIfMissing:
          'Auffrischung prüfen, wenn kein aktueller Eintrag vorliegt.',
    );
    addVaccination(
      title: 'FSME',
      intervalYears: 3,
      reasonIfMissing: 'Empfohlen bei Aufenthalt in Risikogebieten.',
      urgency: 'niedrig',
    );

    if (age >= 60) {
      addVaccination(
        title: 'Influenza',
        intervalYears: 1,
        reasonIfMissing: 'Jährlich empfohlen ab 60 Jahren.',
      );
      addVaccination(
        title: 'Pneumokokken',
        intervalYears: 6,
        reasonIfMissing: 'Empfohlen ab 60 Jahren.',
      );
      addVaccination(
        title: 'Gürtelrose',
        intervalYears: 99,
        reasonIfMissing: 'Empfohlen ab 60 Jahren.',
      );
    }

    void addScreening({
      required String title,
      required int minAge,
      required int intervalMonths,
      required String reason,
      String category = 'Screening',
      String urgency = 'mittel',
      String? doctorName,
    }) {
      if (age < minAge ||
          _hasOpenOrRecentCare(careItems, title, today, intervalMonths)) {
        return;
      }
      recommendations.add(
        PreventionRecommendation(
          title: title,
          category: category,
          reason: reason,
          urgency: urgency,
          dueAt: today,
          intervalMonths: intervalMonths,
          doctorName: doctorName,
        ),
      );
    }

    addScreening(
      title: 'Gesundheits-Check-up',
      minAge: 35,
      intervalMonths: 36,
      reason:
          'Früherkennung von Herz-Kreislauf-Erkrankungen, Nierenerkrankungen und Diabetes.',
      category: 'Check-up',
      doctorName: 'Hausarztpraxis',
    );
    addScreening(
      title: 'Hautkrebsvorsorge',
      minAge: 35,
      intervalMonths: 24,
      reason: 'Früherkennung von Hautkrebs.',
      doctorName: 'Dermatologie',
    );
    addScreening(
      title: 'Darmkrebsvorsorge',
      minAge: 50,
      intervalMonths: 120,
      reason: 'Früherkennung von Darmkrebs ab 50 Jahren.',
      urgency: 'hoch',
      doctorName: 'Gastroenterologie',
    );

    recommendations.sort((a, b) {
      final urgency = _urgencyRank(
        a.urgency,
      ).compareTo(_urgencyRank(b.urgency));
      if (urgency != 0) return urgency;
      return a.dueAt.compareTo(b.dueAt);
    });
    return recommendations;
  }

  Future<void> markPreventiveCareDone(String id) async {
    _db.execute(
      '''
      UPDATE preventive_care_items
      SET status = 'erledigt', updated_at = ?
      WHERE id = ?
      ''',
      [DateTime.now().toIso8601String(), id],
    );
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  int? _currentAge(DateTime now) {
    final rows = _db.select(
      "SELECT date_of_birth FROM local_profiles WHERE id = 'default' LIMIT 1",
    );
    if (rows.isEmpty || rows.first['date_of_birth'] == null) return null;
    final birthDate = DateTime.tryParse(rows.first['date_of_birth'] as String);
    if (birthDate == null) return null;
    var age = now.year - birthDate.year;
    if (DateTime(now.year, birthDate.month, birthDate.day).isAfter(now)) {
      age--;
    }
    return age;
  }

  VaccinationRecord? _lastVaccination(
    List<VaccinationRecord> records,
    String title,
  ) {
    final normalizedTitle = _normalize(title);
    final matches = records.where((record) {
      final name = _normalize(record.vaccineName);
      final target = _normalize(record.targetDisease ?? '');
      return name.contains(normalizedTitle) ||
          normalizedTitle.contains(name) ||
          target.contains(normalizedTitle);
    }).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.vaccinatedAt.compareTo(a.vaccinatedAt));
    return matches.first;
  }

  bool _hasOpenOrRecentCare(
    List<PreventiveCareItem> items,
    String title,
    DateTime now,
    int intervalMonths,
  ) {
    final normalizedTitle = _normalize(title);
    final cutoff = DateTime(now.year, now.month - intervalMonths, now.day);
    return items.any((item) {
      final itemTitle = _normalize('${item.title} ${item.category}');
      if (!itemTitle.contains(normalizedTitle) &&
          !normalizedTitle.contains(itemTitle)) {
        return false;
      }
      if (!item.isDone) return true;
      return item.dueAt.isAfter(cutoff);
    });
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');

  int _urgencyRank(String urgency) {
    switch (urgency) {
      case 'hoch':
        return 0;
      case 'mittel':
        return 1;
      default:
        return 2;
    }
  }
}
