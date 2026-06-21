import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/location_service.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/care_repository.dart';
import '../domain/care.dart';

class FamilyCircleScreen extends ConsumerStatefulWidget {
  const FamilyCircleScreen({super.key});

  @override
  ConsumerState<FamilyCircleScreen> createState() => _FamilyCircleScreenState();
}

class _FamilyCircleScreenState extends ConsumerState<FamilyCircleScreen> {
  int _reload = 0;
  final _location = const LocationService();
  final _message = TextEditingController();
  final _locationText = TextEditingController();
  String? _pendingStatus;
  bool _gettingLocation = false;

  @override
  void dispose() {
    _message.dispose();
    _locationText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openMemberEditor(CareRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Person'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = CareRepository(db);
          return FutureBuilder<List<Object>>(
            key: ValueKey(_reload),
            future: Future.wait([
              repo.listFamilyMembers(),
              repo.listCheckIns(),
            ]),
            builder: (context, snapshot) {
              final members =
                  (snapshot.data?.firstOrNull as List<FamilyMember>?) ?? [];
              final checkIns =
                  (snapshot.data?.lastOrNull as List<FamilyCheckIn>?) ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PageHeader(onRefresh: () => setState(() => _reload++)),
                  const SizedBox(height: 12),
                  _StatusSummary(members: members, checkIns: checkIns),
                  const SizedBox(height: 12),
                  _MyCheckInCard(
                    pendingStatus: _pendingStatus,
                    message: _message,
                    locationText: _locationText,
                    gettingLocation: _gettingLocation,
                    onStatusSelected: (status) =>
                        setState(() => _pendingStatus = status),
                    onGetLocation: _captureLocation,
                    onCancel: () => setState(() => _pendingStatus = null),
                    onSubmit: () => _submitOwnCheckIn(repo),
                  ),
                  const SizedBox(height: 16),
                  _FamilyCountHeader(count: members.length),
                  const SizedBox(height: 16),
                  Text(
                    'Familienmitglieder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...members.map((member) {
                    final latest = _latestForMember(checkIns, member);
                    return _FamilyMemberCard(
                      member: member,
                      latest: latest,
                      onSafeCheckIn: () async {
                        await repo.addCheckIn(
                          memberId: member.id,
                          memberName: member.name,
                          status: 'safe',
                          note: 'Manuell bestaetigt',
                        );
                        if (mounted) setState(() => _reload++);
                      },
                    );
                  }),
                  if (members.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Noch keine Familienmitglieder. Fuegen Sie lokale Kontakte fuer den Sicherheitskreis hinzu.',
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Check-ins',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (checkIns.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Noch keine Check-ins'),
                      ),
                    )
                  else
                    ...checkIns
                        .take(10)
                        .map(
                          (checkIn) => ListTile(
                            leading: const Icon(Icons.done),
                            title: Text(checkIn.memberName),
                            subtitle: Text(
                              [
                                _statusLabel(checkIn.status),
                                _date(checkIn.checkedAt),
                                if ((checkIn.locationText ?? '').isNotEmpty)
                                  checkIn.locationText!,
                              ].join(' • '),
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (checkIn.isOverdue) const _OverdueBadge(),
                                Icon(
                                  _statusIcon(checkIn.status),
                                  color: _statusColor(checkIn.status),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  const _HowItWorksCard(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openMemberEditor(CareRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FamilyMemberEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }

  Future<void> _captureLocation() async {
    setState(() => _gettingLocation = true);
    final messenger = ScaffoldMessenger.of(context);
    final location = await _location.currentEmergencyLocation();
    if (!mounted) return;
    setState(() => _gettingLocation = false);
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
    _locationText.text =
        '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  Future<void> _submitOwnCheckIn(CareRepository repo) async {
    final status = _pendingStatus;
    if (status == null) return;
    await repo.addCheckIn(
      memberName: 'Ich',
      status: status,
      note: _emptyToNull(_message.text),
      locationText: _emptyToNull(_locationText.text),
    );
    _message.clear();
    _locationText.clear();
    if (mounted) {
      setState(() {
        _pendingStatus = null;
        _reload++;
      });
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(GpIcons.family, color: Color(0xFF2563EB), size: 30),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Familien-Sicherheitskreis',
                style: TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Status-Updates und Bin-sicher-Check-ins lokal verwalten',
                style: TextStyle(color: GpColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Aktualisieren',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.members, required this.checkIns});

  final List<FamilyMember> members;
  final List<FamilyCheckIn> checkIns;

  @override
  Widget build(BuildContext context) {
    final latest = <String, FamilyCheckIn>{};
    for (final checkIn in checkIns) {
      latest.putIfAbsent(checkIn.memberId ?? checkIn.memberName, () => checkIn);
    }
    final values = latest.values;
    final knownMemberKeys = values.map(
      (item) => item.memberId ?? item.memberName,
    );
    final membersWithoutStatus = members
        .where((member) => !knownMemberKeys.contains(member.id))
        .length;
    return Row(
      children: [
        Expanded(
          child: _StatusCountCard(
            label: 'Sicher',
            count: values.where((item) => item.status == 'safe').length,
            color: const Color(0xFF16A34A),
            background: const Color(0xFFF0FDF4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusCountCard(
            label: 'Hilfe',
            count: values.where((item) => item.status == 'help_needed').length,
            color: GpColors.emergencyRed,
            background: GpColors.redSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusCountCard(
            label: 'Unbekannt',
            count:
                membersWithoutStatus +
                values
                    .where(
                      (item) =>
                          item.status != 'safe' && item.status != 'help_needed',
                    )
                    .length,
            color: GpColors.textSecondary,
            background: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }
}

class _FamilyCountHeader extends StatelessWidget {
  const _FamilyCountHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.purplePink),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(GpIcons.family, color: Colors.white, size: 46),
            const SizedBox(width: 16),
            Text(
              '$count Personen',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({
    required this.member,
    required this.latest,
    required this.onSafeCheckIn,
  });

  final FamilyMember member;
  final FamilyCheckIn? latest;
  final VoidCallback onSafeCheckIn;

  @override
  Widget build(BuildContext context) {
    final status = latest?.status ?? 'unknown';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(_statusIcon(status), color: _statusColor(status)),
        title: Row(
          children: [
            Expanded(child: Text(member.name)),
            if (latest?.isOverdue ?? false) const _OverdueBadge(),
          ],
        ),
        subtitle: Text(
          [
            member.relationship,
            member.role,
            member.phone,
            if (latest != null) _statusLabel(status),
            if (latest?.note != null) latest!.note,
            if (latest?.locationText != null) latest!.locationText,
          ].whereType<String>().join(' • '),
        ),
        trailing: IconButton(
          tooltip: 'Check-in',
          icon: const Icon(Icons.check_circle_outline),
          onPressed: onSafeCheckIn,
        ),
      ),
    );
  }
}

class _StatusCountCard extends StatelessWidget {
  const _StatusCountCard({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
  });

  final String label;
  final int count;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCheckInCard extends StatelessWidget {
  const _MyCheckInCard({
    required this.pendingStatus,
    required this.message,
    required this.locationText,
    required this.gettingLocation,
    required this.onStatusSelected,
    required this.onGetLocation,
    required this.onCancel,
    required this.onSubmit,
  });

  final String? pendingStatus;
  final TextEditingController message;
  final TextEditingController locationText;
  final bool gettingLocation;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onGetLocation;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite_border, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  'Mein Status senden',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    label: 'Bin sicher',
                    subtitle: 'Alles OK',
                    icon: Icons.check_circle_outline,
                    colors: GpColors.green,
                    onTap: () => onStatusSelected('safe'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusButton(
                    label: 'Brauche Hilfe',
                    subtitle: 'Kontaktieren',
                    icon: Icons.error_outline,
                    colors: GpColors.redGradient,
                    onTap: () => onStatusSelected('help_needed'),
                  ),
                ),
              ],
            ),
            if (pendingStatus != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(label: Text(_statusLabel(pendingStatus!))),
                      ),
                      TextField(
                        controller: message,
                        decoration: const InputDecoration(
                          labelText: 'Optionale Nachricht',
                          hintText: 'z.B. Bin beim Arzt',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: locationText,
                              decoration: const InputDecoration(
                                labelText: 'Standort optional',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Standort erfassen',
                            onPressed: gettingLocation ? null : onGetLocation,
                            icon: gettingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.location_on_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onSubmit,
                              icon: const Icon(Icons.send_outlined),
                              label: const Text('Senden'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: onCancel,
                            child: const Text('Abbrechen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF97316)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 13, color: Color(0xFFC2410C)),
          SizedBox(width: 3),
          Text(
            'Überfällig',
            style: TextStyle(
              color: Color(0xFFC2410C),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F3FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFC4B5FD), width: 2),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: Color(0xFF7C3AED)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'So funktioniert der Sicherheitskreis',
                    style: TextStyle(
                      color: Color(0xFF5B21B6),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Jedes Familienmitglied sendet einen Status. Brauche-Hilfe-Check-ins werden hervorgehoben, überfällige lokale Check-ins markiert.',
                    style: TextStyle(color: Color(0xFF5B21B6), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMemberEditor extends StatefulWidget {
  const _FamilyMemberEditor({required this.repo});

  final CareRepository repo;

  @override
  State<_FamilyMemberEditor> createState() => _FamilyMemberEditorState();
}

class _FamilyMemberEditorState extends State<_FamilyMemberEditor> {
  final _name = TextEditingController();
  final _relationship = TextEditingController();
  final _phone = TextEditingController();
  final _role = TextEditingController(text: 'Kontakt');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Person hinzufuegen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            TextField(
              controller: _relationship,
              decoration: const InputDecoration(labelText: 'Beziehung'),
            ),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            TextField(
              controller: _role,
              decoration: const InputDecoration(labelText: 'Rolle'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await widget.repo.addFamilyMember(
      name: name,
      relationship: _emptyToNull(_relationship.text),
      phone: _emptyToNull(_phone.text),
      role: _emptyToNull(_role.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';

String _statusLabel(String status) => switch (status) {
  'safe' => 'Bin sicher',
  'help_needed' => 'Brauche Hilfe',
  'ok' => 'Bin sicher',
  _ => 'Unbekannt',
};

IconData _statusIcon(String status) => switch (status) {
  'safe' || 'ok' => Icons.check_circle_outline,
  'help_needed' => Icons.error_outline,
  _ => Icons.help_outline,
};

Color _statusColor(String status) => switch (status) {
  'safe' || 'ok' => const Color(0xFF16A34A),
  'help_needed' => GpColors.emergencyRed,
  _ => GpColors.textSecondary,
};

FamilyCheckIn? _latestForMember(
  List<FamilyCheckIn> checkIns,
  FamilyMember member,
) {
  for (final checkIn in checkIns) {
    if (checkIn.memberId == member.id || checkIn.memberName == member.name) {
      return checkIn;
    }
  }
  return null;
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
