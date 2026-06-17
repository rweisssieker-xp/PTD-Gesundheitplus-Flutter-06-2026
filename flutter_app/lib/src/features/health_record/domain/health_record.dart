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
