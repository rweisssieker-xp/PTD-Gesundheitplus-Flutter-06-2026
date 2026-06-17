class HealthcareProfessionalSuggestion {
  const HealthcareProfessionalSuggestion({
    required this.name,
    required this.specialty,
    required this.address,
    required this.phone,
    required this.openingHours,
    this.distanceHint,
    this.tags = const [],
  });

  final String name;
  final String specialty;
  final String address;
  final String phone;
  final String openingHours;
  final String? distanceHint;
  final List<String> tags;

  String get notes => openingHours.isEmpty
      ? 'Aus lokaler Facharzt-Suche übernommen.'
      : 'Sprechzeiten: $openingHours';
}

class HealthcareProfessionalDirectory {
  const HealthcareProfessionalDirectory({this.items = defaultSuggestions});

  final List<HealthcareProfessionalSuggestion> items;

  List<HealthcareProfessionalSuggestion> search(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return items.take(4).toList();

    final scored = <({HealthcareProfessionalSuggestion item, int score})>[];
    for (final item in items) {
      final haystack = [
        item.name,
        item.specialty,
        item.address,
        item.phone,
        item.openingHours,
        ...item.tags,
      ].map(_normalize).join(' ');
      if (!haystack.contains(normalizedQuery)) continue;
      final score = _score(item, normalizedQuery);
      scored.add((item: item, score: score));
    }
    scored.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.item.name.compareTo(b.item.name);
    });
    return scored.map((entry) => entry.item).take(8).toList();
  }

  int _score(HealthcareProfessionalSuggestion item, String query) {
    var score = 0;
    if (_normalize(item.specialty).contains(query)) score += 40;
    if (_normalize(item.name).contains(query)) score += 30;
    if (item.tags.any((tag) => _normalize(tag).contains(query))) score += 20;
    if (_normalize(item.address).contains(query)) score += 10;
    return score;
  }
}

const defaultSuggestions = [
  HealthcareProfessionalSuggestion(
    name: 'Hausarztpraxis Gesundheit Plus',
    specialty: 'Allgemeinmedizin',
    address: 'Beispielstrasse 12, 10115 Berlin',
    phone: '+49 30 123456',
    openingHours: 'Mo-Fr 08:00-12:00, Mo/Do 15:00-18:00',
    distanceHint: 'lokale Vorlage',
    tags: ['Hausarzt', 'Innere Medizin', 'Kontrolle', 'Check-up'],
  ),
  HealthcareProfessionalSuggestion(
    name: 'Kardiologie am Park',
    specialty: 'Kardiologie',
    address: 'Parkallee 4, 50667 Köln',
    phone: '+49 221 987654',
    openingHours: 'Mo-Fr 09:00-16:00',
    distanceHint: 'lokale Vorlage',
    tags: ['Herz', 'EKG', 'Blutdruck', 'Innere Medizin'],
  ),
  HealthcareProfessionalSuggestion(
    name: 'Orthopädie Zentrum Mitte',
    specialty: 'Orthopädie',
    address: 'Mittelweg 28, 20095 Hamburg',
    phone: '+49 40 246810',
    openingHours: 'Mo-Do 08:30-17:00, Fr 08:30-13:00',
    distanceHint: 'lokale Vorlage',
    tags: ['Rücken', 'Gelenke', 'Sportmedizin', 'Schmerztherapie'],
  ),
  HealthcareProfessionalSuggestion(
    name: 'Dermatologie Hautklar',
    specialty: 'Dermatologie',
    address: 'Sonnenplatz 7, 80331 München',
    phone: '+49 89 135790',
    openingHours: 'Mo-Fr 08:00-15:00',
    distanceHint: 'lokale Vorlage',
    tags: ['Haut', 'Allergie', 'Muttermal', 'Screening'],
  ),
  HealthcareProfessionalSuggestion(
    name: 'Zahnarztpraxis Lächeln',
    specialty: 'Zahnmedizin',
    address: 'Markt 3, 04109 Leipzig',
    phone: '+49 341 112233',
    openingHours: 'Mo-Fr 07:30-18:00',
    distanceHint: 'lokale Vorlage',
    tags: ['Zahnarzt', 'Prophylaxe', 'Kiefer', 'Kontrolle'],
  ),
  HealthcareProfessionalSuggestion(
    name: 'Neurologie Nord',
    specialty: 'Neurologie',
    address: 'Nordring 19, 30159 Hannover',
    phone: '+49 511 445566',
    openingHours: 'Mo, Mi, Fr 09:00-14:00; Di/Do 12:00-18:00',
    distanceHint: 'lokale Vorlage',
    tags: ['Migräne', 'Nerven', 'Schwindel', 'Kopfschmerz'],
  ),
  HealthcareProfessionalSuggestion(
    name: 'Physiotherapie Aktiv',
    specialty: 'Physiotherapie',
    address: 'Therapiehof 6, 90402 Nürnberg',
    phone: '+49 911 778899',
    openingHours: 'Mo-Fr 08:00-19:00',
    distanceHint: 'lokale Vorlage',
    tags: ['Reha', 'Manuelle Therapie', 'Bewegung', 'Osteopathie'],
  ),
  HealthcareProfessionalSuggestion(
    name: 'Augenärzte Sehkraft',
    specialty: 'Augenheilkunde',
    address: 'Blickweg 10, 01067 Dresden',
    phone: '+49 351 667788',
    openingHours: 'Mo-Do 08:00-16:00, Fr 08:00-12:00',
    distanceHint: 'lokale Vorlage',
    tags: ['Auge', 'Sehen', 'Glaukom', 'Vorsorge'],
  ),
];

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}
