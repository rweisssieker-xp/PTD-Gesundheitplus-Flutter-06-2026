class VaccinationRecord {
  const VaccinationRecord({
    required this.id,
    required this.vaccineName,
    this.targetDisease,
    required this.vaccinatedAt,
    this.nextDueAt,
    this.batchNumber,
    this.doctorName,
    this.notes,
  });

  final String id;
  final String vaccineName;
  final String? targetDisease;
  final DateTime vaccinatedAt;
  final DateTime? nextDueAt;
  final String? batchNumber;
  final String? doctorName;
  final String? notes;

  bool get boosterDue =>
      nextDueAt != null && !nextDueAt!.isAfter(DateTime.now());
}

class PreventiveCareItem {
  const PreventiveCareItem({
    required this.id,
    required this.title,
    required this.category,
    required this.dueAt,
    this.intervalMonths,
    required this.status,
    this.doctorName,
    this.notes,
  });

  final String id;
  final String title;
  final String category;
  final DateTime dueAt;
  final int? intervalMonths;
  final String status;
  final String? doctorName;
  final String? notes;

  bool get isDone => status == 'erledigt';

  bool get isDue => !isDone && !dueAt.isAfter(DateTime.now());
}

class HealthPass {
  const HealthPass({
    required this.id,
    required this.passType,
    required this.title,
    this.implantedAt,
    this.manufacturer,
    this.model,
    this.material,
    this.serialNumber,
    this.notes,
  });

  final String id;
  final String passType;
  final String title;
  final DateTime? implantedAt;
  final String? manufacturer;
  final String? model;
  final String? material;
  final String? serialNumber;
  final String? notes;
}

class PreventionRecommendation {
  const PreventionRecommendation({
    required this.title,
    required this.category,
    required this.reason,
    required this.urgency,
    required this.dueAt,
    this.intervalMonths,
    this.doctorName,
  });

  final String title;
  final String category;
  final String reason;
  final String urgency;
  final DateTime dueAt;
  final int? intervalMonths;
  final String? doctorName;

  bool get isHighPriority => urgency == 'hoch';
}

class PreventiveCareSnapshot {
  const PreventiveCareSnapshot({
    required this.items,
    required this.recommendations,
  });

  final List<PreventiveCareItem> items;
  final List<PreventionRecommendation> recommendations;
}
