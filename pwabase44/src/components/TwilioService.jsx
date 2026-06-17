/**
 * Twilio Integration Service
 */

import { base44 } from "@/api/base44Client";

export async function sendTwilioSMS(to, message) {
  try {
    if (!to || !to.startsWith('+')) {
      throw new Error('Phone must be E.164 format (e.g., +491234567890)');
    }

    if (!message) {
      throw new Error('Message cannot be empty');
    }

    if (message.length > 1600) {
      message = message.substring(0, 1597) + '...';
    }

    const { data } = await base44.functions.invoke('twilio-send-message', {
      to,
      message,
      type: 'sms'
    });

    return {
      success: data.success,
      messageSid: data.messageSid,
      error: data.error
    };

  } catch (error) {
    console.error('SMS error:', error);
    return {
      success: false,
      error: error.message || 'Failed to send SMS'
    };
  }
}

export async function sendTwilioWhatsApp(to, message) {
  try {
    if (!to || !to.startsWith('+')) {
      throw new Error('WhatsApp must be E.164 format');
    }

    if (!message) {
      throw new Error('Message cannot be empty');
    }

    const { data } = await base44.functions.invoke('twilio-send-message', {
      to,
      message,
      type: 'whatsapp'
    });

    return {
      success: data.success,
      messageSid: data.messageSid,
      error: data.error
    };

  } catch (error) {
    console.error('WhatsApp error:', error);
    return {
      success: false,
      error: error.message || 'Failed to send WhatsApp'
    };
  }
}

export async function sendEmergencySMSBatch(contacts, message, location = null) {
  let messageText = `🚨 NOTFALL\n\n${message}`;
  
  if (location) {
    messageText += `\n\n📍 https://maps.google.com/?q=${location.latitude},${location.longitude}`;
  }

  const results = await Promise.all(
    contacts
      .filter(c => c.notify_via_sms && c.phone)
      .map(async (contact) => {
        const result = await sendTwilioSMS(contact.phone, messageText);
        return {
          contact: contact.name,
          phone: contact.phone,
          ...result
        };
      })
  );

  return { 
    sent: results.filter(r => r.success).length, 
    failed: results.filter(r => !r.success).length, 
    results 
  };
}

export async function sendEmergencyWhatsAppBatch(contacts, message, location = null) {
  let messageText = `🚨 *NOTFALL*\n\n${message}`;
  
  if (location) {
    messageText += `\n\n📍 https://maps.google.com/?q=${location.latitude},${location.longitude}`;
  }

  const results = await Promise.all(
    contacts
      .filter(c => c.notify_via_whatsapp && c.whatsapp_number)
      .map(async (contact) => {
        const result = await sendTwilioWhatsApp(contact.whatsapp_number, messageText);
        return {
          contact: contact.name,
          whatsapp: contact.whatsapp_number,
          ...result
        };
      })
  );

  return { 
    sent: results.filter(r => r.success).length, 
    failed: results.filter(r => !r.success).length, 
    results 
  };
}

export function formatPhoneE164(phone, defaultCountryCode = '49') {
  if (!phone) return null;
  
  let cleaned = phone.replace(/[^\d+]/g, '');
  
  if (cleaned.startsWith('+')) {
    return cleaned;
  }
  
  if (cleaned.startsWith('0')) {
    cleaned = cleaned.substring(1);
  }
  
  return `+${defaultCountryCode}${cleaned}`;
}

export default {
  sendTwilioSMS,
  sendTwilioWhatsApp,
  sendEmergencySMSBatch,
  sendEmergencyWhatsAppBatch,
  formatPhoneE164
};