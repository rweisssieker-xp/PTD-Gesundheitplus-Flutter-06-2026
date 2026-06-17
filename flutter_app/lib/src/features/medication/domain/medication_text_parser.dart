class MedicationTextSuggestion {
  const MedicationTextSuggestion({
    required this.originalText,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.prescribedBy,
    required this.reason,
    required this.reminderTimes,
  });

  final String originalText;
  final String? name;
  final String? dosage;
  final String? frequency;
  final String? prescribedBy;
  final String? reason;
  final List<String> reminderTimes;

  bool get isComplete =>
      _hasText(name) && _hasText(dosage) && _hasText(frequency);

  List<String> get missingFields {
    final fields = <String>[];
    if (!_hasText(name)) fields.add('Medikament');
    if (!_hasText(dosage)) fields.add('Dosierung');
    if (!_hasText(frequency)) fields.add('Haeufigkeit');
    return fields;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class MedicationTextParser {
  const MedicationTextParser();

  MedicationTextSuggestion parse(String text) {
    final normalized = _normalize(text);
    return MedicationTextSuggestion(
      originalText: text.trim(),
      name: _extractName(text),
      dosage: _extractDosage(text),
      frequency: _extractFrequency(normalized),
      prescribedBy: _extractPrescribedBy(text),
      reason: _extractReason(text),
      reminderTimes: _extractReminderTimes(normalized),
    );
  }

  String? _extractName(String text) {
    final match = RegExp(
      r'\b(?:nehme|nimmt|medikament|tablette|kapsel|tropfen)\s+(.+?)(?=\s+(?:\d|einmal|zweimal|dreimal|viermal|morgens|mittags|abends|nachts|taeglich|täglich|wegen|gegen|von|verschrieben|um)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    final value = _removeDosage(_clean(match?.group(1)));
    if (value != null) return value;

    final firstWords = _removeDosage(
      _clean(
        text
            .split(
              RegExp(
                r'\b(?:\d|einmal|zweimal|dreimal|morgens|wegen|gegen|von)\b',
                caseSensitive: false,
              ),
            )
            .first,
      ),
    );
    if (firstWords == null) return null;
    return firstWords
        .replaceFirst(
          RegExp(r'^(ich|patient|patientin)\s+', caseSensitive: false),
          '',
        )
        .replaceFirst(RegExp(r'^(nehme|nimmt)\s+', caseSensitive: false), '')
        .trim();
  }

  String? _extractDosage(String text) {
    final match = RegExp(
      r'\b(\d+(?:[,.]\d+)?)\s*(mg|g|ml|ie|i\.e\.|µg|mcg|tabletten?|kapseln?|tropfen|hub)\b',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    if (match == null) return null;
    final amount = match.group(1)!.replaceAll(',', '.');
    final unit = match.group(2)!.replaceAll('.', '').toLowerCase();
    return '$amount ${_normalizeUnit(unit)}';
  }

  String? _removeDosage(String? value) {
    if (value == null) return null;
    final cleaned = value
        .replaceAll(
          RegExp(
            r'\b\d+(?:[,.]\d+)?\s*(?:mg|g|ml|ie|i\.e\.|µg|mcg|tabletten?|kapseln?|tropfen|hub)\b',
            caseSensitive: false,
            unicode: true,
          ),
          '',
        )
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String? _extractFrequency(String text) {
    const direct = <String, String>{
      'einmal taeglich': '1x taeglich',
      'einmal täglich': '1x taeglich',
      '1x taeglich': '1x taeglich',
      '1 x taeglich': '1x taeglich',
      '1x täglich': '1x taeglich',
      'zweimal taeglich': '2x taeglich',
      'zweimal täglich': '2x taeglich',
      '2x taeglich': '2x taeglich',
      '2 x taeglich': '2x taeglich',
      'dreimal taeglich': '3x taeglich',
      'dreimal täglich': '3x taeglich',
      '3x taeglich': '3x taeglich',
      '4x taeglich': '4x taeglich',
      'bei bedarf': 'bei Bedarf',
    };
    for (final entry in direct.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    final dayTimes = <String>[];
    if (text.contains('morgens')) dayTimes.add('morgens');
    if (text.contains('mittags')) dayTimes.add('mittags');
    if (text.contains('abends')) dayTimes.add('abends');
    if (text.contains('nachts')) dayTimes.add('nachts');
    if (dayTimes.isNotEmpty) return dayTimes.join(', ');
    return null;
  }

  String? _extractPrescribedBy(String text) {
    final match = RegExp(
      r'\b(?:verschrieben von|verordnet von|von)\s+(.+?)(?=\s+(?:wegen|gegen|um|morgens|mittags|abends)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return _clean(match?.group(1));
  }

  String? _extractReason(String text) {
    final match = RegExp(
      r'\b(?:wegen|gegen|fuer|für)\s+(.+?)(?=\s+(?:von|verschrieben|verordnet|um|morgens|mittags|abends)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return _clean(match?.group(1));
  }

  List<String> _extractReminderTimes(String text) {
    final values = <String>{};
    for (final match in RegExp(
      r'\b(?:um\s*)?(\d{1,2}):(\d{2})\s*(?:uhr)?\b',
    ).allMatches(text)) {
      final formatted = _time(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
      );
      if (formatted != null) values.add(formatted);
    }
    if (text.contains('morgens')) values.add('08:00');
    if (text.contains('mittags')) values.add('12:00');
    if (text.contains('abends')) values.add('20:00');
    if (text.contains('nachts')) values.add('22:00');
    return values.toList()..sort();
  }

  String? _time(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _normalizeUnit(String unit) {
    return switch (unit) {
      'tablette' || 'tabletten' => 'Tablette',
      'kapsel' || 'kapseln' => 'Kapsel',
      'tropfen' => 'Tropfen',
      'hub' => 'Hub',
      'ie' || 'i.e' => 'IE',
      _ => unit,
    };
  }

  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _clean(String? value) {
    if (value == null) return null;
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\s,.!?;:]+$'), '')
        .replaceAll(RegExp(r'^[\s,.!?;:]+'), '');
    return cleaned.isEmpty ? null : cleaned;
  }
}
