class DeviceContact {
  const DeviceContact({
    required this.id,
    required this.name,
    required this.phone,
    this.allPhones = const [],
  });

  final String id;
  final String name;
  final String phone;
  final List<String> allPhones;
}

String normalizeGermanPhoneNumber(String value) {
  final compact = value
      .trim()
      .replaceAll(RegExp(r'[\s\-/().]'), '')
      .replaceFirst(RegExp(r'^00'), '+');
  if (compact.startsWith('+')) {
    return compact;
  }
  if (compact.startsWith('0') && compact.length > 1) {
    return '+49${compact.substring(1)}';
  }
  return compact;
}
