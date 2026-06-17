import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/features/appointments/domain/healthcare_professional_directory.dart';

void main() {
  test('returns default suggestions for empty query', () {
    const directory = HealthcareProfessionalDirectory();

    final results = directory.search('');

    expect(results, hasLength(4));
    expect(results.first.specialty, 'Allgemeinmedizin');
  });

  test('finds specialists by specialty and tags', () {
    const directory = HealthcareProfessionalDirectory();

    final cardiology = directory.search('Blutdruck');
    final orthopaedics = directory.search('Orthopaedie');

    expect(cardiology.first.specialty, 'Kardiologie');
    expect(orthopaedics.first.specialty, 'Orthopädie');
  });

  test('returns no result for unknown local query', () {
    const directory = HealthcareProfessionalDirectory();

    final results = directory.search('Tropenmedizin Zanzibar');

    expect(results, isEmpty);
  });
}
