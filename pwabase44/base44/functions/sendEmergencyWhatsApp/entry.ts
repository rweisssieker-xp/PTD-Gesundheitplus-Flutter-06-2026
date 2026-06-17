/**
 * Backend Function: Send Emergency WhatsApp via Twilio
 * 
 * SETUP:
 * 1. Get Twilio Account with WhatsApp enabled
 * 2. Base44 Dashboard -> Settings -> Secrets
 * 3. Add:
 *    - TWILIO_ACCOUNT_SID
 *    - TWILIO_AUTH_TOKEN
 *    - TWILIO_WHATSAPP_NUMBER (e.g., "whatsapp:+14155238886")
 */

export default async function sendEmergencyWhatsApp({ to, message }, { secrets }) {
  try {
    const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_NUMBER } = secrets;

    if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_WHATSAPP_NUMBER) {
      console.warn('Twilio WhatsApp credentials not configured');
      return {
        success: false,
        error: 'WhatsApp service not configured',
        simulated: true
      };
    }

    // Format WhatsApp number
    const whatsappTo = to.startsWith('whatsapp:') ? to : `whatsapp:${to}`;

    // Twilio WhatsApp API Call
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

    if (response.status !== 201) {
      throw new Error(data.message || 'Twilio WhatsApp API error');
    }

    return {
      success: true,
      messageSid: data.sid,
      status: data.status,
      to: data.to
    };

  } catch (error) {
    console.error('WhatsApp Error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}