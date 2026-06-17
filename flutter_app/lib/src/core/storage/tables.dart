class AppTable {
  const AppTable(this.actualTableName);

  final String actualTableName;
}

class AppTables {
  const AppTables._();

  static const localProfiles = AppTable('local_profiles');
  static const medications = AppTable('medications');
  static const medicationLogs = AppTable('medication_logs');
  static const medicationInteractionGuidance = AppTable(
    'medication_interaction_guidance',
  );
  static const medicationInteractionChecks = AppTable(
    'medication_interaction_checks',
  );
  static const appointments = AppTable('appointments');
  static const healthcareProfessionals = AppTable('healthcare_professionals');
  static const medicalHistoryEntries = AppTable('medical_history_entries');
  static const treatmentRecords = AppTable('treatment_records');
  static const allergies = AppTable('allergies');
  static const bloodPressureLogs = AppTable('blood_pressure_logs');
  static const weightLogs = AppTable('weight_logs');
  static const vaccinations = AppTable('vaccinations');
  static const preventiveCareItems = AppTable('preventive_care_items');
  static const healthDocuments = AppTable('health_documents');
  static const emergencyContacts = AppTable('emergency_contacts');
  static const notifications = AppTable('notifications');
  static const consentSettings = AppTable('consent_settings');
  static const communicationPreferences = AppTable('communication_preferences');
  static const familyMembers = AppTable('family_members');
  static const familyCheckIns = AppTable('family_check_ins');
  static const dementiaLogs = AppTable('dementia_logs');

  static const all = [
    localProfiles,
    medications,
    medicationLogs,
    medicationInteractionGuidance,
    medicationInteractionChecks,
    appointments,
    healthcareProfessionals,
    medicalHistoryEntries,
    treatmentRecords,
    allergies,
    bloodPressureLogs,
    weightLogs,
    vaccinations,
    preventiveCareItems,
    healthDocuments,
    emergencyContacts,
    notifications,
    consentSettings,
    communicationPreferences,
    familyMembers,
    familyCheckIns,
    dementiaLogs,
  ];
}
