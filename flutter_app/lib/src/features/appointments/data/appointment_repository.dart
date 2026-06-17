import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/appointment.dart';
import '../domain/healthcare_professional.dart';

class AppointmentRepository {
  AppointmentRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> saveAppointment(Appointment appointment) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO appointments (
        id, title, starts_at, location, doctor_name, specialty, date, time,
        reason, reminder_enabled, reminder_hours_before, notes, status,
        created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        starts_at = excluded.starts_at,
        location = excluded.location,
        doctor_name = excluded.doctor_name,
        specialty = excluded.specialty,
        date = excluded.date,
        time = excluded.time,
        reason = excluded.reason,
        reminder_enabled = excluded.reminder_enabled,
        reminder_hours_before = excluded.reminder_hours_before,
        notes = excluded.notes,
        status = excluded.status,
        updated_at = excluded.updated_at;
      ''',
      [
        appointment.id,
        appointment.doctorName,
        appointment.startsAt.toIso8601String(),
        appointment.location,
        appointment.doctorName,
        appointment.specialty,
        _dateKey(appointment.date),
        appointment.time,
        appointment.reason,
        appointment.reminderEnabled ? 1 : 0,
        appointment.reminderHoursBefore,
        appointment.notes,
        appointment.status.label,
        now,
        now,
      ],
    );
  }

  Future<void> deleteAppointment(String id) async {
    _db.execute('DELETE FROM appointments WHERE id = ?', [id]);
  }

  Future<List<Appointment>> listAppointments() async {
    final rows = _db.select('''
      SELECT id, doctor_name, specialty, date, time, location, reason,
             reminder_enabled, reminder_hours_before, notes, status
      FROM appointments
      ORDER BY starts_at
      ''');
    return rows.map(_appointmentFromRow).toList();
  }

  Future<void> saveProfessional(HealthcareProfessional professional) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO healthcare_professionals (
        id, name, specialty, address, phone, email, notes, treating_since,
        created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        specialty = excluded.specialty,
        address = excluded.address,
        phone = excluded.phone,
        email = excluded.email,
        notes = excluded.notes,
        treating_since = excluded.treating_since,
        updated_at = excluded.updated_at;
      ''',
      [
        professional.id,
        professional.name,
        professional.specialty,
        professional.address,
        professional.phone,
        professional.email,
        professional.notes,
        professional.treatingSince?.toIso8601String(),
        now,
        now,
      ],
    );
  }

  Future<void> deleteProfessional(String id) async {
    _db.execute('DELETE FROM healthcare_professionals WHERE id = ?', [id]);
  }

  Future<List<HealthcareProfessional>> listProfessionals() async {
    final rows = _db.select('''
      SELECT id, name, specialty, address, phone, email, notes, treating_since
      FROM healthcare_professionals
      ORDER BY specialty COLLATE NOCASE, name COLLATE NOCASE
      ''');
    return rows.map(_professionalFromRow).toList();
  }

  Appointment newAppointment({
    required String doctorName,
    required DateTime date,
    required String time,
    String? specialty,
    String? location,
    String? reason,
    String? notes,
  }) {
    return Appointment(
      id: _uuid.v4(),
      doctorName: doctorName,
      specialty: specialty,
      date: date,
      time: time,
      location: location,
      reason: reason,
      reminderEnabled: true,
      reminderHoursBefore: 24,
      notes: notes,
      status: AppointmentStatus.planned,
    );
  }

  HealthcareProfessional newProfessional({
    required String name,
    required String specialty,
    String? address,
    String? phone,
    String? email,
    String? notes,
  }) {
    return HealthcareProfessional(
      id: _uuid.v4(),
      name: name,
      specialty: specialty,
      address: address,
      phone: phone,
      email: email,
      notes: notes,
      treatingSince: null,
    );
  }

  Appointment _appointmentFromRow(Map<String, Object?> row) {
    return Appointment(
      id: row['id'] as String,
      doctorName:
          row['doctor_name'] as String? ?? row['title'] as String? ?? 'Termin',
      specialty: row['specialty'] as String?,
      date: DateTime.parse(row['date'] as String),
      time: row['time'] as String,
      location: row['location'] as String?,
      reason: row['reason'] as String?,
      reminderEnabled: (row['reminder_enabled'] as int? ?? 1) == 1,
      reminderHoursBefore: row['reminder_hours_before'] as int? ?? 24,
      notes: row['notes'] as String?,
      status: AppointmentStatus.fromStorage(
        row['status'] as String? ?? 'Geplant',
      ),
    );
  }

  HealthcareProfessional _professionalFromRow(Map<String, Object?> row) {
    return HealthcareProfessional(
      id: row['id'] as String,
      name: row['name'] as String,
      specialty: row['specialty'] as String,
      address: row['address'] as String?,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      notes: row['notes'] as String?,
      treatingSince: _parseDate(row['treating_since'] as String?),
    );
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _dateKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }
}
