class EmergencyProfile {
  const EmergencyProfile({
    required this.fullName,
    required this.notes,
    required this.medications,
    required this.allergies,
    required this.diagnoses,
    required this.contacts,
  });

  final String fullName;
  final String notes;
  final List<String> medications;
  final List<String> allergies;
  final List<String> diagnoses;
  final List<EmergencyContactSummary> contacts;
}

class EmergencyContactSummary {
  const EmergencyContactSummary({required this.name, required this.phone});

  final String name;
  final String phone;
}
