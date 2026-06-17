import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Termine')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: dbAsync.hasValue
            ? () => _openEditor(AppointmentRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Termin'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = AppointmentRepository(db);
          return FutureBuilder<List<Appointment>>(
            key: ValueKey(_reload),
            future: repo.listAppointments(),
            builder: (context, snapshot) {
              final appointments = snapshot.data ?? [];
              final upcoming = appointments
                  .where(
                    (item) =>
                        item.startsAt.isAfter(DateTime.now()) ||
                        _isToday(item.date),
                  )
                  .toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AppointmentSummary(count: upcoming.length),
                  const SizedBox(height: 16),
                  if (appointments.isEmpty)
                    _EmptyAppointments(onAdd: () => _openEditor(repo))
                  else
                    ...appointments.map(
                      (appointment) => _AppointmentCard(
                        appointment: appointment,
                        onComplete: () async {
                          await repo.saveAppointment(
                            appointment.copyWith(
                              status: AppointmentStatus.completed,
                            ),
                          );
                          _refresh();
                        },
                        onDelete: () async {
                          await repo.deleteAppointment(appointment.id);
                          _refresh();
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(AppointmentRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AppointmentEditor(repo: repo),
    );
    if (saved == true) _refresh();
  }

  void _refresh() {
    setState(() {
      _reload++;
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _AppointmentSummary extends StatelessWidget {
  const _AppointmentSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), GpColors.emergencyRed],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(GpIcons.appointments, color: Colors.white, size: 46),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anstehende Termine',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(GpIcons.appointments, color: Colors.black26, size: 52),
            const SizedBox(height: 12),
            const Text('Noch keine Termine eingetragen'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ersten Termin hinzufuegen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onComplete,
    required this.onDelete,
  });

  final Appointment appointment;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE4E6),
                  child: Icon(
                    GpIcons.appointments,
                    color: GpColors.emergencyRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${appointment.date.day}.${appointment.date.month}.${appointment.date.year} • ${appointment.time} Uhr',
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'complete') onComplete();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'complete',
                      child: Text('Abgeschlossen'),
                    ),
                    PopupMenuItem(value: 'delete', child: Text('Loeschen')),
                  ],
                ),
              ],
            ),
            if ((appointment.specialty ?? '').isNotEmpty)
              _Line(
                icon: Icons.local_hospital_outlined,
                text: appointment.specialty!,
              ),
            if ((appointment.location ?? '').isNotEmpty)
              _Line(icon: Icons.place_outlined, text: appointment.location!),
            if ((appointment.reason ?? '').isNotEmpty)
              _Line(icon: Icons.info_outline, text: appointment.reason!),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(appointment.status.label)),
                if (appointment.reminderEnabled)
                  Chip(
                    label: Text(
                      '${appointment.reminderHoursBefore}h Erinnerung',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _AppointmentEditor extends StatefulWidget {
  const _AppointmentEditor({required this.repo});

  final AppointmentRepository repo;

  @override
  State<_AppointmentEditor> createState() => _AppointmentEditorState();
}

class _AppointmentEditorState extends State<_AppointmentEditor> {
  final _doctorName = TextEditingController();
  final _specialty = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  final _location = TextEditingController();
  final _reason = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date.text =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _time.text = '09:00';
  }

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
            Text('Neuer Termin', style: Theme.of(context).textTheme.titleLarge),
            TextField(
              controller: _doctorName,
              decoration: const InputDecoration(
                labelText: 'Arzt / Behandler *',
              ),
            ),
            TextField(
              controller: _specialty,
              decoration: const InputDecoration(labelText: 'Fachrichtung'),
            ),
            TextField(
              controller: _date,
              decoration: const InputDecoration(labelText: 'Datum YYYY-MM-DD'),
            ),
            TextField(
              controller: _time,
              decoration: const InputDecoration(labelText: 'Uhrzeit HH:MM'),
            ),
            TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Ort'),
            ),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Grund'),
            ),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final date = DateTime.tryParse(_date.text);
    if (_doctorName.text.trim().isEmpty ||
        date == null ||
        _time.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Arzt, Datum und Uhrzeit eingeben')),
      );
      return;
    }
    await widget.repo.saveAppointment(
      widget.repo.newAppointment(
        doctorName: _doctorName.text.trim(),
        specialty: _specialty.text.trim(),
        date: date,
        time: _time.text.trim(),
        location: _location.text.trim(),
        reason: _reason.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }
}
