class MedicationInteractionGuidance {
  const MedicationInteractionGuidance({
    required this.id,
    required this.title,
    required this.severity,
    required this.description,
    this.action,
  });

  final String id;
  final String title;
  final String severity;
  final String description;
  final String? action;
}

class MedicationInteractionCheck {
  const MedicationInteractionCheck({
    required this.id,
    required this.medicationNames,
    required this.riskLevel,
    required this.summary,
    required this.consentUsed,
    required this.checkedAt,
  });

  final String id;
  final List<String> medicationNames;
  final String riskLevel;
  final String summary;
  final bool consentUsed;
  final DateTime checkedAt;
}
