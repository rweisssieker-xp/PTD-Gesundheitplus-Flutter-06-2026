/**
 * WhatsApp Service Component - Now using Twilio
 * Handles WhatsApp notifications via Twilio Integration
 */

import { sendTwilioWhatsApp, formatPhoneE164 } from "./TwilioService";

/**
 * Send WhatsApp message via Twilio
 */
export const sendWhatsAppMessage = async (to, message) => {
  return await sendTwilioWhatsApp(to, message);
};

/**
 * Send emergency alert via WhatsApp
 */
export const sendEmergencyWhatsApp = async (contact, message, location = null) => {
  try {
    if (!contact.whatsapp_number) {
      return { success: false, error: 'No WhatsApp number' };
    }

    let whatsappMessage = `🚨 *NOTFALL-ALARM* 🚨\n\n${message}`;
    
    if (location) {
      const mapsUrl = `https://maps.google.com/?q=${location.latitude},${location.longitude}`;
      whatsappMessage += `\n\n📍 *Standort:*\n${mapsUrl}`;
    }

    whatsappMessage += `\n\n_Gesundheit Plus Emergency Guardian_`;

    const result = await sendTwilioWhatsApp(
      contact.whatsapp_number,
      whatsappMessage
    );

    return result;

  } catch (error) {
    console.error('Emergency WhatsApp error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Send batch emergency alerts via WhatsApp
 */
export const sendEmergencyWhatsAppBatch = async (contacts, message, location = null) => {
  const results = [];
  let sent = 0;
  let failed = 0;

  const promises = contacts.map(async (contact) => {
    if (!contact.notify_via_whatsapp || !contact.whatsapp_number) {
      return null;
    }

    try {
      const result = await sendEmergencyWhatsApp(contact, message, location);
      
      if (result.success) {
        sent++;
        results.push({
          contact: contact.name,
          number: contact.whatsapp_number,
          success: true,
          messageSid: result.messageSid
        });
      } else {
        failed++;
        results.push({
          contact: contact.name,
          number: contact.whatsapp_number,
          success: false,
          error: result.error
        });
      }
    } catch (error) {
      failed++;
      results.push({
        contact: contact.name,
        number: contact.whatsapp_number,
        success: false,
        error: error.message
      });
    }
  });

  await Promise.all(promises.filter(p => p !== null));

  return { sent, failed, results };
};

/**
 * Format phone number for WhatsApp (E.164)
 */
export const formatWhatsAppNumber = (phone, defaultCountryCode = '49') => {
  return formatPhoneE164(phone, defaultCountryCode);
};

export default {
  sendWhatsAppMessage,
  sendEmergencyWhatsApp,
  sendEmergencyWhatsAppBatch,
  formatWhatsAppNumber
};