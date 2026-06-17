class HealthcareProfessionalTextSuggestion {
  const HealthcareProfessionalTextSuggestion({
    required this.originalText,
    required this.name,
    required this.specialty,
    required this.address,
    required this.phone,
    required this.email,
  });

  final String originalText;
  final String? name;
  final String? specialty;
  final String? address;
  final String? phone;
  final String? email;

  bool get isComplete => _hasText(name) && _hasText(specialty);

  List<String> get missingFields {
    final fields = <String>[];
    if (!_hasText(name)) fields.add('Name');
    if (!_hasText(specialty)) fields.add('Fachrichtung');
    return fields;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class HealthcareProfessionalTextParser {
  const HealthcareProfessionalTextParser();

  HealthcareProfessionalTextSuggestion parse(String text) {
    final normalized = _normalize(text);
    return HealthcareProfessionalTextSuggestion(
      originalText: text.trim(),
      name: _extractName(text),
      specialty: _extractSpecialty(normalized),
      address: _extractAddress(text),
      phone: _extractPhone(text),
      email: _extractEmail(text),
    );
  }

  String? _extractName(String text) {
    final match = RegExp(
      r'\b(?:arzt|aerztin|ärztin|behandler|behandlerin|praxis|doktor|dr\.?)\s+(.+?)(?=\s+(?:ist|für|fuer|als|fachrichtung|in|adresse|telefon|tel\.?|nummer|email|e-mail)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    final value = _clean(match?.group(1));
    if (value != null) {
      return value.replaceFirst(
        RegExp(r'^(ist|heisst|heißt)\s+', caseSensitive: false),
        '',
      );
    }

    final dr = RegExp(
      r'\b(Dr\.?\s+[\p{L}\-]+(?:\s+[\p{L}\-]+)?)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return _clean(dr?.group(1));
  }

  String? _extractSpecialty(String text) {
    const specialties = <String, String>{
      'hausarzt': 'Allgemeinmedizin',
      'allgemeinmedizin': 'Allgemeinmedizin',
      'internist': 'Innere Medizin',
      'kardiolog': 'Kardiologie',
      'kardiologie': 'Kardiologie',
      'orthopaed': 'Orthopaedie',
      'orthopäd': 'Orthopaedie',
      'zahnarzt': 'Zahnmedizin',
      'zahnmedizin': 'Zahnmedizin',
      'dermatolog': 'Dermatologie',
      'hautarzt': 'Dermatologie',
      'gynaekolog': 'Gynaekologie',
      'gynäkolog': 'Gynaekologie',
      'neurolog': 'Neurologie',
      'augenarzt': 'Augenheilkunde',
      'hno': 'HNO',
      'psychotherapeut': 'Psychotherapie',
      'physiotherapie': 'Physiotherapie',
    };
    for (final entry in specialties.entries) {
      if (text.contains(entry.key)) return entry.value;
    }

    final match = RegExp(
      r'\b(?:fachrichtung|als)\s+(.+?)(?=\s+(?:in|adresse|telefon|tel|nummer|email|e-mail)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return _clean(match?.group(1));
  }

  String? _extractAddress(String text) {
    final match = RegExp(
      r'\b(?:adresse|praxisadresse|in)\s+(.+?)(?=\s+(?:telefon|tel\.?|nummer|email|e-mail)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return _clean(match?.group(1));
  }

  String? _extractPhone(String text) {
    final match = RegExp(
      r'(?:\+?\d[\d\s()/.-]{5,}\d)',
      caseSensitive: false,
    ).firstMatch(text);
    final phone = _clean(match?.group(0));
    if (phone == null) return null;
    return phone.replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _extractEmail(String text) {
    final match = RegExp(
      r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
      caseSensitive: false,
    ).firstMatch(text);
    return _clean(match?.group(0));
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String? _clean(String? value) {
    if (value == null) return null;
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\s,.!?;:]+$'), '')
        .replaceAll(RegExp(r'^[\s,.!?;:]+'), '');
    return cleaned.isEmpty ? null : cleaned;
  }
}
