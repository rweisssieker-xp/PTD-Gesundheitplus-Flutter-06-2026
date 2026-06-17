import 'health_document.dart';

class MedicalDocumentInsights {
  const MedicalDocumentInsights({
    required this.summary,
    required this.urgency,
    required this.requiresAttention,
    required this.findings,
    required this.entities,
    required this.actions,
  });

  final String summary;
  final InsightUrgency urgency;
  final bool requiresAttention;
  final List<String> findings;
  final List<MedicalEntity> entities;
  final List<SuggestedMedicalAction> actions;

  bool get hasDetails =>
      findings.isNotEmpty || entities.isNotEmpty || actions.isNotEmpty;
}

enum InsightUrgency {
  low('Niedrig'),
  medium('Mittel'),
  high('Hoch'),
  urgent('Dringend');

  const InsightUrgency(this.label);

  final String label;
}

class MedicalEntity {
  const MedicalEntity({required this.type, required this.label});

  final MedicalEntityType type;
  final String label;
}

enum MedicalEntityType {
  diagnosis('Diagnose'),
  medication('Medikament'),
  labResult('Laborwert'),
  allergy('Allergie'),
  vaccination('Impfung'),
  appointment('Termin'),
  procedure('Prozedur');

  const MedicalEntityType(this.label);

  final String label;
}

class SuggestedMedicalAction {
  const SuggestedMedicalAction({
    required this.label,
    required this.description,
    required this.priority,
  });

  final String label;
  final String description;
  final InsightUrgency priority;
}

class MedicalDocumentInsightAnalyzer {
  const MedicalDocumentInsightAnalyzer();

  MedicalDocumentInsights analyzeDocument(HealthDocument document) {
    return analyzeText(
      title: document.title,
      category: document.category,
      notes: document.notes,
    );
  }

  MedicalDocumentInsights analyzeText({
    required String title,
    required String category,
    String? notes,
  }) {
    final combined = [
      title,
      category,
      notes,
    ].whereType<String>().join(' ').toLowerCase();
    final entities = <MedicalEntity>[];
    final findings = <String>[];
    final actions = <SuggestedMedicalAction>[];
    var urgency = InsightUrgency.low;

    void addEntity(MedicalEntityType type, String label) {
      if (!entities.any(
        (entity) => entity.type == type && entity.label == label,
      )) {
        entities.add(MedicalEntity(type: type, label: label));
      }
    }

    if (_containsAny(combined, const ['labor', 'blutwert', 'hba1c', 'crp'])) {
      addEntity(MedicalEntityType.labResult, 'Laborbefund');
      findings.add('Labor- oder Blutwerte erkannt.');
      actions.add(
        const SuggestedMedicalAction(
          label: 'Laborwerte prüfen',
          description:
              'Auffällige oder neue Laborwerte mit der behandelnden Praxis besprechen.',
          priority: InsightUrgency.medium,
        ),
      );
    }
    if (_containsAny(combined, const ['rezept', 'medikament', 'dosierung'])) {
      addEntity(MedicalEntityType.medication, 'Medikation');
      findings.add('Medikationsbezug erkannt.');
      actions.add(
        const SuggestedMedicalAction(
          label: 'Medikation abgleichen',
          description:
              'Prüfen, ob dieses Dokument eine neue oder geänderte Medikation enthält.',
          priority: InsightUrgency.medium,
        ),
      );
    }
    if (_containsAny(combined, const ['allergie', 'unverträglichkeit'])) {
      addEntity(MedicalEntityType.allergy, 'Allergiehinweis');
      findings.add('Allergie- oder Unverträglichkeitshinweis erkannt.');
      actions.add(
        const SuggestedMedicalAction(
          label: 'Allergien aktualisieren',
          description:
              'Allergiehinweise mit der lokalen Allergieliste vergleichen.',
          priority: InsightUrgency.high,
        ),
      );
      urgency = InsightUrgency.high;
    }
    if (_containsAny(combined, const ['impfung', 'impfpass', 'booster'])) {
      addEntity(MedicalEntityType.vaccination, 'Impfung');
      findings.add('Impf- oder Auffrischungshinweis erkannt.');
      actions.add(
        const SuggestedMedicalAction(
          label: 'Impfpass ergänzen',
          description:
              'Impfung oder Auffrischungsdatum im lokalen Impfpass erfassen.',
          priority: InsightUrgency.medium,
        ),
      );
    }
    if (_containsAny(combined, const [
      'termin',
      'kontrolle',
      'wiedervorstellung',
    ])) {
      addEntity(MedicalEntityType.appointment, 'Termin');
      findings.add('Termin- oder Kontrollhinweis erkannt.');
      actions.add(
        const SuggestedMedicalAction(
          label: 'Termin planen',
          description:
              'Kontroll- oder Wiedervorstellungstermin in der Terminliste anlegen.',
          priority: InsightUrgency.medium,
        ),
      );
    }
    if (_containsAny(combined, const ['arztbrief', 'diagnose', 'befund'])) {
      addEntity(MedicalEntityType.diagnosis, 'Befund/Diagnose');
      findings.add('Befund- oder Diagnosebezug erkannt.');
    }
    if (_containsAny(combined, const [
      'operation',
      'op ',
      'eingriff',
      'prozedur',
    ])) {
      addEntity(MedicalEntityType.procedure, 'Behandlung/Eingriff');
      findings.add('Behandlung oder Eingriff erkannt.');
    }
    if (_containsAny(combined, const [
      'dringend',
      'sofort',
      'notfall',
      'kritisch',
    ])) {
      urgency = InsightUrgency.urgent;
      findings.add('Dringlichkeitsbegriff erkannt.');
      actions.add(
        const SuggestedMedicalAction(
          label: 'Ärztlich abklären',
          description:
              'Dokument zeitnah mit medizinischem Fachpersonal prüfen.',
          priority: InsightUrgency.urgent,
        ),
      );
    } else if (_containsAny(combined, const [
      'auffällig',
      'erhöht',
      'pathologisch',
    ])) {
      if (urgency == InsightUrgency.low) urgency = InsightUrgency.high;
      findings.add('Auffälliger medizinischer Hinweis erkannt.');
    }

    if (findings.isEmpty) {
      findings.add('Dokument wurde lokal gespeichert.');
    }

    return MedicalDocumentInsights(
      summary: 'Lokale Analyse für "$title": ${findings.take(3).join(' ')}',
      urgency: urgency,
      requiresAttention:
          urgency == InsightUrgency.high || urgency == InsightUrgency.urgent,
      findings: findings,
      entities: entities,
      actions: actions,
    );
  }

  bool _containsAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }
}
