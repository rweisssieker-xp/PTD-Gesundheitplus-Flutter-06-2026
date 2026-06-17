import 'dart:convert';

import 'health_record.dart';

class AnamnesisPayloadBuilder {
  String build(List<MedicalHistoryEntry> entries) {
    return jsonEncode({
      'source': 'Gesundheit Plus',
      'type': 'anamnesis',
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': entries
          .take(40)
          .map(
            (entry) => {
              'category': entry.category,
              'title': entry.title,
              if ((entry.details ?? '').isNotEmpty) 'details': entry.details,
              if (entry.occurredAt != null)
                'occurredAt': entry.occurredAt!.toIso8601String(),
              'active': entry.active,
            },
          )
          .toList(),
    });
  }
}
