import 'package:uuid/uuid.dart';

import '../../../core/ai/ai_context_builder.dart';
import '../../../core/storage/app_database.dart';
import '../../privacy/data/local_privacy_repository.dart';

typedef AiCoachResponder =
    Future<String> Function({required String prompt, required String context});

class AiCoachRepository {
  AiCoachRepository(this._db, {Uuid? uuid, AiCoachResponder? responder})
    : _uuid = uuid ?? const Uuid(),
      _responder = responder;

  final AppDatabase _db;
  final Uuid _uuid;
  final AiCoachResponder? _responder;

  Future<AiCoachMessage> ask(String question) async {
    final privacy = await LocalPrivacyRepository(_db).snapshot();
    final consent = privacy.aiContextAllowed;
    final now = DateTime.now().toIso8601String();
    _insert(role: 'user', content: question, consent: consent, createdAt: now);
    final answer = await _answer(question: question, consentAllowed: consent);
    _insert(
      role: 'assistant',
      content: answer,
      consent: consent,
      createdAt: now,
    );
    return AiCoachMessage(
      id: _uuid.v4(),
      role: 'assistant',
      content: answer,
      consentUsed: consent,
      createdAt: DateTime.parse(now),
    );
  }

  Future<String> _answer({
    required String question,
    required bool consentAllowed,
  }) async {
    if (!consentAllowed) {
      return 'Bitte aktiviere zuerst die KI-Kontextfreigabe im Datenschutzbereich. Deine Gesundheitsdaten bleiben lokal geschuetzt.';
    }
    final context = _buildHealthContext(consentAllowed: consentAllowed);
    final responder = _responder;
    if (responder == null) {
      return '${_localAnswer(question)}\n\nHinweis: Diese Antwort wurde lokal auf dem Gerät erzeugt; es wurde kein Online-KI-Dienst kontaktiert.';
    }
    try {
      return await responder(prompt: question, context: context);
    } catch (_) {
      return 'Der Online-KI-Dienst ist gerade nicht erreichbar. Deine Frage wurde lokal gespeichert; Gesundheitsdaten wurden nicht verändert. Bitte prüfe die Verbindung oder versuche es später erneut.';
    }
  }

  Future<List<AiCoachMessage>> listMessages() async {
    final rows = _db.select('''
      SELECT id, role, content, consent_used, created_at
      FROM ai_coach_messages
      ORDER BY created_at ASC
      ''');
    return rows
        .map(
          (row) => AiCoachMessage(
            id: row['id'] as String,
            role: row['role'] as String,
            content: row['content'] as String,
            consentUsed: row['consent_used'] == 1,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  void _insert({
    required String role,
    required String content,
    required bool consent,
    required String createdAt,
  }) {
    _db.execute(
      '''
      INSERT INTO ai_coach_messages (id, role, content, consent_used, created_at)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [_uuid.v4(), role, content, consent ? 1 : 0, createdAt],
    );
  }

  String _localAnswer(String question) {
    final lower = question.toLowerCase();
    if (lower.contains('medik') || lower.contains('tablett')) {
      return 'Ich kann deine lokale Medikationsliste beruecksichtigen. Bei neuen Beschwerden, Nebenwirkungen oder Unsicherheit bitte aerztlich pruefen lassen.';
    }
    if (lower.contains('termin')) {
      return 'Pruefe deine lokalen Termine und plane Erinnerungen mit ausreichend Vorlauf.';
    }
    return 'Ich kann lokal gespeicherte Gesundheitsdaten zusammenfassen und naechste Schritte strukturieren. Das ersetzt keine medizinische Diagnose.';
  }

  String _buildHealthContext({required bool consentAllowed}) {
    final medications = _db
        .select('''
          SELECT name, dosage
          FROM medications
          WHERE active = 1
          ORDER BY name ASC
          LIMIT 20
          ''')
        .map((row) {
          final dosage = row['dosage'] as String?;
          return [
            row['name'] as String,
            if (dosage != null && dosage.trim().isNotEmpty) dosage,
          ].join(' ');
        })
        .toList();
    final allergies = _db
        .select('''
          SELECT substance, severity
          FROM allergies
          ORDER BY substance ASC
          LIMIT 20
          ''')
        .map((row) {
          final severity = row['severity'] as String?;
          return [
            row['substance'] as String,
            if (severity != null && severity.trim().isNotEmpty) severity,
          ].join(' - ');
        })
        .toList();
    final diagnoses = _db
        .select('''
          SELECT title
          FROM medical_history_entries
          WHERE active = 1
          ORDER BY title ASC
          LIMIT 20
          ''')
        .map((row) => row['title'] as String)
        .toList();
    return AiContextBuilder().build(
      consentAllowed: consentAllowed,
      medications: medications,
      allergies: allergies,
      diagnoses: diagnoses,
    );
  }
}

class AiCoachMessage {
  const AiCoachMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.consentUsed,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String content;
  final bool consentUsed;
  final DateTime createdAt;
}
