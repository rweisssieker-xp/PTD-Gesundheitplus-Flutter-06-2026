import 'package:flutter_test/flutter_test.dart';
import 'package:gesundheitplus/src/core/storage/app_database.dart';
import 'package:gesundheitplus/src/features/appointments/data/appointment_repository.dart';
import 'package:gesundheitplus/src/features/appointments/domain/appointment.dart';

void main() {
  test('creates and lists appointments', () async {
    final db = AppDatabase.memory();
    final repo = AppointmentRepository(db);
    final appointment = repo.newAppointment(
      doctorName: 'Dr. Muster',
      specialty: 'Allgemeinmedizin',
      date: DateTime(2026, 6, 18),
      time: '09:30',
      reason: 'Kontrolle',
    );
    await repo.saveAppointment(appointment);
    final appointments = await repo.listAppointments();
    expect(appointments.single.doctorName, 'Dr. Muster');
    expect(appointments.single.startsAt, DateTime(2026, 6, 18, 9, 30));
    db.close();
  });

  test('creates and lists healthcare professionals', () async {
    final db = AppDatabase.memory();
    final repo = AppointmentRepository(db);
    await repo.saveProfessional(
      repo.newProfessional(
        name: 'Dr. Zahn',
        specialty: 'Zahnmedizin',
        phone: '+49123',
      ),
    );
    final professionals = await repo.listProfessionals();
    expect(professionals.single.name, 'Dr. Zahn');
    expect(professionals.single.specialty, 'Zahnmedizin');
    db.close();
  });

  test('updates appointment status', () async {
    final db = AppDatabase.memory();
    final repo = AppointmentRepository(db);
    final appointment = repo.newAppointment(
      doctorName: 'Dr. Muster',
      date: DateTime(2026, 6, 18),
      time: '09:30',
    );
    await repo.saveAppointment(appointment);
    await repo.saveAppointment(
      appointment.copyWith(status: AppointmentStatus.completed),
    );
    final appointments = await repo.listAppointments();
    expect(appointments.single.status, AppointmentStatus.completed);
    db.close();
  });
}
