class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    this.relationship,
    this.phone,
    this.role,
  });

  final String id;
  final String name;
  final String? relationship;
  final String? phone;
  final String? role;
}

class FamilyCheckIn {
  const FamilyCheckIn({
    required this.id,
    this.memberId,
    required this.memberName,
    required this.status,
    this.note,
    this.locationText,
    required this.checkedAt,
  });

  final String id;
  final String? memberId;
  final String memberName;
  final String status;
  final String? note;
  final String? locationText;
  final DateTime checkedAt;
}

class DementiaLog {
  const DementiaLog({
    required this.id,
    required this.type,
    required this.value,
    this.note,
    required this.loggedAt,
  });

  final String id;
  final String type;
  final String value;
  final String? note;
  final DateTime loggedAt;
}
