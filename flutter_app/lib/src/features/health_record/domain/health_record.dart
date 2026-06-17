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
