class EmergencyProfile {
  const EmergencyProfile({
    required this.fullName,
    this.dateOfBirth,
    required this.notes,
    required this.medications,
    required this.allergies,
    required this.diagnoses,
    required this.contacts,
    this.criticalWarnings = const [],
    this.immediateActions = const [],
  });

  final String fullName;
  final DateTime? dateOfBirth;
  final String notes;
  final List<String> medications;
  final List<String> allergies;
  final List<String> diagnoses;
  final List<EmergencyContactSummary> contacts;
  final List<String> criticalWarnings;
  final List<String> immediateActions;
}

class EmergencyContactSummary {
  const EmergencyContactSummary({
    required this.name,
    required this.phone,
    this.messenger,
  });

  final String name;
  final String phone;
  final String? messenger;
}
