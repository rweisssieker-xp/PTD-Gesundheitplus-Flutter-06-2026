import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/documents/domain/medical_document_insights.dart';

void main() {
  test('detects local medical entities and suggested actions', () {
    final insights = const MedicalDocumentInsightAnalyzer().analyzeText(
      title: 'Laborbefund und Rezept',
      category: 'Laborbefund',
      notes: 'CRP auffällig. Neues Medikament mit Dosierung dokumentiert.',
    );

    expect(insights.urgency, InsightUrgency.high);
    expect(
      insights.entities.map((entity) => entity.type),
      containsAll([MedicalEntityType.labResult, MedicalEntityType.medication]),
    );
    expect(
      insights.actions.map((action) => action.label),
      containsAll(['Laborwerte prüfen', 'Medikation abgleichen']),
    );
  });

  test('marks urgent documents as requiring attention', () {
    final insights = const MedicalDocumentInsightAnalyzer().analyzeText(
      title: 'Arztbrief',
      category: 'Befund',
      notes: 'Kritisch, bitte sofort ärztlich abklären.',
    );

    expect(insights.urgency, InsightUrgency.urgent);
    expect(insights.requiresAttention, isTrue);
    expect(
      insights.actions.map((action) => action.label),
      contains('Ärztlich abklären'),
    );
  });
}
