/**
 * Backend Function: Send Emergency Telegram Message
 * 
 * SETUP:
 * 1. Create bot via @BotFather in Telegram
 * 2. Get Bot Token
 * 3. Base44 Dashboard -> Settings -> Secrets
 * 4. Add: TELEGRAM_BOT_TOKEN
 */

export default async function sendEmergencyTelegram({ chatId, message, location, buttons }, { secrets }) {
  try {
    const { TELEGRAM_BOT_TOKEN } = secrets;

    if (!TELEGRAM_BOT_TOKEN) {
      console.warn('Telegram bot token not configured');
      return {
        success: false,
        error: 'Telegram service not configured',
        simulated: true
      };
    }

    // Send text message
    const messageUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
    
    const payload = {
      chat_id: chatId,
      text: message,
      parse_mode: 'Markdown',
      disable_web_page_preview: false
    };

    // Add buttons if provided
    if (buttons && buttons.length > 0) {
      payload.reply_markup = {
        inline_keyboard: buttons
      };
    }

    const messageResponse = await fetch(messageUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const messageData = await messageResponse.json();
    
    if (!messageData.ok) {
      throw new Error(messageData.description || 'Telegram API error');
    }

    // Send location if provided
    if (location) {
      const locationUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendLocation`;
      
      await fetch(locationUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: chatId,
          latitude: location.latitude,
          longitude: location.longitude
        })
      });
    }

    return {
      success: true,
      messageId: messageData.result.message_id,
      chatId: messageData.result.chat.id
    };

  } catch (error) {
    console.error('Telegram Error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}