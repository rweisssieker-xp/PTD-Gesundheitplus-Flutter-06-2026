import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/emergency/domain/emergency_payload_builder.dart';
import 'package:gesundheitplus/src/features/emergency/domain/emergency_profile.dart';

void main() {
  test('builds offline-readable minimal emergency payload', () {
    final profile = EmergencyProfile(
      fullName: 'Max Muster',
      dateOfBirth: DateTime(1980, 5, 4),
      notes: 'Patient ist ansprechbar auf Deutsch.',
      medications: const ['Ramipril 5mg'],
      allergies: const ['Penicillin'],
      diagnoses: const ['Hypertonie'],
      criticalWarnings: const ['Allergie: Penicillin (Schwer)'],
      immediateActions: const ['Bei akuter Gefahr 112 rufen'],
      contacts: const [
        EmergencyContactSummary(name: 'Erika Muster', phone: '+491234567'),
      ],
    );
    final payload = EmergencyPayloadBuilder().build(profile);
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    expect(decoded['fullName'], 'Max Muster');
    expect(decoded['dateOfBirth'], '1980-05-04T00:00:00.000');
    expect(decoded['medications'], ['Ramipril 5mg']);
    expect(decoded['criticalWarnings'], ['Allergie: Penicillin (Schwer)']);
    expect(decoded['immediateActions'], ['Bei akuter Gefahr 112 rufen']);
    expect(decoded['contacts'][0]['phone'], '+491234567');
  });
}
