/**
 * Telegram Service Component
 * Handles Telegram notifications via Backend Functions
 */

import { base44 } from "@/api/base44Client";

/**
 * Send message via Telegram Bot (via Backend Function)
 */
export const sendTelegramMessage = async (chatId, message, options = {}) => {
  try {
    if (!chatId) {
      console.warn('No Telegram Chat ID provided');
      return { success: false, error: 'No Chat ID' };
    }

    // Call Backend Function
    const result = await base44.functions.sendEmergencyTelegram({
      chatId: chatId,
      message: message,
      location: options.location || null,
      buttons: options.buttons || null
    });

    console.log('Telegram result:', result);

    return result;

  } catch (error) {
    console.error('Telegram sending error:', error);
    return {
      success: false,
      error: error.message || 'Failed to send Telegram message'
    };
  }
};

/**
 * Send emergency alert via Telegram with all features
 */
export const sendEmergencyTelegram = async (contact, message, location = null) => {
  try {
    if (!contact.telegram_chat_id) {
      return { success: false, error: 'No Telegram Chat ID' };
    }

    const telegramMessage = `🚨 *NOTFALL-ALARM* 🚨\n\n${message}`;

    const buttons = [
      [
        { text: "🚑 Ich bin unterwegs!", callback_data: "emergency_responding" },
        { text: "📞 112 gerufen", callback_data: "emergency_called_112" }
      ]
    ];

    const result = await sendTelegramMessage(
      contact.telegram_chat_id,
      telegramMessage,
      { location, buttons }
    );

    return result;

  } catch (error) {
    console.error('Emergency Telegram error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send batch emergency alerts via Telegram
 */
export const sendEmergencyTelegramBatch = async (contacts, message, location = null) => {
  const results = [];
  let sent = 0;
  let failed = 0;

  const promises = contacts.map(async (contact) => {
    if (!contact.notify_via_telegram || !contact.telegram_chat_id) {
      return null;
    }

    try {
      const result = await sendEmergencyTelegram(contact, message, location);
      
      if (result.success) {
        sent++;
        results.push({
          contact: contact.name,
          chatId: contact.telegram_chat_id,
          success: true,
          messageId: result.messageId
        });
      } else {
        failed++;
        results.push({
          contact: contact.name,
          chatId: contact.telegram_chat_id,
          success: false,
          error: result.error,
          simulated: result.simulated || false
        });
      }
    } catch (error) {
      failed++;
      results.push({
        contact: contact.name,
        chatId: contact.telegram_chat_id,
        success: false,
        error: error.message
      });
    }
  });

  await Promise.all(promises.filter(p => p !== null));

  return { sent, failed, results };
};

export default {
  sendTelegramMessage,
  sendEmergencyTelegram,
  sendEmergencyTelegramBatch
};