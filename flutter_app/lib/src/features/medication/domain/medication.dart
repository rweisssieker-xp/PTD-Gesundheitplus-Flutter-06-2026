class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.active,
  });

  final String id;
  final String name;
  final String? dosage;
  final bool active;
}
