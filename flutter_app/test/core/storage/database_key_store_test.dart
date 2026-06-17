import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/database_key_store.dart';

void main() {
  test('fixed database key store returns configured key', () async {
    const store = FixedDatabaseKeyStore('test-key');
    expect(await store.readOrCreateKey(), 'test-key');
  });
}
