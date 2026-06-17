/**
 * Preventive Care Reminder Service
 * Prüft regelmäßig Vorsorgeuntersuchungen und erstellt Erinnerungen
 */

import React, { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";

export default function PreventiveCareReminderService() {
  const { data: preventiveCare = [] } = useQuery({
    queryKey: ['preventive-care-active'],
    queryFn: () => base44.entities.PreventiveCare.list(),
    refetchInterval: 3600000, // Alle 60 Minuten
  });

  useEffect(() => {
    const checkReminders = async () => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      for (const care of preventiveCare) {
        if (!care.reminder_enabled || !care.next_due_date) continue;

        const dueDate = new Date(care.next_due_date);
        dueDate.setHours(0, 0, 0, 0);

        const daysDiff = Math.floor((dueDate - today) / (1000 * 60 * 60 * 24));

        // Erinnerungen bei 30, 14, 7, 3, 1 Tage vorher
        const reminderDays = [30, 14, 7, 3, 1];
        
        if (reminderDays.includes(daysDiff)) {
          const storageKey = `preventive_reminder_${care.id}_${daysDiff}`;
          
          if (localStorage.getItem(storageKey)) continue;

          // Erstelle Benachrichtigung
          await base44.entities.Notification.create({
            title: "📋 Vorsorgeuntersuchung fällig",
            message: `${care.examination_type} ist in ${daysDiff} Tag${daysDiff !== 1 ? 'en' : ''} fällig${care.doctor ? ` bei ${care.doctor}` : ''}`,
            type: "info",
            priority: daysDiff <= 3 ? "high" : "medium",
            action_url: "/Vorsorge"
          });

          localStorage.setItem(storageKey, 'sent');

          // Browser-Benachrichtigung bei 7 und 1 Tag vorher
          if ([7, 1].includes(daysDiff) && "Notification" in window && Notification.permission === "granted") {
            new Notification("📋 Vorsorgeuntersuchung", {
              body: `${care.examination_type} ist in ${daysDiff} Tag${daysDiff !== 1 ? 'en' : ''} fällig`,
              icon: "/icon-192.png",
              tag: `preventive-${care.id}`,
              requireInteraction: daysDiff === 1
            });
          }
        }

        // Warnung bei überfällig
        if (daysDiff < 0 && daysDiff > -30) {
          const storageKey = `preventive_overdue_${care.id}`;
          if (!localStorage.getItem(storageKey)) {
            await base44.entities.Notification.create({
              title: "⚠️ Vorsorgeuntersuchung überfällig",
              message: `${care.examination_type} ist seit ${Math.abs(daysDiff)} Tag${Math.abs(daysDiff) !== 1 ? 'en' : ''} überfällig`,
              type: "warning",
              priority: "high",
              action_url: "/Vorsorge"
            });
            localStorage.setItem(storageKey, 'sent');
          }
        }
      }

      // Cleanup alte Reminder-Keys (älter als 90 Tage)
      const ninetyDaysAgo = new Date();
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
      Object.keys(localStorage).forEach(key => {
        if (key.startsWith('preventive_reminder_') || key.startsWith('preventive_overdue_')) {
          localStorage.removeItem(key);
        }
      });
    };

    checkReminders();
    const interval = setInterval(checkReminders, 3600000); // Stündlich prüfen

    return () => clearInterval(interval);
  }, [preventiveCare]);

  return null;
}