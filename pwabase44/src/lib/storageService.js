/**
 * Hybrid Storage Service
 * Transparently switches between localStorage (local mode) and Cloud (cloud mode).
 * Mode is stored in localStorage under 'storage_mode' key.
 */

const STORAGE_MODE_KEY = 'gesundheit_storage_mode';
const LOCAL_PREFIX = 'gp_local_';

export function getStorageMode() {
  return localStorage.getItem(STORAGE_MODE_KEY) || null; // null = not chosen yet
}

export function setStorageMode(mode) {
  localStorage.setItem(STORAGE_MODE_KEY, mode); // 'local' or 'cloud'
}

function localKey(entity) {
  return `${LOCAL_PREFIX}${entity}`;
}

function getLocalData(entity) {
  const raw = localStorage.getItem(localKey(entity));
  return raw ? JSON.parse(raw) : [];
}

function saveLocalData(entity, data) {
  localStorage.setItem(localKey(entity), JSON.stringify(data));
}

function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

/**
 * Creates a storage-aware entity interface.
 * Usage: createEntityService('Medication', base44.entities.Medication)
 */
export function createEntityService(entityName, cloudEntity) {
  return {
    async list(sortField = '-created_date') {
      if (getStorageMode() === 'local') {
        const data = getLocalData(entityName);
        // Simple sort by created_date desc
        return [...data].sort((a, b) => 
          new Date(b.created_date || 0) - new Date(a.created_date || 0)
        );
      }
      return cloudEntity.list(sortField);
    },

    async filter(query, sortField = '-created_date', limit = 50) {
      if (getStorageMode() === 'local') {
        const data = getLocalData(entityName);
        const filtered = data.filter(item => {
          return Object.entries(query).every(([key, value]) => item[key] === value);
        });
        return filtered.sort((a, b) => 
          new Date(b.created_date || 0) - new Date(a.created_date || 0)
        );
      }
      return cloudEntity.filter(query, sortField, limit);
    },

    async get(id) {
      if (getStorageMode() === 'local') {
        const data = getLocalData(entityName);
        return data.find(item => item.id === id) || null;
      }
      return cloudEntity.get(id);
    },

    async create(itemData) {
      if (getStorageMode() === 'local') {
        const data = getLocalData(entityName);
        const newItem = {
          ...itemData,
          id: generateId(),
          created_date: new Date().toISOString(),
          updated_date: new Date().toISOString(),
        };
        data.push(newItem);
        saveLocalData(entityName, data);
        return newItem;
      }
      return cloudEntity.create(itemData);
    },

    async update(id, itemData) {
      if (getStorageMode() === 'local') {
        const data = getLocalData(entityName);
        const index = data.findIndex(item => item.id === id);
        if (index === -1) throw new Error(`Item ${id} not found in ${entityName}`);
        data[index] = { ...data[index], ...itemData, updated_date: new Date().toISOString() };
        saveLocalData(entityName, data);
        return data[index];
      }
      return cloudEntity.update(id, itemData);
    },

    async delete(id) {
      if (getStorageMode() === 'local') {
        const data = getLocalData(entityName);
        const filtered = data.filter(item => item.id !== id);
        saveLocalData(entityName, filtered);
        return true;
      }
      return cloudEntity.delete(id);
    },

    async bulkCreate(items) {
      if (getStorageMode() === 'local') {
        const results = [];
        for (const item of items) {
          results.push(await this.create(item));
        }
        return results;
      }
      return cloudEntity.bulkCreate(items);
    },

    subscribe(callback) {
      if (getStorageMode() === 'local') {
        // No real-time for local mode, return noop
        return () => {};
      }
      return cloudEntity.subscribe(callback);
    }
  };
}

/**
 * Export all local data as JSON for backup
 */
export function exportLocalData() {
  const entities = [
    'Medication', 'Appointment', 'BloodPressureLog', 'WeightLog',
    'Allergy', 'Vaccination', 'MedicalHistory', 'EmergencyContact',
    'TreatmentHistory', 'ScannedDocument', 'PreventiveCare',
    'HealthPass', 'MedicationLog', 'HydrationLog', 'MealLog',
    'FamilyCheckIn', 'DrugInteractionCheck', 'Notification'
  ];
  const backup = { exported_at: new Date().toISOString(), data: {} };
  entities.forEach(name => {
    backup.data[name] = getLocalData(name);
  });
  return backup;
}

/**
 * Clear all local data
 */
export function clearLocalData() {
  const keys = Object.keys(localStorage).filter(k => k.startsWith(LOCAL_PREFIX));
  keys.forEach(k => localStorage.removeItem(k));
}