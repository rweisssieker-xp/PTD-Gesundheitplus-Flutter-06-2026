import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/health_record.dart';

class HealthRecordRepository {
  HealthRecordRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addHistoryEntry({
    required String category,
    required String title,
    String? details,
    DateTime? occurredAt,
    bool active = true,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO medical_history_entries (
        id, category, title, details, occurred_at, active, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        category,
        title,
        details,
        occurredAt?.toIso8601String(),
        active ? 1 : 0,
        now,
        now,
      ],
    );
  }

  Future<List<MedicalHistoryEntry>> listHistoryEntries() async {
    final rows = _db.select('''
      SELECT id, category, title, details, occurred_at, active
      FROM medical_history_entries
      ORDER BY category ASC, title ASC
      ''');
    return rows
        .map(
          (row) => MedicalHistoryEntry(
            id: row['id'] as String,
            category: row['category'] as String,
            title: row['title'] as String,
            details: row['details'] as String?,
            occurredAt: _date(row['occurred_at']),
            active: row['active'] == 1,
          ),
        )
        .toList();
  }

  Future<void> deleteHistoryEntry(String id) async {
    _db.execute('DELETE FROM medical_history_entries WHERE id = ?', [id]);
  }

  Future<void> addTreatment({
    required String title,
    String? provider,
    String? specialty,
    DateTime? treatedAt,
    String? outcome,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO treatment_records (
        id, title, provider, specialty, treated_at, outcome, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        title,
        provider,
        specialty,
        (treatedAt ?? DateTime.now()).toIso8601String(),
        outcome,
        notes,
        now,
        now,
      ],
    );
  }

  Future<List<TreatmentRecord>> listTreatments() async {
    final rows = _db.select('''
      SELECT id, title, provider, specialty, treated_at, outcome, notes
      FROM treatment_records
      ORDER BY treated_at DESC
      ''');
    return rows
        .map(
          (row) => TreatmentRecord(
            id: row['id'] as String,
            title: row['title'] as String,
            provider: row['provider'] as String?,
            specialty: row['specialty'] as String?,
            treatedAt: DateTime.parse(row['treated_at'] as String),
            outcome: row['outcome'] as String?,
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<void> deleteTreatment(String id) async {
    _db.execute('DELETE FROM treatment_records WHERE id = ?', [id]);
  }

  Future<void> addAllergy({
    required String substance,
    String? category,
    String? reaction,
    String? severity,
    DateTime? diagnosedAt,
    String? diagnosedBy,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO allergies (
        id, substance, category, reaction, severity, diagnosed_at, diagnosed_by, notes, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        substance,
        category,
        reaction,
        severity,
        diagnosedAt?.toIso8601String(),
        diagnosedBy,
        notes,
        now,
        now,
      ],
    );
  }

  Future<void> updateAllergy({
    required String id,
    required String substance,
    String? category,
    String? reaction,
    String? severity,
    DateTime? diagnosedAt,
    String? diagnosedBy,
    String? notes,
  }) async {
    _db.execute(
      '''
      UPDATE allergies
      SET substance = ?,
          category = ?,
          reaction = ?,
          severity = ?,
          diagnosed_at = ?,
          diagnosed_by = ?,
          notes = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        substance,
        category,
        reaction,
        severity,
        diagnosedAt?.toIso8601String(),
        diagnosedBy,
        notes,
        DateTime.now().toIso8601String(),
        id,
      ],
    );
  }

  Future<List<AllergyRecord>> listAllergies() async {
    final rows = _db.select('''
      SELECT id, substance, category, reaction, severity, diagnosed_at, diagnosed_by, notes
      FROM allergies
      ORDER BY
        CASE severity
          WHEN 'Lebensbedrohlich' THEN 0
          WHEN 'Schwer' THEN 1
          WHEN 'Mittel' THEN 2
          WHEN 'Leicht' THEN 3
          ELSE 4
        END,
        substance ASC
      ''');
    return rows
        .map(
          (row) => AllergyRecord(
            id: row['id'] as String,
            substance: row['substance'] as String,
            category: row['category'] as String?,
            reaction: row['reaction'] as String?,
            severity: row['severity'] as String?,
            diagnosedAt: _date(row['diagnosed_at']),
            diagnosedBy: row['diagnosed_by'] as String?,
            notes: row['notes'] as String?,
          ),
        )
        .toList();
  }

  Future<AllergyMedicationCheckResult> checkMedicationAllergies() async {
    final medicationRows = _db.select('''
      SELECT name
      FROM medications
      WHERE active = 1
      ORDER BY name COLLATE NOCASE
      ''');
    final medicationNames = medicationRows
        .map((row) => row['name'] as String)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final allergies = (await listAllergies())
        .where(
          (allergy) =>
              _normalize(allergy.category ?? '') == 'medikament' ||
              _looksLikeMedicationAllergy(allergy.substance),
        )
        .toList();
    final conflicts = <AllergyMedicationConflict>[];
    final seen = <String>{};

    for (final medication in medicationNames) {
      final medicationTokens = _tokens(medication);
      for (final allergy in allergies) {
        final conflict = _matchMedicationAllergy(
          medicationName: medication,
          medicationTokens: medicationTokens,
          allergy: allergy,
        );
        if (conflict == null) continue;
        final key =
            '${_normalize(conflict.medicationName)}|${_normalize(conflict.allergen)}|${conflict.severity}';
        if (seen.add(key)) conflicts.add(conflict);
      }
    }

    conflicts.sort((a, b) {
      final severity = _severityRank(
        a.severity,
      ).compareTo(_severityRank(b.severity));
      if (severity != 0) return severity;
      return a.medicationName.compareTo(b.medicationName);
    });
    return AllergyMedicationCheckResult(
      activeMedicationCount: medicationNames.length,
      medicationAllergyCount: allergies.length,
      conflicts: conflicts,
    );
  }

  Future<void> deleteAllergy(String id) async {
    _db.execute('DELETE FROM allergies WHERE id = ?', [id]);
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  AllergyMedicationConflict? _matchMedicationAllergy({
    required String medicationName,
    required Set<String> medicationTokens,
    required AllergyRecord allergy,
  }) {
    final allergenTokens = _tokens(allergy.substance);
    final overlap = medicationTokens.intersection(allergenTokens);
    final severe =
        allergy.severity == 'Schwer' || allergy.severity == 'Lebensbedrohlich';
    if (overlap.isNotEmpty) {
      return AllergyMedicationConflict(
        medicationName: medicationName,
        allergen: allergy.substance,
        severity: severe ? 'Kontraindiziert' : 'Schwerwiegend',
        description:
            'Der Medikamentenname passt direkt zu einer gespeicherten Medikamenten-Allergie.',
        recommendation:
            'Vor Einnahme unbedingt Arzt oder Apotheke kontaktieren und Alternativen pruefen.',
      );
    }

    for (final rule in _allergyRules) {
      if (!rule.allergyTerms.any(allergenTokens.contains)) continue;
      if (!rule.medicationTerms.any(medicationTokens.contains)) continue;
      return AllergyMedicationConflict(
        medicationName: medicationName,
        allergen: allergy.substance,
        severity: severe ? rule.highSeverity : rule.severity,
        description: rule.description,
        recommendation: rule.recommendation,
      );
    }
    return null;
  }

  bool _looksLikeMedicationAllergy(String value) {
    final tokens = _tokens(value);
    return _allergyRules.any((rule) => rule.allergyTerms.any(tokens.contains));
  }

  Set<String> _tokens(String value) {
    final normalized = _normalize(value);
    final base = normalized
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 3)
        .toSet();
    return {
      ...base,
      if (normalized.contains('acetylsalicyl')) 'ass',
      if (normalized.contains('ibuprofen')) 'nsaid',
      if (normalized.contains('diclofenac')) 'nsaid',
      if (normalized.contains('naproxen')) 'nsaid',
      if (normalized.contains('amoxicillin')) 'penicillin',
      if (normalized.contains('ampicillin')) 'penicillin',
      if (normalized.contains('cefal') || normalized.contains('ceph'))
        'betalaktam',
      if (normalized.contains('sulf')) 'sulfonamid',
    };
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');

  int _severityRank(String severity) {
    switch (severity) {
      case 'Kontraindiziert':
        return 0;
      case 'Schwerwiegend':
        return 1;
      case 'Moderat':
        return 2;
      default:
        return 3;
    }
  }
}

class _AllergyMedicationRule {
  const _AllergyMedicationRule({
    required this.allergyTerms,
    required this.medicationTerms,
    required this.severity,
    required this.highSeverity,
    required this.description,
    required this.recommendation,
  });

  final Set<String> allergyTerms;
  final Set<String> medicationTerms;
  final String severity;
  final String highSeverity;
  final String description;
  final String recommendation;
}

const _allergyRules = [
  _AllergyMedicationRule(
    allergyTerms: {'penicillin', 'betalaktam'},
    medicationTerms: {'penicillin', 'betalaktam'},
    severity: 'Schwerwiegend',
    highSeverity: 'Kontraindiziert',
    description:
        'Penicillin- oder Betalaktam-Allergie kann mit diesem Antibiotikum kollidieren.',
    recommendation:
        'Antibiotikum nicht ohne aerztliche Ruecksprache einnehmen; Allergiepass vorzeigen.',
  ),
  _AllergyMedicationRule(
    allergyTerms: {'ass', 'aspirin', 'nsaid'},
    medicationTerms: {'ass', 'aspirin', 'nsaid'},
    severity: 'Schwerwiegend',
    highSeverity: 'Kontraindiziert',
    description:
        'ASS/NSAR-Allergie kann bei Schmerzmitteln aus derselben Wirkstoffgruppe relevant sein.',
    recommendation:
        'Vor Einnahme alternative Schmerzmittel mit Arzt oder Apotheke abstimmen.',
  ),
  _AllergyMedicationRule(
    allergyTerms: {'sulfonamid'},
    medicationTerms: {'sulfonamid'},
    severity: 'Moderat',
    highSeverity: 'Schwerwiegend',
    description:
        'Sulfonamid-Allergie kann bei sulfonamidhaltigen Medikamenten relevant sein.',
    recommendation:
        'Packungsbeilage und Verordnung pharmazeutisch pruefen lassen.',
  ),
];
