/**
 * Dementia Reminder Service
 * Handles hydration and meal reminders for dementia patients
 * Runs in background and sends notifications at appropriate times
 */

import { useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";

/**
 * Check if current time is within active hours
 */
const isWithinActiveHours = (startTime, endTime) => {
  const now = new Date();
  const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  
  return currentTime >= startTime && currentTime <= endTime;
};

/**
 * Calculate minutes since last reminder
 */
const getMinutesSinceLastReminder = (lastReminderTime) => {
  if (!lastReminderTime) return Infinity;
  
  const now = new Date();
  const last = new Date(lastReminderTime);
  return Math.floor((now - last) / (1000 * 60));
};

/**
 * Check if it's time for a meal reminder
 */
const isTimeForMeal = (mealTimes) => {
  const now = new Date();
  const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  
  // Check if current time matches any meal time (within 5 minutes)
  for (const mealTime of mealTimes) {
    const [mealHour, mealMinute] = mealTime.split(':').map(Number);
    const [currentHour, currentMinute] = currentTime.split(':').map(Number);
    
    if (mealHour === currentHour && Math.abs(mealMinute - currentMinute) <= 5) {
      return { isTime: true, mealTime };
    }
  }
  
  return { isTime: false };
};

/**
 * Send push notification
 */
const sendPushNotification = (title, body, priority = 'high') => {
  if ('Notification' in window && Notification.permission === 'granted') {
    const notification = new Notification(title, {
      body: body,
      icon: '/icon-192.png',
      badge: '/icon-192.png',
      tag: 'dementia-reminder',
      requireInteraction: priority === 'high',
      vibrate: [200, 100, 200, 100, 200],
      silent: false
    });

    // Play sound
    try {
      const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OWiUhMHU6vn77RgGgU7k9n0yX4qBSl+zPLaizsIHGy+8eimUBEKTqfi8bllHAU2jdXzzn0pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGgU5k9jyzn4pBSh7yvHajDwJHW/A8uynTxAKUKjl8bZjGg==');
      audio.play().catch(() => {});
    } catch (e) {}

    notification.onclick = () => {
      window.focus();
      notification.close();
    };
  }
};

/**
 * Create in-app notification
 */
const createNotification = async (title, message, type, actionUrl = null) => {
  try {
    await base44.entities.Notification.create({
      title,
      message,
      type,
      priority: 'high',
      action_url: actionUrl
    });
  } catch (error) {
    console.error("Failed to create notification:", error);
  }
};

export default function DementiaReminderService() {
  useEffect(() => {
    // Request notification permission
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }

    // Initial check
    checkReminders();

    // Check every minute
    const interval = setInterval(checkReminders, 60 * 1000);

    return () => clearInterval(interval);
  }, []);

  const checkReminders = async () => {
    try {
      const user = await base44.auth.me();
      
      if (!user.dementia_support_enabled) return;

      // Check hydration reminders
      if (user.hydration_reminders_enabled) {
        await checkHydrationReminder(user);
      }

      // Check meal reminders
      if (user.meal_reminders_enabled) {
        await checkMealReminder(user);
      }
    } catch (error) {
      console.error("Error checking reminders:", error);
    }
  };

  const checkHydrationReminder = async (user) => {
    // Check if within active hours
    if (!isWithinActiveHours(user.hydration_start_time, user.hydration_end_time)) {
      return;
    }

    // Check if interval has passed
    const minutesSinceLastReminder = getMinutesSinceLastReminder(user.last_hydration_reminder);
    const interval = user.hydration_interval_minutes || 120;

    if (minutesSinceLastReminder >= interval) {
      // Send reminder
      const title = "💧 Zeit zu trinken!";
      const message = "Bitte trinken Sie jetzt ein Glas Wasser oder ein anderes Getränk.";
      
      sendPushNotification(title, message, 'high');
      
      await createNotification(
        title,
        message,
        'info',
        '/Demenz-Unterstützung'
      );

      // Update last reminder time
      await base44.auth.updateMe({
        last_hydration_reminder: new Date().toISOString()
      });

      console.log("Hydration reminder sent");
    }
  };

  const checkMealReminder = async (user) => {
    const mealTimes = user.meal_times || ["08:00", "13:00", "19:00"];
    const { isTime, mealTime } = isTimeForMeal(mealTimes);

    if (isTime) {
      // Check if we already sent a reminder for this meal time today
      const lastMealReminder = await base44.entities.Notification.filter({
        type: 'info',
        created_date: {
          $gte: new Date().toISOString().split('T')[0] // Today
        },
        message: { $regex: 'Mahlzeit' }
      });

      // If we already sent a meal reminder within the last 30 minutes, skip
      if (lastMealReminder.length > 0) {
        const lastReminder = lastMealReminder[lastMealReminder.length - 1];
        const minutesSince = getMinutesSinceLastReminder(lastReminder.created_date);
        if (minutesSince < 30) return;
      }

      // Determine meal type
      const hour = parseInt(mealTime.split(':')[0]);
      let mealType = "Mahlzeit";
      if (hour >= 6 && hour < 11) mealType = "Frühstück";
      else if (hour >= 11 && hour < 16) mealType = "Mittagessen";
      else if (hour >= 16 && hour < 22) mealType = "Abendessen";

      const title = `🍽️ Zeit für ${mealType}!`;
      const message = `Es ist ${mealTime} Uhr. Bitte nehmen Sie jetzt Ihre Mahlzeit ein.`;
      
      sendPushNotification(title, message, 'high');
      
      await createNotification(
        title,
        message,
        'info',
        '/Demenz-Unterstützung'
      );

      console.log(`Meal reminder sent for ${mealType}`);
    }
  };

  // This component doesn't render anything
  return null;
}