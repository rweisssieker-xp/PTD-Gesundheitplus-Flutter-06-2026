/**
 * SMS Service Component - Now using Twilio
 * Handles SMS notifications via Twilio Integration
 */

import { sendTwilioSMS, formatPhoneE164 } from "./TwilioService";

/**
 * Sends SMS to a phone number via Twilio
 */
export const sendSMS = async (to, message) => {
  return await sendTwilioSMS(to, message);
};

/**
 * Sends emergency SMS to multiple contacts
 */
export const sendEmergencySMSBatch = async (contacts, message) => {
  const results = [];
  let sent = 0;
  let failed = 0;

  const emergencyMessage = `🚨 NOTFALL-ALARM 🚨\n\n${message}\n\n---\nGesundheit Plus Emergency Guardian`;

  const promises = contacts.map(async (contact) => {
    if (!contact.notify_via_sms || !contact.phone) {
      return null;
    }

    try {
      const result = await sendTwilioSMS(contact.phone, emergencyMessage);
      
      if (result.success) {
        sent++;
        results.push({
          contact: contact.name,
          phone: contact.phone,
          success: true,
          messageId: result.messageSid
        });
      } else {
        failed++;
        results.push({
          contact: contact.name,
          phone: contact.phone,
          success: false,
          error: result.error
        });
      }
    } catch (error) {
      failed++;
      results.push({
        contact: contact.name,
        phone: contact.phone,
        success: false,
        error: error.message
      });
    }
  });

  await Promise.all(promises.filter(p => p !== null));

  return { sent, failed, results };
};

/**
 * Validates phone number format (E.164)
 */
export const isValidPhoneNumber = (phone) => {
  if (!phone) return false;
  const e164Regex = /^\+[1-9]\d{1,14}$/;
  return e164Regex.test(phone);
};

/**
 * Formats phone number to E.164 format
 */
export const formatPhoneNumber = (phone, defaultCountryCode = '49') => {
  return formatPhoneE164(phone, defaultCountryCode);
};

export default {
  sendSMS,
  sendEmergencySMSBatch,
  isValidPhoneNumber,
  formatPhoneNumber
};