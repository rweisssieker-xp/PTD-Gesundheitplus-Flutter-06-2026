class AiContextBuilder {
  String build({
    required bool consentAllowed,
    required List<String> medications,
    required List<String> allergies,
    required List<String> diagnoses,
  }) {
    if (!consentAllowed) {
      throw StateError('AI context requires user consent');
    }
    return [
      'Lokaler Gesundheitskontext fuer Gesundheit Plus:',
      'Aktive Medikamente: ${_join(medications)}',
      'Allergien: ${_join(allergies)}',
      'Diagnosen: ${_join(diagnoses)}',
    ].join('\n');
  }

  String _join(List<String> values) =>
      values.isEmpty ? 'Keine Eintraege' : values.take(20).join(', ');
}
