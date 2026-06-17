import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/notifications/native_notification_service.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment.dart';
import '../domain/appointment_ics_builder.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  int _reload = 0;
  final _notifications = NativeNotificationService();

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
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
                  _CalendarExportCard(
                    appointments: appointments,
                    upcoming: upcoming,
                    onExport: _exportAppointments,
                  ),
                  const SizedBox(height: 16),
                  if (appointments.isEmpty)
                    _EmptyAppointments(onAdd: () => _openEditor(repo))
                  else
                    ...appointments.map(
                      (appointment) => _AppointmentCard(
                        appointment: appointment,
                        onComplete: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await repo.saveAppointment(
                            appointment.copyWith(
                              status: AppointmentStatus.completed,
                            ),
                          );
                          try {
                            await _cancelAppointmentReminder(appointment);
                          } catch (_) {
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Termin abgeschlossen, Erinnerung konnte nicht entfernt werden.',
                                  ),
                                ),
                              );
                            }
                          }
                          _refresh();
                        },
                        onDelete: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await repo.deleteAppointment(appointment.id);
                          try {
                            await _cancelAppointmentReminder(appointment);
                          } catch (_) {
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Termin geloescht, Erinnerung konnte nicht entfernt werden.',
                                  ),
                                ),
                              );
                            }
                          }
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
      builder: (context) => _AppointmentEditor(
        repo: repo,
        scheduleAppointment: _scheduleAppointmentReminder,
      ),
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

  Future<void> _scheduleAppointmentReminder(Appointment appointment) async {
    if (!appointment.reminderEnabled ||
        appointment.status == AppointmentStatus.completed ||
        appointment.status == AppointmentStatus.cancelled) {
      return;
    }
    final reminder = NotificationScheduler().appointmentReminder(
      appointmentId: appointment.id,
      doctorName: appointment.doctorName,
      startsAt: appointment.startsAt,
      hoursBefore: appointment.reminderHoursBefore,
      now: DateTime.now(),
    );
    if (reminder == null) return;
    await _notifications.scheduleReminder(
      reminder,
      body: [
        appointment.reason,
        appointment.location,
        '${appointment.date.day}.${appointment.date.month}.${appointment.date.year} um ${appointment.time} Uhr',
      ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' • '),
    );
  }

  Future<void> _cancelAppointmentReminder(Appointment appointment) {
    return _notifications.cancelAppointmentReminder(appointment.id);
  }

  Future<void> _exportAppointments(List<Appointment> appointments) async {
    if (appointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Termine zum Exportieren vorhanden'),
        ),
      );
      return;
    }
    final directory = await getTemporaryDirectory();
    final date = DateTime.now();
    final fileName =
        'gesundheit-plus-termine-${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}.ics';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(AppointmentIcsBuilder().build(appointments));
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'text/calendar', name: fileName),
    ]);
  }
}

class _CalendarExportCard extends StatelessWidget {
  const _CalendarExportCard({
    required this.appointments,
    required this.upcoming,
    required this.onExport,
  });

  final List<Appointment> appointments;
  final List<Appointment> upcoming;
  final ValueChanged<List<Appointment>> onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEEF2FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFC7D2FE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kalender Synchronisation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Exportieren Sie Ihre Termine als .ics Datei für Google Calendar, Outlook, Apple Calendar oder andere Kalender-Apps.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: GpColors.border, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${upcoming.length} anstehende / ${appointments.length} Termin(e) gesamt',
                      style: const TextStyle(
                        color: GpColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: upcoming.isEmpty
                          ? null
                          : () => onExport(upcoming),
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Anstehende Termine exportieren'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: appointments.isEmpty
                          ? null
                          : () => onExport(appointments),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Alle Termine exportieren'),
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
  const _AppointmentEditor({
    required this.repo,
    required this.scheduleAppointment,
  });

  final AppointmentRepository repo;
  final Future<void> Function(Appointment appointment) scheduleAppointment;

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
    final appointment = widget.repo.newAppointment(
      doctorName: _doctorName.text.trim(),
      specialty: _specialty.text.trim(),
      date: date,
      time: _time.text.trim(),
      location: _location.text.trim(),
      reason: _reason.text.trim(),
      notes: _notes.text.trim(),
    );
    await widget.repo.saveAppointment(appointment);
    try {
      await widget.scheduleAppointment(appointment);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Termin gespeichert, Erinnerung konnte nicht geplant werden.',
            ),
          ),
        );
      }
    }
    if (mounted) Navigator.pop(context, true);
  }
}
