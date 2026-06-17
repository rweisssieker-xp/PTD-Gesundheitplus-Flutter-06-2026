import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/health_record/domain/anamnesis_payload_builder.dart';
import 'package:gesundheitplus/src/features/health_record/domain/health_record.dart';

void main() {
  test('builds offline-readable anamnesis QR payload', () {
    final payload = AnamnesisPayloadBuilder().build([
      MedicalHistoryEntry(
        id: '1',
        category: 'Vorerkrankung',
        title: 'Asthma',
        details: 'Seit Kindheit',
        occurredAt: DateTime(2020, 1, 2),
        active: true,
      ),
    ]);

    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    expect(decoded['source'], 'Gesundheit Plus');
    expect(decoded['type'], 'anamnesis');
    expect(decoded['entries'][0]['title'], 'Asthma');
    expect(decoded['entries'][0]['details'], 'Seit Kindheit');
  });
}
