class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.schedule,
    required this.startDate,
    required this.endDate,
    required this.prescribedBy,
    required this.reason,
    required this.reminderEnabled,
    required this.reminderTimes,
    required this.refillReminderDays,
    required this.notes,
    required this.active,
  });

  final String id;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? schedule;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? prescribedBy;
  final String? reason;
  final bool reminderEnabled;
  final List<String> reminderTimes;
  final int? refillReminderDays;
  final String? notes;
  final bool active;

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    String? schedule,
    DateTime? startDate,
    DateTime? endDate,
    String? prescribedBy,
    String? reason,
    bool? reminderEnabled,
    List<String>? reminderTimes,
    int? refillReminderDays,
    String? notes,
    bool? active,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      schedule: schedule ?? this.schedule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      reason: reason ?? this.reason,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      refillReminderDays: refillReminderDays ?? this.refillReminderDays,
      notes: notes ?? this.notes,
      active: active ?? this.active,
    );
  }
}

class MedicationLog {
  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.dosageTaken,
    required this.status,
    required this.date,
    required this.takenAt,
    required this.notes,
    required this.confirmedByVoice,
  });

  final String id;
  final String medicationId;
  final String medicationName;
  final String scheduledTime;
  final String? dosageTaken;
  final MedicationLogStatus status;
  final DateTime date;
  final DateTime? takenAt;
  final String? notes;
  final bool confirmedByVoice;
}

enum MedicationLogStatus {
  pending,
  taken,
  skipped,
  missed;

  static MedicationLogStatus fromStorage(String value) {
    return MedicationLogStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MedicationLogStatus.pending,
    );
  }
}
