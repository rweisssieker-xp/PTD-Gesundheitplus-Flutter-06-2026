import { useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { useQueryClient } from "@tanstack/react-query";
import { addDays, isBefore, isAfter, differenceInDays } from "date-fns";
import { toast } from "sonner";
import { generateAllRecommendations } from "./PreventionEngine";

export default function NotificationService() {
  const queryClient = useQueryClient();

  useEffect(() => {
    // Request notification permission on mount
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }

    // Check for alerts every time the app loads
    checkForAlerts();

    // Set up periodic checks (every 6 hours)
    const interval = setInterval(checkForAlerts, 6 * 60 * 60 * 1000);
    
    return () => clearInterval(interval);
  }, []);

  const sendPushNotification = (title, body, priority = 'medium') => {
    if ('Notification' in window && Notification.permission === 'granted') {
      const notification = new Notification(title, {
        body: body,
        icon: '/icon-192.png',
        badge: '/icon-192.png',
        tag: 'gesundheit-plus',
        requireInteraction: priority === 'high',
        vibrate: priority === 'high' ? [200, 100, 200] : [100]
      });

      notification.onclick = () => {
        window.focus();
        notification.close();
      };
    }
  };

  const createNotification = async (title, message, type, priority = 'medium', actionUrl = null) => {
    try {
      await base44.entities.Notification.create({
        title,
        message,
        type,
        priority,
        action_url: actionUrl
      });
      
      // Send push notification for high priority alerts
      if (priority === 'high') {
        sendPushNotification(title, message, priority);
      }

      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    } catch (error) {
      console.error("Failed to create notification:", error);
    }
  };

  const checkMedicationRefills = async () => {
    try {
      const medications = await base44.entities.Medication.list();
      const today = new Date();

      for (const med of medications) {
        if (!med.active || !med.supply_duration_days) continue;

        // Calculate when medication will run out
        const startDate = med.start_date ? new Date(med.start_date) : today;
        const runOutDate = addDays(startDate, med.supply_duration_days);
        const daysUntilRunOut = differenceInDays(runOutDate, today);

        // Alert 7 days before running out
        if (daysUntilRunOut <= 7 && daysUntilRunOut > 0) {
          const existingNotifications = await base44.entities.Notification.filter({
            type: 'medication_refill',
            message: { $regex: med.name }
          });

          // Only create if no recent notification exists
          if (existingNotifications.length === 0) {
            await createNotification(
              "Rezept nachfüllen",
              `Ihr Medikament "${med.name}" wird in ${daysUntilRunOut} Tagen zur Neige gehen. Bitte rechtzeitig ein neues Rezept besorgen.`,
              'warning',
              daysUntilRunOut <= 3 ? 'high' : 'medium',
              '/Medikation'
            );
          }
        }

        // Urgent alert if already running out
        if (daysUntilRunOut <= 0 && daysUntilRunOut > -7) {
          await createNotification(
            "⚠️ Medikament zur Neige!",
            `Ihr Medikament "${med.name}" sollte nachgefüllt werden. Kontaktieren Sie Ihren Arzt für ein neues Rezept.`,
            'warning',
            'high',
            '/Medikation'
          );
        }
      }
    } catch (error) {
      console.error("Failed to check medication refills:", error);
    }
  };

  const checkUpcomingAppointments = async () => {
    try {
      const appointments = await base44.entities.Appointment.list();
      const today = new Date();
      const tomorrow = addDays(today, 1);
      const in3Days = addDays(today, 3);

      for (const appt of appointments) {
        const apptDate = new Date(`${appt.date}T${appt.time}`);
        
        if (isBefore(apptDate, today)) continue; // Skip past appointments

        const daysUntil = differenceInDays(apptDate, today);

        // Reminder 3 days before
        if (daysUntil === 3) {
          await createNotification(
            "Termin in 3 Tagen",
            `Erinnerung: Termin bei ${appt.doctor_name} am ${new Date(appt.date).toLocaleDateString('de-DE')} um ${appt.time} Uhr.`,
            'appointment_reminder',
            'medium',
            '/Termine'
          );
        }

        // Reminder 1 day before (high priority)
        if (daysUntil === 1) {
          await createNotification(
            "Termin morgen!",
            `Ihr Termin bei ${appt.doctor_name} ist morgen um ${appt.time} Uhr. ${appt.location ? `Ort: ${appt.location}` : ''}`,
            'appointment_reminder',
            'high',
            '/Termine'
          );
        }

        // Reminder on the same day (very urgent)
        if (daysUntil === 0) {
          const hoursUntil = Math.floor((apptDate.getTime() - today.getTime()) / (1000 * 60 * 60));
          if (hoursUntil <= 2 && hoursUntil > 0) {
            await createNotification(
              "🚨 Termin heute!",
              `Ihr Termin bei ${appt.doctor_name} ist in ${hoursUntil} Stunden um ${appt.time} Uhr!`,
              'appointment_reminder',
              'high',
              '/Termine'
            );
          }
        }
      }
    } catch (error) {
      console.error("Failed to check upcoming appointments:", error);
    }
  };

  const checkPreventionRecommendations = async () => {
    try {
      const user = await base44.auth.me();
      
      // Check if we need to run prevention check
      const lastCheck = user.last_prevention_check 
        ? new Date(user.last_prevention_check)
        : new Date(0);
      
      const daysSinceLastCheck = differenceInDays(new Date(), lastCheck);
      
      // Run check every 7 days
      if (daysSinceLastCheck < 7) return;

      // Generate all recommendations
      const recommendations = await generateAllRecommendations(user);

      // Update last check time
      await base44.auth.updateMe({
        last_prevention_check: new Date().toISOString()
      });

      // Notify about high-priority vaccinations
      const urgentVaccinations = recommendations.vaccinations
        .filter(v => v.urgency === 'high')
        .slice(0, 3);

      for (const vacc of urgentVaccinations) {
        const existing = await base44.entities.Notification.filter({
          type: 'vaccination_reminder',
          message: { $regex: vacc.vaccine }
        });

        if (existing.length === 0) {
          await createNotification(
            `💉 Impfung empfohlen: ${vacc.vaccine}`,
            vacc.reason,
            'info',
            'high',
            '/Impfpass'
          );
        }
      }

      // Notify about screenings
      const urgentScreenings = recommendations.screenings
        .filter(s => s.urgency === 'high')
        .slice(0, 2);

      for (const screening of urgentScreenings) {
        const existing = await base44.entities.Notification.filter({
          type: 'info',
          message: { $regex: screening.name }
        });

        if (existing.length === 0) {
          await createNotification(
            `🏥 Vorsorge empfohlen: ${screening.name}`,
            `${screening.reason}. Häufigkeit: ${screening.frequency}`,
            'info',
            'medium',
            '/Vorsorge'
          );
        }
      }

      // Pregnancy recommendations
      if (user.is_pregnant && recommendations.pregnancy.length > 0) {
        const urgentPregnancy = recommendations.pregnancy
          .filter(p => p.urgency === 'high')
          .slice(0, 2);

        for (const rec of urgentPregnancy) {
          await createNotification(
            `🤰 Schwangerschaft: ${rec.name}`,
            rec.reason,
            'info',
            'high',
            '/Vorsorge'
          );
        }
      }

      // Summary notification if there are recommendations
      if (recommendations.total > 0) {
        await createNotification(
          "📋 Neue Gesundheitsempfehlungen",
          `Es gibt ${recommendations.total} neue Empfehlungen für Sie: ${recommendations.vaccinations.length} Impfungen, ${recommendations.screenings.length} Vorsorgeuntersuchungen${user.is_pregnant ? `, ${recommendations.pregnancy.length} Schwangerschaftstermine` : ''}.`,
          'info',
          'medium',
          '/Vorsorge'
        );
      }

    } catch (error) {
      console.error("Failed to check prevention recommendations:", error);
    }
  };

  const checkForAlerts = async () => {
    try {
      await Promise.all([
        checkMedicationRefills(),
        checkUpcomingAppointments(),
        checkPreventionRecommendations()
      ]);
    } catch (error) {
      console.error("Failed to check for alerts:", error);
    }
  };

  // This component doesn't render anything
  return null;
}