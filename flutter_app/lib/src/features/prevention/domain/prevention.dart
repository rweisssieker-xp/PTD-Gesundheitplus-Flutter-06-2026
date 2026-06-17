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
