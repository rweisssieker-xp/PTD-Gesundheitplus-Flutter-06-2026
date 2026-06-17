import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/platform/location_service.dart';
import '../../../core/platform/platform_handoff_service.dart';
import '../../../shared_ui/gp_colors.dart';
import '../domain/emergency_profile.dart';

typedef EmergencyMessageShare = Future<void> Function(String text);

class EmergencyContactsSection extends StatelessWidget {
  const EmergencyContactsSection({
    super.key,
    required this.contacts,
    this.title = 'Notfallkontakte',
    this.empty = 'Keine Kontakte mit Telefonnummer',
    PlatformHandoffService? handoff,
    LocationService? location,
    EmergencyMessageShare? shareMessage,
  }) : _handoff = handoff ?? const PlatformHandoffService(),
       _location = location ?? const LocationService(),
       _shareMessage = shareMessage ?? _defaultShareMessage;

  final List<EmergencyContactSummary> contacts;
  final String title;
  final String empty;
  final PlatformHandoffService _handoff;
  final LocationService _location;
  final EmergencyMessageShare _shareMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (contacts.isEmpty)
              Text(empty, style: const TextStyle(color: GpColors.textSecondary))
            else
              ...contacts.map(
                (contact) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(contact.name),
                  subtitle: Text(contact.phone),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Anrufen',
                        icon: const Icon(Icons.call_outlined),
                        onPressed: () => _launch(
                          context,
                          PlatformHandoffService.telUri(contact.phone),
                          'Telefon-App konnte nicht geoeffnet werden.',
                        ),
                      ),
                      IconButton(
                        tooltip: 'SMS senden',
                        icon: const Icon(Icons.sms_outlined),
                        onPressed: () => _launch(
                          context,
                          PlatformHandoffService.smsUri(
                            contact.phone,
                            'Ich brauche Hilfe. Bitte rufen Sie mich an.',
                          ),
                          'SMS-App konnte nicht geoeffnet werden.',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Standort per SMS',
                        icon: const Icon(Icons.my_location_outlined),
                        onPressed: () => _shareLocation(context, contact.phone),
                      ),
                      IconButton(
                        tooltip: 'WhatsApp',
                        icon: const Icon(Icons.chat_outlined),
                        onPressed: () => _launch(
                          context,
                          PlatformHandoffService.whatsappUri(
                            contact.phone,
                            _emergencyMessage,
                          ),
                          'WhatsApp konnte nicht geoeffnet werden. Nutzen Sie Teilen oder SMS.',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Teilen',
                        icon: const Icon(Icons.ios_share_outlined),
                        onPressed: () => _shareEmergencyText(context),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(
    BuildContext context,
    Uri uri,
    String failureText,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final launched = await _handoff.launch(uri);
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(failureText)));
    }
  }

  Future<void> _shareEmergencyText(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _shareMessage(_emergencyMessage);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Teilen konnte nicht geoeffnet werden.')),
      );
    }
  }

  Future<void> _shareLocation(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final location = await _location.currentEmergencyLocation();
    if (location == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Standort nicht verfuegbar. Bitte Berechtigung und GPS pruefen.',
          ),
        ),
      );
      return;
    }
    final launched = await _handoff.launch(
      PlatformHandoffService.smsUri(
        phone,
        'Ich brauche Hilfe. Mein aktueller Standort: ${location.mapsUrl}',
      ),
    );
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('SMS-App konnte nicht geoeffnet werden.')),
      );
    }
  }
}

const _emergencyMessage =
    'Ich brauche Hilfe. Bitte rufen Sie mich an. Gesendet aus Gesundheit Plus.';

Future<void> _defaultShareMessage(String text) => Share.share(text);
