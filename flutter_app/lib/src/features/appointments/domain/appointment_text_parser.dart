class AppointmentTextSuggestion {
  const AppointmentTextSuggestion({
    required this.originalText,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.specialty,
    required this.location,
    required this.reason,
  });

  final String originalText;
  final String? doctorName;
  final DateTime? date;
  final String? time;
  final String? specialty;
  final String? location;
  final String? reason;

  bool get isComplete => _hasText(doctorName) && date != null && _hasText(time);

  List<String> get missingFields {
    final fields = <String>[];
    if (!_hasText(doctorName)) fields.add('Arzt / Behandler');
    if (date == null) fields.add('Datum');
    if (!_hasText(time)) fields.add('Uhrzeit');
    return fields;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class AppointmentTextParser {
  const AppointmentTextParser();

  AppointmentTextSuggestion parse(String text, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final normalized = _normalize(text);
    return AppointmentTextSuggestion(
      originalText: text.trim(),
      doctorName: _extractDoctor(text),
      date: _extractDate(normalized, reference),
      time: _extractTime(normalized),
      specialty: _extractSpecialty(normalized),
      location: _extractLocation(text),
      reason: _extractReason(text),
    );
  }

  String? _extractDoctor(String text) {
    final match = RegExp(
      r'\bbei(?:m| der| dem)?\s+(.+?)(?=\s+(?:am|heute|morgen|uebermorgen|übermorgen|um|wegen|zur|zum|fuer|für|in)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    if (match == null) return null;
    final value = _clean(match.group(1));
    if (value == null) return null;
    return value.replaceFirst(
      RegExp(r'^(einen|eine|den|die)\s+', caseSensitive: false),
      '',
    );
  }

  DateTime? _extractDate(String text, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (text.contains('uebermorgen') || text.contains('übermorgen')) {
      return today.add(const Duration(days: 2));
    }
    if (text.contains('morgen')) {
      return today.add(const Duration(days: 1));
    }
    if (text.contains('heute')) return today;

    final iso = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b').firstMatch(text);
    if (iso != null) {
      return _date(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }

    final german = RegExp(
      r'\b(\d{1,2})\.(\d{1,2})\.(\d{2,4})\b',
    ).firstMatch(text);
    if (german != null) {
      final rawYear = int.parse(german.group(3)!);
      return _date(
        rawYear < 100 ? 2000 + rawYear : rawYear,
        int.parse(german.group(2)!),
        int.parse(german.group(1)!),
      );
    }

    final weekdays = <String, int>{
      'montag': DateTime.monday,
      'dienstag': DateTime.tuesday,
      'mittwoch': DateTime.wednesday,
      'donnerstag': DateTime.thursday,
      'freitag': DateTime.friday,
      'samstag': DateTime.saturday,
      'sonntag': DateTime.sunday,
    };
    for (final entry in weekdays.entries) {
      if (text.contains(entry.key)) {
        var days = entry.value - today.weekday;
        if (days < 0) days += 7;
        return today.add(Duration(days: days));
      }
    }
    return null;
  }

  String? _extractTime(String text) {
    final colon = RegExp(
      r'\b(?:um\s*)?(\d{1,2}):(\d{2})\s*(?:uhr)?\b',
    ).firstMatch(text);
    if (colon != null) {
      return _time(int.parse(colon.group(1)!), int.parse(colon.group(2)!));
    }
    final hour = RegExp(
      r'\b(?:um\s*)?(\d{1,2})\s*uhr(?:\s*(\d{1,2}))?\b',
    ).firstMatch(text);
    if (hour != null) {
      return _time(
        int.parse(hour.group(1)!),
        int.tryParse(hour.group(2) ?? '') ?? 0,
      );
    }
    return null;
  }

  String? _extractSpecialty(String text) {
    const knownSpecialties = <String, String>{
      'hausarzt': 'Allgemeinmedizin',
      'allgemeinmedizin': 'Allgemeinmedizin',
      'zahnarzt': 'Zahnmedizin',
      'zahnmedizin': 'Zahnmedizin',
      'kardiolog': 'Kardiologie',
      'kardiologie': 'Kardiologie',
      'orthopaed': 'Orthopaedie',
      'orthopäd': 'Orthopaedie',
      'dermatolog': 'Dermatologie',
      'hautarzt': 'Dermatologie',
      'gynaekolog': 'Gynaekologie',
      'gynäkolog': 'Gynaekologie',
      'neurolog': 'Neurologie',
      'augenarzt': 'Augenheilkunde',
      'hno': 'HNO',
    };
    for (final entry in knownSpecialties.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String? _extractLocation(String text) {
    final match = RegExp(
      r'\bin\s+(.+?)(?=\s+(?:am|um|wegen|zur|zum|fuer|für)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return _clean(match?.group(1));
  }

  String? _extractReason(String text) {
    final match = RegExp(
      r'\b(?:wegen|zur|zum|fuer|für)\s+(.+?)(?=\s+(?:bei|am|um|in)\b|$)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return _clean(match?.group(1));
  }

  DateTime? _date(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String? _time(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('ä', 'ä')
        .replaceAll('ö', 'ö')
        .replaceAll('ü', 'ü')
        .trim();
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
