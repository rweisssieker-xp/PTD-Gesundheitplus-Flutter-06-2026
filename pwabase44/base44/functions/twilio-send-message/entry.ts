import { createClientFromRequest } from 'npm:@base44/sdk@0.8.4';

Deno.serve(async (req) => {
  try {
    const base44 = createClientFromRequest(req);
    
    const user = await base44.auth.me();
    if (!user) {
      return Response.json({ success: false, error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const { to, message, type = 'sms' } = body;

    if (!to || !message) {
      return Response.json({ 
        success: false, 
        error: 'Missing required fields: to, message' 
      }, { status: 400 });
    }

    const accountSid = Deno.env.get('TWILIO_ACCOUNT_SID');
    const authToken = Deno.env.get('TWILIO_AUTH_TOKEN');
    const fromNumber = type === 'whatsapp' 
      ? Deno.env.get('TWILIO_WHATSAPP_NUMBER')
      : Deno.env.get('TWILIO_PHONE_NUMBER');

    if (!accountSid || !authToken || !fromNumber) {
      return Response.json({ 
        success: false, 
        error: 'Twilio credentials not configured' 
      }, { status: 400 });
    }

    const toNumber = type === 'whatsapp' && !to.startsWith('whatsapp:') ? `whatsapp:${to}` : to;
    const fromNumberFormatted = type === 'whatsapp' && !fromNumber.startsWith('whatsapp:') 
      ? `whatsapp:${fromNumber}` 
      : fromNumber;

    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;

    const formData = new URLSearchParams({
      To: toNumber,
      From: fromNumberFormatted,
      Body: message
    });

    const twilioResponse = await fetch(twilioUrl, {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa(`${accountSid}:${authToken}`),
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData
    });

    const twilioData = await twilioResponse.json();

    if (!twilioResponse.ok) {
      console.error('Twilio error:', twilioData);
      return Response.json({
        success: false,
        error: twilioData.message || 'Twilio API error',
        code: twilioData.code
      }, { status: 400 });
    }

    return Response.json({
      success: true,
      messageSid: twilioData.sid,
      status: twilioData.status
    });

  } catch (error) {
    console.error('Function error:', error);
    return Response.json({
      success: false,
      error: error.message
    }, { status: 500 });
  }
});