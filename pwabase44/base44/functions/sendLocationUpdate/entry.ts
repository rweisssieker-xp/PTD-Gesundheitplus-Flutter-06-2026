/**
 * Backend Function: Send Real-time Location Update
 * Continuously updates emergency contacts with user's GPS location
 */

export default async function sendLocationUpdate({ 
  contacts, 
  location, 
  trackingId,
  userName,
  message 
}, { secrets }) {
  
  const results = {
    sms: { sent: 0, failed: 0 },
    telegram: { sent: 0, failed: 0 },
    whatsapp: { sent: 0, failed: 0 }
  };

  const timestamp = new Date().toLocaleString('de-DE');
  const mapsUrl = `https://maps.google.com/?q=${location.latitude},${location.longitude}`;
  const accuracy = Math.round(location.accuracy || 0);

  // Prepare messages
  const shortMessage = `📍 LIVE-STANDORT UPDATE\n${userName}\n${timestamp}\n\nKoordinaten: ${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}\nGenauigkeit: ±${accuracy}m\n\n${mapsUrl}\n\n${message || 'Tracking aktiv...'}`;

  const telegramMessage = `📍 *LIVE-STANDORT UPDATE*\n\n👤 ${userName}\n⏰ ${timestamp}\n📏 Genauigkeit: ±${accuracy}m\n\n${message || '_Tracking aktiv..._'}\n\n🔗 [Google Maps öffnen](${mapsUrl})`;

  // Send to all contacts in parallel
  const promises = contacts.map(async (contact) => {
    const contactResults = [];

    // SMS
    if (contact.notify_via_sms && contact.phone && secrets.TWILIO_ACCOUNT_SID) {
      try {
        const smsResult = await sendSMS(contact.phone, shortMessage, secrets);
        if (smsResult.success) results.sms.sent++;
        else results.sms.failed++;
        contactResults.push({ channel: 'sms', ...smsResult });
      } catch (error) {
        results.sms.failed++;
        contactResults.push({ channel: 'sms', success: false, error: error.message });
      }
    }

    // Telegram (with live location)
    if (contact.notify_via_telegram && contact.telegram_chat_id && secrets.TELEGRAM_BOT_TOKEN) {
      try {
        const telegramResult = await sendTelegramLocation(
          contact.telegram_chat_id,
          location,
          telegramMessage,
          secrets
        );
        if (telegramResult.success) results.telegram.sent++;
        else results.telegram.failed++;
        contactResults.push({ channel: 'telegram', ...telegramResult });
      } catch (error) {
        results.telegram.failed++;
        contactResults.push({ channel: 'telegram', success: false, error: error.message });
      }
    }

    // WhatsApp
    if (contact.notify_via_whatsapp && contact.whatsapp_number && secrets.TWILIO_ACCOUNT_SID) {
      try {
        const whatsappResult = await sendWhatsApp(contact.whatsapp_number, shortMessage, secrets);
        if (whatsappResult.success) results.whatsapp.sent++;
        else results.whatsapp.failed++;
        contactResults.push({ channel: 'whatsapp', ...whatsappResult });
      } catch (error) {
        results.whatsapp.failed++;
        contactResults.push({ channel: 'whatsapp', success: false, error: error.message });
      }
    }

    return contactResults;
  });

  await Promise.all(promises);

  return {
    success: true,
    trackingId,
    location,
    timestamp,
    results
  };
}

// Helper: Send SMS via Twilio
async function sendSMS(to, message, secrets) {
  const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER } = secrets;
  
  const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
  const formData = new URLSearchParams({
    To: to,
    From: TWILIO_PHONE_NUMBER,
    Body: message.substring(0, 1600)
  });

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64'),
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: formData.toString()
  });

  const data = await response.json();
  return {
    success: response.status === 201,
    messageSid: data.sid,
    error: data.message
  };
}

// Helper: Send Telegram with live location
async function sendTelegramLocation(chatId, location, message, secrets) {
  const { TELEGRAM_BOT_TOKEN } = secrets;
  
  // Send live location (editable for 15 minutes)
  const locationUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendLocation`;
  
  const locationResponse = await fetch(locationUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      chat_id: chatId,
      latitude: location.latitude,
      longitude: location.longitude,
      live_period: 900, // 15 minutes live tracking
      horizontal_accuracy: location.accuracy
    })
  });

  const locationData = await locationResponse.json();
  
  if (!locationData.ok) {
    throw new Error(locationData.description || 'Telegram location error');
  }

  // Send text message
  const messageUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  await fetch(messageUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      chat_id: chatId,
      text: message,
      parse_mode: 'Markdown'
    })
  });

  return {
    success: true,
    messageId: locationData.result.message_id
  };
}

// Helper: Send WhatsApp via Twilio
async function sendWhatsApp(to, message, secrets) {
  const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_NUMBER } = secrets;
  
  const whatsappTo = to.startsWith('whatsapp:') ? to : `whatsapp:${to}`;
  const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
  
  const formData = new URLSearchParams({
    To: whatsappTo,
    From: TWILIO_WHATSAPP_NUMBER,
    Body: message
  });

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64'),
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: formData.toString()
  });

  const data = await response.json();
  return {
    success: response.status === 201,
    messageSid: data.sid,
    error: data.message
  };
}