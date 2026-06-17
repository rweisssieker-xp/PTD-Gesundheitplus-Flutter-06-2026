class MedicalHistoryEntry {
  const MedicalHistoryEntry({
    required this.id,
    required this.category,
    required this.title,
    this.details,
    this.occurredAt,
    required this.active,
  });

  final String id;
  final String category;
  final String title;
  final String? details;
  final DateTime? occurredAt;
  final bool active;
}

class TreatmentRecord {
  const TreatmentRecord({
    required this.id,
    required this.title,
    this.provider,
    this.specialty,
    required this.treatedAt,
    this.outcome,
    this.notes,
  });

  final String id;
  final String title;
  final String? provider;
  final String? specialty;
  final DateTime treatedAt;
  final String? outcome;
  final String? notes;
}

class AllergyRecord {
  const AllergyRecord({
    required this.id,
    required this.substance,
    this.category,
    this.reaction,
    this.severity,
    this.diagnosedAt,
    this.diagnosedBy,
    this.notes,
  });

  final String id;
  final String substance;
  final String? category;
  final String? reaction;
  final String? severity;
  final DateTime? diagnosedAt;
  final String? diagnosedBy;
  final String? notes;
}

class AllergyMedicationCheckResult {
  const AllergyMedicationCheckResult({
    required this.activeMedicationCount,
    required this.medicationAllergyCount,
    required this.conflicts,
  });

  final int activeMedicationCount;
  final int medicationAllergyCount;
  final List<AllergyMedicationConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;

  String get overallRisk {
    if (conflicts.any((conflict) => conflict.severity == 'Kontraindiziert')) {
      return 'kritisch';
    }
    if (conflicts.any((conflict) => conflict.severity == 'Schwerwiegend')) {
      return 'hoch';
    }
    if (conflicts.any((conflict) => conflict.severity == 'Moderat')) {
      return 'moderat';
    }
    return 'niedrig';
  }

  String get summary {
    if (conflicts.isEmpty) {
      return 'Keine lokalen Medikamenten-Allergie-Konflikte erkannt.';
    }
    return '${conflicts.length} moegliche Medikamenten-Allergie-Konflikte erkannt. Bitte aerztlich oder pharmazeutisch pruefen.';
  }
}

class AllergyMedicationConflict {
  const AllergyMedicationConflict({
    required this.medicationName,
    required this.allergen,
    required this.severity,
    required this.description,
    required this.recommendation,
  });

  final String medicationName;
  final String allergen;
  final String severity;
  final String description;
  final String recommendation;
}
