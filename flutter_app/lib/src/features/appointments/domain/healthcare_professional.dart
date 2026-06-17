class HealthcareProfessional {
  const HealthcareProfessional({
    required this.id,
    required this.name,
    required this.specialty,
    required this.address,
    required this.phone,
    required this.email,
    required this.notes,
    required this.treatingSince,
  });

  final String id;
  final String name;
  final String specialty;
  final String? address;
  final String? phone;
  final String? email;
  final String? notes;
  final DateTime? treatingSince;
}
