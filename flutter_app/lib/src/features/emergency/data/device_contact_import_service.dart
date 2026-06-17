import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;

import '../domain/device_contact.dart';

class DeviceContactImportService {
  const DeviceContactImportService();

  Future<DeviceContactImportResult> loadContacts() async {
    final status = await flutter_contacts.FlutterContacts.permissions.request(
      flutter_contacts.PermissionType.read,
    );
    final allowed =
        status == flutter_contacts.PermissionStatus.granted ||
        status == flutter_contacts.PermissionStatus.limited;
    if (!allowed) {
      return const DeviceContactImportResult.denied();
    }

    final contacts = await flutter_contacts.FlutterContacts.getAll(
      properties: {flutter_contacts.ContactProperty.phone},
    );
    final mapped =
        contacts
            .where((contact) => contact.phones.isNotEmpty)
            .map((contact) {
              final phones = contact.phones
                  .map((phone) {
                    final normalized = phone.normalizedNumber;
                    if (normalized != null && normalized.isNotEmpty) {
                      return normalized;
                    }
                    return phone.number;
                  })
                  .where((phone) => phone.trim().isNotEmpty)
                  .toList();
              if (phones.isEmpty) return null;
              final displayName = contact.displayName?.trim() ?? '';
              final name = displayName.isEmpty
                  ? 'Unbekannter Kontakt'
                  : displayName;
              return DeviceContact(
                id: contact.id ?? '$name-${phones.first}',
                name: name,
                phone: phones.first,
                allPhones: phones,
              );
            })
            .nonNulls
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return DeviceContactImportResult.loaded(mapped);
  }
}

class DeviceContactImportResult {
  const DeviceContactImportResult._({
    required this.allowed,
    required this.contacts,
  });

  const DeviceContactImportResult.denied()
    : this._(allowed: false, contacts: const []);

  const DeviceContactImportResult.loaded(List<DeviceContact> contacts)
    : this._(allowed: true, contacts: contacts);

  final bool allowed;
  final List<DeviceContact> contacts;
}
