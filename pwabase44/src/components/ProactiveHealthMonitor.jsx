/**
 * Proactive Health Monitor
 * Background service that monitors health data and sends proactive alerts
 */

import { useEffect, useState } from "react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";

/**
 * Check for medication refill needs
 */
const checkMedicationRefills = async () => {
  try {
    const medications = await base44.entities.Medication.filter({ active: true });
    
    const needsRefill = medications.filter(m => {
      if (!m.supply_duration_days || !m.start_date) return false;
      
      const startDate = new Date(m.start_date);
      const daysSinceStart = Math.floor((new Date() - startDate) / (1000 * 60 * 60 * 24));
      const daysRemaining = m.supply_duration_days - daysSinceStart;
      const reminderDays = m.refill_reminder_days || 7;
      
      return daysRemaining <= reminderDays && daysRemaining > 0;
    });

    if (needsRefill.length > 0) {
      // Check if we already created a notification today
      const today = new Date().toISOString().split('T')[0];
      const existingNotifications = await base44.entities.Notification.filter({
        type: 'medication_refill',
        created_date: { $gte: today }
      });

      if (existingNotifications.length === 0) {
        for (const med of needsRefill) {
          await base44.entities.Notification.create({
            title: '💊 Medikament bald aufgebraucht',
            message: `${med.name} - Bitte fordern Sie ein neues Rezept an.`,
            type: 'medication_refill',
            priority: 'medium',
            related_medication_id: med.id,
            action_url: '/Medikation'
          });
        }

        toast.warning(`${needsRefill.length} Medikament(e) bald aufgebraucht`, {
          description: 'Rezept anfordern nicht vergessen'
        });
      }
    }
  } catch (error) {
    console.error('Medication refill check error:', error);
  }
};

/**
 * Check for critical medication interactions
 */
const checkMedicationInteractions = async () => {
  try {
    const medications = await base44.entities.Medication.filter({ active: true });
    
    if (medications.length < 2) return;

    // Get user's emergency profile for known interactions
    const user = await base44.auth.me();
    
    if (user.emergency_profile?.medication_interactions) {
      const criticalInteractions = user.emergency_profile.medication_interactions.filter(
        i => i.severity === 'critical' || i.severity === 'major'
      );

      if (criticalInteractions.length > 0) {
        // Check if we already notified about this
        const existingNotifications = await base44.entities.Notification.filter({
          type: 'warning',
          message: { $regex: 'Medikamenten-Interaktion' }
        });

        if (existingNotifications.length === 0) {
          await base44.entities.Notification.create({
            title: '⚠️ Medikamenten-Interaktion erkannt',
            message: `${criticalInteractions.length} potenzielle Interaktion(en) in Ihrem KI-Notfallprofil. Bitte mit Ihrem Arzt besprechen.`,
            type: 'warning',
            priority: 'high',
            action_url: '/Notfallprofil'
          });

          toast.warning('Medikamenten-Interaktion erkannt', {
            description: 'Prüfen Sie Ihr Notfallprofil'
          });
        }
      }
    }
  } catch (error) {
    console.error('Interaction check error:', error);
  }
};

/**
 * Check for missing emergency contacts
 */
const checkEmergencyContacts = async () => {
  try {
    const contacts = await base44.entities.EmergencyContact.list();
    
    if (contacts.length === 0) {
      const existingNotifications = await base44.entities.Notification.filter({
        type: 'warning',
        message: { $regex: 'Notfallkontakte' }
      });

      if (existingNotifications.length === 0) {
        await base44.entities.Notification.create({
          title: '🚨 Keine Notfallkontakte eingerichtet',
          message: 'Für Ihre Sicherheit: Bitte richten Sie mindestens einen Notfallkontakt ein.',
          type: 'warning',
          priority: 'high',
          action_url: '/Notfall-Einrichtung'
        });
      }
    } else {
      // Check for unverified contacts
      const unverified = contacts.filter(c => {
        const vs = c.verification_status || {};
        return (c.notify_via_sms && !vs.phone_verified) ||
               (c.notify_via_telegram && !vs.telegram_verified) ||
               (c.notify_via_whatsapp && !vs.whatsapp_verified);
      });

      if (unverified.length === contacts.length && contacts.length > 0) {
        const existingNotifications = await base44.entities.Notification.filter({
          type: 'info',
          message: { $regex: 'verifizieren' }
        });

        if (existingNotifications.length === 0) {
          await base44.entities.Notification.create({
            title: '🔐 Notfallkontakte verifizieren',
            message: `${unverified.length} Kontakt(e) noch nicht verifiziert. Stellen Sie sicher, dass Benachrichtigungen ankommen.`,
            type: 'info',
            priority: 'medium',
            action_url: '/Notfall-Einrichtung'
          });
        }
      }
    }
  } catch (error) {
    console.error('Emergency contacts check error:', error);
  }
};

/**
 * Check if emergency profile is outdated
 */
const checkEmergencyProfile = async () => {
  try {
    const user = await base44.auth.me();
    
    if (!user.emergency_profile) {
      const existingNotifications = await base44.entities.Notification.filter({
        type: 'info',
        message: { $regex: 'Notfallprofil' }
      });

      if (existingNotifications.length === 0) {
        await base44.entities.Notification.create({
          title: '🧠 KI-Notfallprofil erstellen',
          message: 'Erstellen Sie ein KI-generiertes Notfallprofil für Ersthelfer - kann Leben retten!',
          type: 'info',
          priority: 'medium',
          action_url: '/Notfall-Einrichtung'
        });
      }
    } else {
      const profileAge = Math.floor(
        (new Date() - new Date(user.emergency_profile.generated_at)) / (1000 * 60 * 60 * 24)
      );

      if (profileAge > 90) {
        await base44.entities.Notification.create({
          title: '🔄 Notfallprofil aktualisieren',
          message: `Ihr Notfallprofil ist ${profileAge} Tage alt. Aktualisierung empfohlen.`,
          type: 'info',
          priority: 'low',
          action_url: '/Notfall-Einrichtung'
        });
      }
    }
  } catch (error) {
    console.error('Profile check error:', error);
  }
};

/**
 * Main Proactive Health Monitor Component
 */
export default function ProactiveHealthMonitor() {
  useEffect(() => {
    // Initial checks after 5 seconds
    const initialTimer = setTimeout(() => {
      runHealthChecks();
    }, 5000);

    // Run checks every 6 hours
    const interval = setInterval(() => {
      runHealthChecks();
    }, 6 * 60 * 60 * 1000);

    return () => {
      clearTimeout(initialTimer);
      clearInterval(interval);
    };
  }, []);

  const runHealthChecks = async () => {
    try {
      console.log('Running proactive health checks...');
      
      await Promise.all([
        checkMedicationRefills(),
        checkMedicationInteractions(),
        checkEmergencyContacts(),
        checkEmergencyProfile()
      ]);

      console.log('Proactive health checks completed');
    } catch (error) {
      console.error('Health checks error:', error);
    }
  };

  // This component doesn't render anything
  return null;
}