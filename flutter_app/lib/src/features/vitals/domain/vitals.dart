class BloodPressureLog {
  const BloodPressureLog({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.measuredAt,
    required this.notes,
  });

  final String id;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final DateTime measuredAt;
  final String? notes;
}

class WeightLog {
  const WeightLog({
    required this.id,
    required this.weightKg,
    required this.heightCm,
    required this.measuredAt,
    required this.notes,
  });

  final String id;
  final double weightKg;
  final double? heightCm;
  final DateTime measuredAt;
  final String? notes;

  double? get bmi {
    final height = heightCm;
    if (height == null || height <= 0) return null;
    final meters = height / 100;
    return weightKg / (meters * meters);
  }
}
