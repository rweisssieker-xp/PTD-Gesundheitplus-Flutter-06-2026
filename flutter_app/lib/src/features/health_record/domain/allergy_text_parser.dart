class AllergyTextSuggestion {
  const AllergyTextSuggestion({
    required this.originalText,
    required this.substance,
    required this.category,
    required this.severity,
    required this.reaction,
  });

  final String originalText;
  final String? substance;
  final String category;
  final String severity;
  final String? reaction;

  bool get isComplete => substance != null && substance!.trim().isNotEmpty;

  List<String> get missingFields => isComplete ? const [] : const ['Allergen'];
}

class AllergyTextParser {
  const AllergyTextParser();

  AllergyTextSuggestion parse(String text) {
    final normalized = _normalize(text);
    final substance = _extractSubstance(text);
    return AllergyTextSuggestion(
      originalText: text.trim(),
      substance: substance,
      category: _extractCategory(normalized, substance),
      severity: _extractSeverity(normalized),
      reaction: _extractReaction(text),
    );
  }

  String? _extractSubstance(String text) {
    final match = RegExp(
      r'\b(?:allergie gegen|allergisch gegen|unvertraeglichkeit gegen|unverträglichkeit gegen|reagiere auf|reaktion auf)\s+(.+?)(?=\s+(?:mit|durch|wegen|seit|schwer|leicht|mittel|lebensbedrohlich|atemnot|ausschlag|schwellung|juckreiz)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    final value = _clean(match?.group(1));
    if (value != null) return value;

    final short = RegExp(
      r'\b([A-ZÄÖÜ][\p{L}\-\s]{2,40})\s+(?:allergie|unvertraeglichkeit|unverträglichkeit)\b',
      caseSensitive: true,
      unicode: true,
    ).firstMatch(text);
    return _clean(short?.group(1));
  }

  String _extractCategory(String normalized, String? substance) {
    final source = '${_normalize(substance ?? '')} $normalized';
    const medicationTerms = [
      'penicillin',
      'amoxicillin',
      'ibuprofen',
      'aspirin',
      'ass',
      'diclofenac',
      'antibiot',
      'medikament',
    ];
    if (medicationTerms.any(source.contains)) return 'Medikament';
    if (source.contains('nuss') ||
        source.contains('erdnuss') ||
        source.contains('milch') ||
        source.contains('ei') ||
        source.contains('gluten') ||
        source.contains('lebensmittel')) {
      return 'Nahrungsmittel';
    }
    if (source.contains('pollen') ||
        source.contains('birke') ||
        source.contains('gräser') ||
        source.contains('graeser') ||
        source.contains('hasel')) {
      return 'Pollen';
    }
    if (source.contains('katze') ||
        source.contains('hund') ||
        source.contains('tierhaar')) {
      return 'Tierhaare';
    }
    if (source.contains('hausstaub') || source.contains('milbe')) {
      return 'Hausstaubmilben';
    }
    if (source.contains('wespe') ||
        source.contains('biene') ||
        source.contains('insekt')) {
      return 'Insektengift';
    }
    if (source.contains('nickel') ||
        source.contains('latex') ||
        source.contains('kontakt')) {
      return 'Kontaktallergie';
    }
    return 'Sonstiges';
  }

  String _extractSeverity(String normalized) {
    if (normalized.contains('lebensbedrohlich') ||
        normalized.contains('anaphyl') ||
        normalized.contains('notfall')) {
      return 'Lebensbedrohlich';
    }
    if (normalized.contains('schwer') ||
        normalized.contains('atemnot') ||
        normalized.contains('luftnot') ||
        normalized.contains('starke schwellung')) {
      return 'Schwer';
    }
    if (normalized.contains('leicht')) return 'Leicht';
    return 'Mittel';
  }

  String? _extractReaction(String text) {
    final match = RegExp(
      r'\b(?:mit|reaktion(?: ist)?|symptome(?: sind)?|führt zu|fuehrt zu)\s+(.+?)(?=\s+(?:bei|durch|seit|allergie gegen|allergisch gegen)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    final value = _clean(match?.group(1));
    if (value != null) return value;

    final normalized = _normalize(text);
    final reactions = <String>[];
    if (normalized.contains('atemnot') || normalized.contains('luftnot')) {
      reactions.add('Atemnot');
    }
    if (normalized.contains('ausschlag')) reactions.add('Hautausschlag');
    if (normalized.contains('schwellung')) reactions.add('Schwellung');
    if (normalized.contains('juckreiz')) reactions.add('Juckreiz');
    if (normalized.contains('niesen')) reactions.add('Niesen');
    return reactions.isEmpty ? null : reactions.join(', ');
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
