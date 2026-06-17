/**
 * Backend Function: Send Emergency SMS via Twilio
 * 
 * SETUP:
 * 1. Base44 Dashboard -> Settings -> Secrets
 * 2. Add:
 *    - TWILIO_ACCOUNT_SID
 *    - TWILIO_AUTH_TOKEN
 *    - TWILIO_PHONE_NUMBER
 */

export default async function sendEmergencySMS({ to, message }, { secrets }) {
  try {
    const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER } = secrets;

    if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_PHONE_NUMBER) {
      console.warn('Twilio credentials not configured');
      return {
        success: false,
        error: 'SMS service not configured',
        simulated: true
      };
    }

    // Twilio API Call
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

    if (response.status !== 201) {
      throw new Error(data.message || 'Twilio API error');
    }

    return {
      success: true,
      messageSid: data.sid,
      status: data.status,
      to: data.to
    };

  } catch (error) {
    console.error('SMS Error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}