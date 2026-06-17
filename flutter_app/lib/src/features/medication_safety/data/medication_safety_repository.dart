import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../medication/data/medication_repository.dart';
import '../domain/medication_safety.dart';

class MedicationSafetyRepository {
  MedicationSafetyRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addGuidance({
    required String title,
    required String severity,
    required String description,
    String? action,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO medication_interaction_guidance (
        id, title, severity, description, action, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [_uuid.v4(), title, severity, description, action, now, now],
    );
  }

  Future<List<MedicationInteractionGuidance>> listGuidance() async {
    final rows = _db.select('''
      SELECT id, title, severity, description, action
      FROM medication_interaction_guidance
      ORDER BY created_at DESC
      ''');
    return rows
        .map(
          (row) => MedicationInteractionGuidance(
            id: row['id'] as String,
            title: row['title'] as String,
            severity: row['severity'] as String,
            description: row['description'] as String,
            action: row['action'] as String?,
          ),
        )
        .toList();
  }

  Future<MedicationInteractionCheck> runLocalCheck({
    required bool consentAllowed,
  }) async {
    final medications = await MedicationRepository(_db).listActive();
    final names = medications.map((medication) => medication.name).toList();
    final summary = _buildSummary(names);
    final riskLevel = summary.contains('Blutungsrisiko') ? 'hoch' : 'niedrig';
    final now = DateTime.now();
    final check = MedicationInteractionCheck(
      id: _uuid.v4(),
      medicationNames: names,
      riskLevel: riskLevel,
      summary: consentAllowed
          ? summary
          : 'Nicht ausgefuehrt: KI-/Kontextfreigabe fehlt. Lokale Medikamentenliste bleibt geschuetzt.',
      consentUsed: consentAllowed,
      checkedAt: now,
    );
    _db.execute(
      '''
      INSERT INTO medication_interaction_checks (
        id, medication_names, risk_level, summary, consent_used, checked_at, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        check.id,
        jsonEncode(check.medicationNames),
        check.riskLevel,
        check.summary,
        check.consentUsed ? 1 : 0,
        now.toIso8601String(),
        now.toIso8601String(),
        now.toIso8601String(),
      ],
    );
    return check;
  }

  Future<List<MedicationInteractionCheck>> listChecks() async {
    final rows = _db.select('''
      SELECT id, medication_names, risk_level, summary, consent_used, checked_at
      FROM medication_interaction_checks
      ORDER BY checked_at DESC
      ''');
    return rows
        .map(
          (row) => MedicationInteractionCheck(
            id: row['id'] as String,
            medicationNames:
                (jsonDecode(row['medication_names'] as String) as List<dynamic>)
                    .cast<String>(),
            riskLevel: row['risk_level'] as String,
            summary: row['summary'] as String,
            consentUsed: row['consent_used'] == 1,
            checkedAt: DateTime.parse(row['checked_at'] as String),
          ),
        )
        .toList();
  }

  String _buildSummary(List<String> names) {
    final lower = names.map((name) => name.toLowerCase()).toList();
    final hasAss = lower.any(
      (name) => name.contains('ass') || name.contains('aspirin'),
    );
    final hasBloodThinner = lower.any(
      (name) =>
          name.contains('warfarin') ||
          name.contains('marcumar') ||
          name.contains('apixaban') ||
          name.contains('rivaroxaban'),
    );
    if (names.isEmpty) {
      return 'Keine aktive Medikation fuer einen Check vorhanden.';
    }
    if (hasAss && hasBloodThinner) {
      return 'Blutungsrisiko moeglich: ASS/Aspirin zusammen mit Antikoagulanzien aerztlich pruefen lassen.';
    }
    return 'Keine lokale Hochrisiko-Regel getroffen. Ergebnis ersetzt keine aerztliche Pruefung.';
  }
}
