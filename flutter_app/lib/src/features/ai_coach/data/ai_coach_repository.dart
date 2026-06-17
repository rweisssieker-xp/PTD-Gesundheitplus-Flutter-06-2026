import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../privacy/data/local_privacy_repository.dart';

class AiCoachRepository {
  AiCoachRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<AiCoachMessage> ask(String question) async {
    final privacy = await LocalPrivacyRepository(_db).snapshot();
    final consent = privacy.aiContextAllowed;
    final now = DateTime.now().toIso8601String();
    _insert(role: 'user', content: question, consent: consent, createdAt: now);
    final answer = consent
        ? _localAnswer(question)
        : 'Bitte aktiviere zuerst die KI-Kontextfreigabe im Datenschutzbereich. Deine Gesundheitsdaten bleiben lokal geschuetzt.';
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
