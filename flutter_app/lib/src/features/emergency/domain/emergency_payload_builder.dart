import 'dart:convert';

import 'emergency_profile.dart';

class EmergencyPayloadBuilder {
  String build(EmergencyProfile profile) {
    return jsonEncode({
      'source': 'Gesundheit Plus',
      'fullName': profile.fullName,
      'dateOfBirth': profile.dateOfBirth?.toIso8601String(),
      'notes': profile.notes,
      'medications': profile.medications.take(20).toList(),
      'allergies': profile.allergies.take(20).toList(),
      'diagnoses': profile.diagnoses.take(20).toList(),
      'criticalWarnings': profile.criticalWarnings.take(10).toList(),
      'immediateActions': profile.immediateActions.take(10).toList(),
      'contacts': profile.contacts
          .take(5)
          .map((contact) => {'name': contact.name, 'phone': contact.phone})
          .toList(),
    });
  }
}
