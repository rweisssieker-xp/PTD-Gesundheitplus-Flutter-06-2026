/**
 * Medication Reminder Service
 * Client-seitige lokale Benachrichtigungen für Medikamenten-Erinnerungen
 * Läuft im Hintergrund und zeigt Browser-Benachrichtigungen zu den eingestellten Zeiten
 */

import React, { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";

export default function MedicationReminderService() {
  const [permissionGranted, setPermissionGranted] = useState(false);

  // Lade aktive Medikamente mit Erinnerungen
  const { data: medications = [] } = useQuery({
    queryKey: ['medications-active'],
    queryFn: () => base44.entities.Medication.filter({ active: true }),
    refetchInterval: 60000, // Alle 60 Sekunden aktualisieren
  });

  // Browser-Benachrichtigungsberechtigung anfordern
  useEffect(() => {
    if ("Notification" in window) {
      if (Notification.permission === "granted") {
        setPermissionGranted(true);
      } else if (Notification.permission !== "denied") {
        Notification.requestPermission().then((permission) => {
          setPermissionGranted(permission === "granted");
        });
      }
    }
  }, []);

  // Hauptlogik: Überwache Erinnerungszeiten
  useEffect(() => {
    if (!permissionGranted || medications.length === 0) return;

    const checkReminders = async () => {
      const now = new Date();
      const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
      const currentDay = now.toDateString();
      const dateStr = now.toISOString().split('T')[0];

      // Hole alle Logs für heute
      const todayLogs = await base44.entities.MedicationLog.filter({ date: dateStr });

      medications.forEach((med) => {
        if (!med.reminder_enabled || !med.reminder_times || med.reminder_times.length === 0) {
          return;
        }

        med.reminder_times.forEach(async (reminderTime) => {
          if (!reminderTime) return;

          // Prüfe, ob die aktuelle Zeit mit der Erinnerungszeit übereinstimmt
          if (currentTime === reminderTime) {
            const storageKey = `med_reminder_${med.id}_${currentDay}_${reminderTime}`;
            
            // Prüfe, ob wir heute bereits erinnert haben (verhindert Duplikate)
            if (localStorage.getItem(storageKey)) {
              return;
            }

            // Prüfe ob Log existiert, sonst erstelle einen
            let log = todayLogs.find(l => 
              l.medication_id === med.id && 
              l.scheduled_time === reminderTime
            );

            if (!log) {
              log = await base44.entities.MedicationLog.create({
                medication_id: med.id,
                medication_name: med.name,
                scheduled_time: reminderTime,
                dosage_taken: med.dosage,
                status: "pending",
                date: dateStr,
                reminder_sent: true
              });
            } else if (!log.reminder_sent) {
              await base44.entities.MedicationLog.update(log.id, {
                ...log,
                reminder_sent: true
              });
            }

            // Zeige Benachrichtigung
            showNotification(med, reminderTime);

            // Markiere als heute gesendet
            localStorage.setItem(storageKey, 'sent');

            // Erstelle Benachrichtigung in der App
            createAppNotification(med, reminderTime);
          }
        });
      });
    };

    // Initialer Check
    checkReminders();

    // Prüfe alle 30 Sekunden
    const interval = setInterval(checkReminders, 30000);

    // Cleanup
    return () => clearInterval(interval);
  }, [medications, permissionGranted]);

  const showNotification = (medication, time) => {
    if (!("Notification" in window) || Notification.permission !== "granted") {
      return;
    }

    const notification = new Notification("💊 Medikamenten-Erinnerung", {
      body: `Zeit für: ${medication.name} (${medication.dosage})\nUm ${time}`,
      icon: "/icon-192.png", // PWA Icon
      badge: "/badge-72.png",
      tag: `medication-${medication.id}-${time}`,
      requireInteraction: true, // Bleibt sichtbar bis User reagiert
      vibrate: [200, 100, 200],
      data: {
        medicationId: medication.id,
        medicationName: medication.name,
        time: time
      }
    });

    // Sound abspielen (optional)
    try {
      const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBTGH0fPTgjMGHm7A7+OZUR');
      audio.volume = 0.3;
      audio.play().catch(() => {}); // Ignoriere Fehler (z.B. wenn Autoplay blockiert)
    } catch (e) {
      // Ignoriere Audio-Fehler
    }

    // Klick auf Benachrichtigung öffnet Tagesplan
    notification.onclick = () => {
      window.focus();
      window.location.href = '/Medikamenten-Tagesplan';
      notification.close();
    };
  };

  const createAppNotification = async (medication, time) => {
    try {
      await base44.entities.Notification.create({
        title: "💊 Medikamenten-Erinnerung",
        message: `Zeit für ${medication.name} (${medication.dosage}) um ${time}`,
        type: "info",
        priority: "medium",
        action_url: "/Medikamenten-Tagesplan"
      });
    } catch (error) {
      console.error("Fehler beim Erstellen der App-Benachrichtigung:", error);
    }
  };

  // Aufräumen alter Einträge (älter als 2 Tage)
  useEffect(() => {
    const cleanup = () => {
      const twoDaysAgo = new Date();
      twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);

      Object.keys(localStorage).forEach((key) => {
        if (key.startsWith('med_reminder_')) {
          const parts = key.split('_');
          if (parts.length >= 4) {
            try {
              const dateStr = parts.slice(2, -1).join('_');
              const itemDate = new Date(dateStr);
              if (itemDate < twoDaysAgo) {
                localStorage.removeItem(key);
              }
            } catch (e) {
              localStorage.removeItem(key);
            }
          }
        }
      });
    };

    cleanup();
    const cleanupInterval = setInterval(cleanup, 24 * 60 * 60 * 1000);

    return () => clearInterval(cleanupInterval);
  }, []);

  // Keine UI - läuft unsichtbar im Hintergrund
  return null;
}