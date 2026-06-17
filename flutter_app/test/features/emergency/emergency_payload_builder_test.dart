import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/emergency/domain/emergency_payload_builder.dart';
import 'package:gesundheitplus/src/features/emergency/domain/emergency_profile.dart';

void main() {
  test('builds offline-readable minimal emergency payload', () {
    final profile = EmergencyProfile(
      fullName: 'Max Muster',
      notes: 'Patient ist ansprechbar auf Deutsch.',
      medications: const ['Ramipril 5mg'],
      allergies: const ['Penicillin'],
      diagnoses: const ['Hypertonie'],
      contacts: const [
        EmergencyContactSummary(name: 'Erika Muster', phone: '+491234567'),
      ],
    );
    final payload = EmergencyPayloadBuilder().build(profile);
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    expect(decoded['fullName'], 'Max Muster');
    expect(decoded['medications'], ['Ramipril 5mg']);
    expect(decoded['contacts'][0]['phone'], '+491234567');
  });
}
