class AppTable {
  const AppTable(this.actualTableName);

  final String actualTableName;
}

class AppTables {
  const AppTables._();

  static const localProfiles = AppTable('local_profiles');
  static const medications = AppTable('medications');
  static const medicationLogs = AppTable('medication_logs');
  static const appointments = AppTable('appointments');
  static const allergies = AppTable('allergies');
  static const emergencyContacts = AppTable('emergency_contacts');
  static const notifications = AppTable('notifications');
  static const consentSettings = AppTable('consent_settings');

  static const all = [
    localProfiles,
    medications,
    medicationLogs,
    appointments,
    allergies,
    emergencyContacts,
    notifications,
    consentSettings,
  ];
}
