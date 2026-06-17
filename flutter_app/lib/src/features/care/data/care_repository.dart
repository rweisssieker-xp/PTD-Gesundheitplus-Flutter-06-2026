import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/care.dart';

class CareRepository {
  CareRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> addFamilyMember({
    required String name,
    String? relationship,
    String? phone,
    String? role,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO family_members (id, name, relationship, phone, role, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [_uuid.v4(), name, relationship, phone, role, now, now],
    );
  }

  Future<List<FamilyMember>> listFamilyMembers() async {
    final rows = _db.select(
      'SELECT id, name, relationship, phone, role FROM family_members ORDER BY name ASC',
    );
    return rows
        .map(
          (row) => FamilyMember(
            id: row['id'] as String,
            name: row['name'] as String,
            relationship: row['relationship'] as String?,
            phone: row['phone'] as String?,
            role: row['role'] as String?,
          ),
        )
        .toList();
  }

  Future<void> addCheckIn({
    String? memberId,
    required String memberName,
    required String status,
    String? note,
    String? locationText,
    DateTime? checkedAt,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO family_check_ins (
        id, member_id, member_name, status, note, location_text, checked_at, created_at, updated_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        memberId,
        memberName,
        status,
        note,
        locationText,
        (checkedAt ?? DateTime.now()).toIso8601String(),
        now,
        now,
      ],
    );
  }

  Future<List<FamilyCheckIn>> listCheckIns() async {
    final rows = _db.select('''
      SELECT id, member_id, member_name, status, note, location_text, checked_at
      FROM family_check_ins
      ORDER BY checked_at DESC
      ''');
    return rows
        .map(
          (row) => FamilyCheckIn(
            id: row['id'] as String,
            memberId: row['member_id'] as String?,
            memberName: row['member_name'] as String,
            status: row['status'] as String,
            note: row['note'] as String?,
            locationText: row['location_text'] as String?,
            checkedAt: DateTime.parse(row['checked_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> addDementiaLog({
    required String type,
    required String value,
    String? note,
    DateTime? loggedAt,
  }) async {
    final now = DateTime.now().toIso8601String();
    _db.execute(
      '''
      INSERT INTO dementia_logs (id, type, value, note, logged_at, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        _uuid.v4(),
        type,
        value,
        note,
        (loggedAt ?? DateTime.now()).toIso8601String(),
        now,
        now,
      ],
    );
  }

  Future<List<DementiaLog>> listDementiaLogs() async {
    final rows = _db.select(
      'SELECT id, type, value, note, logged_at FROM dementia_logs ORDER BY logged_at DESC',
    );
    return rows
        .map(
          (row) => DementiaLog(
            id: row['id'] as String,
            type: row['type'] as String,
            value: row['value'] as String,
            note: row['note'] as String?,
            loggedAt: DateTime.parse(row['logged_at'] as String),
          ),
        )
        .toList();
  }
}
