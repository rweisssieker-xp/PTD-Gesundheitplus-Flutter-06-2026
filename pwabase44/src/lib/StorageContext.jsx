import React, { createContext, useContext, useState, useEffect } from 'react';
import { getStorageMode, setStorageMode as persistMode, createEntityService } from './storageService';
import { base44 } from '@/api/base44Client';

const StorageContext = createContext(null);

// Central registry of all entity services
function buildServices(mode) {
  const entities = [
    'Medication', 'Appointment', 'BloodPressureLog', 'WeightLog',
    'Allergy', 'Vaccination', 'MedicalHistory', 'EmergencyContact',
    'TreatmentHistory', 'ScannedDocument', 'PreventiveCare',
    'HealthPass', 'MedicationLog', 'HydrationLog', 'MealLog',
    'FamilyCheckIn', 'DrugInteractionCheck', 'Notification',
    'EmergencyTracking', 'HealthcareProfessional'
  ];
  
  const services = {};
  entities.forEach(name => {
    services[name] = createEntityService(name, base44.entities[name]);
  });
  return services;
}

export function StorageProvider({ children }) {
  const [mode, setModeState] = useState(() => getStorageMode());
  const [services, setServices] = useState(() => buildServices(getStorageMode()));

  const setMode = (newMode) => {
    persistMode(newMode);
    setModeState(newMode);
    setServices(buildServices(newMode));
  };

  return (
    <StorageContext.Provider value={{ mode, setMode, services, isLocal: mode === 'local', isCloud: mode === 'cloud', isChosen: mode !== null }}>
      {children}
    </StorageContext.Provider>
  );
}

export function useStorage() {
  const ctx = useContext(StorageContext);
  if (!ctx) throw new Error('useStorage must be used within StorageProvider');
  return ctx;
}

// Convenience hook to get entity services
export function useEntities() {
  const { services } = useStorage();
  return services;
}