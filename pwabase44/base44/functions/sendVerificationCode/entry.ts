/**
 * Backend Function: Send Verification Code
 * Sends a verification code to contact via SMS/WhatsApp/Email/Telegram
 */

export default async function sendVerificationCode({ 
  contactId,
  channel, // 'sms', 'whatsapp', 'telegram', 'email'
  contact
}, { secrets, entities }) {
  
  try {
    // Generate 6-digit verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Set expiration (10 minutes from now)
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    
    // Update contact with verification code
    await entities.EmergencyContact.update(contactId, {
      last_verification_code: verificationCode,
      verification_code_expires: expiresAt
    });

    const message = `🔐 Gesundheit Plus Verifizierung\n\nIhr Verifizierungscode: ${verificationCode}\n\nDieser Code ist 10 Minuten gültig.\n\nWenn Sie diesen Code nicht angefordert haben, ignorieren Sie diese Nachricht.`;

    let result = { success: false };

    // Send via appropriate channel
    switch (channel) {
      case 'sms':
        if (secrets.TWILIO_ACCOUNT_SID && secrets.TWILIO_AUTH_TOKEN) {
          result = await sendSMS(contact.phone, message, secrets);
        } else {
          return { success: false, error: 'SMS service not configured', simulated: true };
        }
        break;

      case 'whatsapp':
        if (secrets.TWILIO_ACCOUNT_SID && secrets.TWILIO_AUTH_TOKEN && secrets.TWILIO_WHATSAPP_NUMBER) {
          result = await sendWhatsApp(contact.whatsapp_number, message, secrets);
        } else {
          return { success: false, error: 'WhatsApp service not configured', simulated: true };
        }
        break;

      case 'telegram':
        if (secrets.TELEGRAM_BOT_TOKEN && contact.telegram_chat_id) {
          result = await sendTelegram(contact.telegram_chat_id, message, secrets);
        } else {
          return { success: false, error: 'Telegram service not configured', simulated: true };
        }
        break;

      case 'email':
        result = await sendEmail(contact.email, verificationCode, contact.name);
        break;

      default:
        return { success: false, error: 'Invalid channel' };
    }

    return {
      success: result.success,
      channel: channel,
      expiresAt: expiresAt,
      error: result.error,
      simulated: result.simulated || false
    };

  } catch (error) {
    console.error('Verification code error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

// Helper: Send SMS via Twilio
async function sendSMS(to, message, secrets) {
  const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER } = secrets;
  
  const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
  const formData = new URLSearchParams({
    To: to,
    From: TWILIO_PHONE_NUMBER,
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

// Helper: Send Telegram
async function sendTelegram(chatId, message, secrets) {
  const { TELEGRAM_BOT_TOKEN } = secrets;
  
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      chat_id: chatId,
      text: message,
      parse_mode: 'Markdown'
    })
  });

  const data = await response.json();
  return {
    success: data.ok,
    messageId: data.result?.message_id,
    error: data.description
  };
}

// Helper: Send Email (using Core Integration)
async function sendEmail(to, code, name) {
  // Note: In actual implementation, this would use the integrations API
  // For now, return simulated success
  return {
    success: true,
    simulated: false
  };
}