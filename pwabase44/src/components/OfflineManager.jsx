/**
 * Offline Manager
 * Handles caching of critical emergency data for offline access
 * Automatically syncs when online and provides offline fallbacks
 */

import { useEffect, useState } from "react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";

const CACHE_KEYS = {
  EMERGENCY_PROFILE: 'gesundheit_plus_emergency_profile',
  EMERGENCY_CONTACTS: 'gesundheit_plus_emergency_contacts',
  USER_DATA: 'gesundheit_plus_user_data',
  MEDICATIONS: 'gesundheit_plus_medications',
  ALLERGIES: 'gesundheit_plus_allergies',
  LAST_SYNC: 'gesundheit_plus_last_sync'
};

/**
 * Save data to localStorage with error handling
 */
const saveToCache = (key, data) => {
  try {
    localStorage.setItem(key, JSON.stringify({
      data,
      timestamp: new Date().toISOString()
    }));
    return true;
  } catch (error) {
    console.error(`Failed to cache ${key}:`, error);
    return false;
  }
};

/**
 * Load data from localStorage
 */
const loadFromCache = (key) => {
  try {
    const cached = localStorage.getItem(key);
    if (!cached) return null;
    return JSON.parse(cached);
  } catch (error) {
    console.error(`Failed to load from cache ${key}:`, error);
    return null;
  }
};

/**
 * Check if user is online
 */
const checkOnlineStatus = () => {
  return navigator.onLine;
};

/**
 * Sync critical emergency data to localStorage
 */
export const syncEmergencyData = async () => {
  try {
    // Fetch all critical data
    const [user, contacts, medications, allergies] = await Promise.all([
      base44.auth.me().catch(() => null),
      base44.entities.EmergencyContact.list().catch(() => []),
      base44.entities.Medication.filter({ active: true }).catch(() => []),
      base44.entities.Allergy.list().catch(() => [])
    ]);

    // Cache everything
    const results = {
      user: saveToCache(CACHE_KEYS.USER_DATA, user),
      profile: user?.emergency_profile ? saveToCache(CACHE_KEYS.EMERGENCY_PROFILE, user.emergency_profile) : true,
      contacts: saveToCache(CACHE_KEYS.EMERGENCY_CONTACTS, contacts),
      medications: saveToCache(CACHE_KEYS.MEDICATIONS, medications),
      allergies: saveToCache(CACHE_KEYS.ALLERGIES, allergies)
    };

    // Update last sync time
    saveToCache(CACHE_KEYS.LAST_SYNC, new Date().toISOString());

    const allSuccess = Object.values(results).every(r => r);
    return {
      success: allSuccess,
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error("Failed to sync emergency data:", error);
    return { success: false, error: error.message };
  }
};

/**
 * Get cached emergency data
 */
export const getCachedEmergencyData = () => {
  const user = loadFromCache(CACHE_KEYS.USER_DATA);
  const profile = loadFromCache(CACHE_KEYS.EMERGENCY_PROFILE);
  const contacts = loadFromCache(CACHE_KEYS.EMERGENCY_CONTACTS);
  const medications = loadFromCache(CACHE_KEYS.MEDICATIONS);
  const allergies = loadFromCache(CACHE_KEYS.ALLERGIES);
  const lastSync = loadFromCache(CACHE_KEYS.LAST_SYNC);

  return {
    user: user?.data || null,
    emergencyProfile: profile?.data || null,
    contacts: contacts?.data || [],
    medications: medications?.data || [],
    allergies: allergies?.data || [],
    lastSync: lastSync?.data || null,
    hasCachedData: !!(user || profile || contacts)
  };
};

/**
 * Clear all cached data
 */
export const clearCache = () => {
  Object.values(CACHE_KEYS).forEach(key => {
    try {
      localStorage.removeItem(key);
    } catch (error) {
      console.error(`Failed to clear ${key}:`, error);
    }
  });
};

/**
 * Offline Manager Component
 * Automatically syncs data when online and monitors connection status
 */
export default function OfflineManager() {
  const [isOnline, setIsOnline] = useState(checkOnlineStatus());
  const [lastSyncTime, setLastSyncTime] = useState(null);
  const [isSyncing, setIsSyncing] = useState(false);

  // Load last sync time on mount
  useEffect(() => {
    const cached = loadFromCache(CACHE_KEYS.LAST_SYNC);
    if (cached?.data) {
      setLastSyncTime(cached.data);
    }
  }, []);

  // Monitor online/offline status
  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      console.log("App is now online");
      // Auto-sync when coming back online
      performSync();
    };

    const handleOffline = () => {
      setIsOnline(false);
      console.log("App is now offline");
      toast.warning("Offline-Modus aktiviert", {
        description: "Notfalldaten bleiben verfügbar"
      });
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Initial sync on mount if online
  useEffect(() => {
    if (isOnline) {
      performSync();
    }
  }, []);

  const performSync = async () => {
    if (isSyncing) return;
    
    setIsSyncing(true);
    try {
      const result = await syncEmergencyData();
      if (result.success) {
        setLastSyncTime(result.timestamp);
        console.log("Emergency data synced successfully");
      }
    } catch (error) {
      console.error("Sync failed:", error);
    } finally {
      setIsSyncing(false);
    }
  };

  // This component doesn't render anything
  return null;
}

export { checkOnlineStatus };