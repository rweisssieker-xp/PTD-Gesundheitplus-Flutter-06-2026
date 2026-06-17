enum MedicationIntakeDecision { taken, skipped, unknown }

class MedicationIntakeTextResult {
  const MedicationIntakeTextResult({
    required this.decision,
    required this.note,
  });

  final MedicationIntakeDecision decision;
  final String note;
}

class MedicationIntakeTextParser {
  const MedicationIntakeTextParser();

  MedicationIntakeTextResult parse(String text) {
    final normalized = _normalize(text);
    if (_containsAny(normalized, const [
      'nicht genommen',
      'nicht eingenommen',
      'nein',
      'vergessen',
      'ausgelassen',
      'uebersprungen',
      'übersprungen',
    ])) {
      return MedicationIntakeTextResult(
        decision: MedicationIntakeDecision.skipped,
        note: text.trim(),
      );
    }
    if (_containsAny(normalized, const [
      'eingenommen',
      'genommen',
      'ja',
      'bestaetigt',
      'bestätigt',
      'erledigt',
      'habe ich',
    ])) {
      return MedicationIntakeTextResult(
        decision: MedicationIntakeDecision.taken,
        note: text.trim(),
      );
    }
    return MedicationIntakeTextResult(
      decision: MedicationIntakeDecision.unknown,
      note: text.trim(),
    );
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
