/**
 * Twilio Send Message - Backend Function
 * Sends SMS and WhatsApp messages via Twilio API
 */

import { createClientFromRequest } from 'npm:@base44/sdk@0.8.4';

Deno.serve(async (req) => {
  try {
    // Parse request body
    const { to, message, type = 'sms' } = await req.json();

    // Validate input
    if (!to || !message) {
      return Response.json({ 
        success: false, 
        error: 'Missing required fields: to, message' 
      }, { status: 400 });
    }

    // Get Twilio credentials from environment
    const accountSid = Deno.env.get('TWILIO_ACCOUNT_SID');
    const authToken = Deno.env.get('TWILIO_AUTH_TOKEN');
    const fromNumber = type === 'whatsapp' 
      ? Deno.env.get('TWILIO_WHATSAPP_NUMBER')
      : Deno.env.get('TWILIO_PHONE_NUMBER');

    // Validate secrets
    if (!accountSid || !authToken || !fromNumber) {
      return Response.json({ 
        success: false, 
        error: 'Twilio credentials not configured. Please set up secrets in Dashboard.' 
      }, { status: 500 });
    }

    // Initialize Base44 client for authentication
    const base44 = createClientFromRequest(req);
    
    // Verify user is authenticated
    const user = await base44.auth.me();
    if (!user) {
      return Response.json({ 
        success: false, 
        error: 'Unauthorized' 
      }, { status: 401 });
    }

    // Format numbers for WhatsApp
    const toNumber = type === 'whatsapp' && !to.startsWith('whatsapp:') ? `whatsapp:${to}` : to;
    const fromNumberFormatted = type === 'whatsapp' && !fromNumber.startsWith('whatsapp:') 
      ? `whatsapp:${fromNumber}` 
      : fromNumber;

    // Create Twilio API URL
    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;

    // Prepare form data
    const formData = new URLSearchParams({
      To: toNumber,
      From: fromNumberFormatted,
      Body: message
    });

    // Send request to Twilio API
    const twilioResponse = await fetch(twilioUrl, {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa(`${accountSid}:${authToken}`),
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData
    });

    const twilioData = await twilioResponse.json();

    // Handle Twilio errors
    if (!twilioResponse.ok) {
      console.error('Twilio API error:', twilioData);
      
      let errorMessage = twilioData.message || 'Failed to send message';
      
      // Handle specific error codes
      if (twilioData.code === 21211) {
        errorMessage = 'Invalid phone number format';
      } else if (twilioData.code === 21608) {
        errorMessage = 'Phone number is not opted-in for WhatsApp';
      } else if (twilioData.code === 20003) {
        errorMessage = 'Authentication failed - check Twilio credentials';
      }

      return Response.json({
        success: false,
        error: errorMessage,
        code: twilioData.code
      }, { status: twilioResponse.status });
    }

    // Log success
    console.log(`${type.toUpperCase()} sent successfully:`, {
      messageSid: twilioData.sid,
      to: toNumber,
      status: twilioData.status
    });

    return Response.json({
      success: true,
      messageSid: twilioData.sid,
      status: twilioData.status,
      type: type
    });

  } catch (error) {
    console.error('Twilio function error:', error);

    return Response.json({
      success: false,
      error: error.message || 'Internal server error'
    }, { status: 500 });
  }
});