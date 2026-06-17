import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  MessageSquare,
  Phone,
  CheckCircle,
  AlertCircle,
  ExternalLink,
  Copy,
  Send,
  Loader2
} from "lucide-react";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";
import { formatPhoneE164 } from "@/components/TwilioService";

export default function TwilioSetupPage() {
  const [testPhone, setTestPhone] = useState('');
  const [testMessage, setTestMessage] = useState('Test-Nachricht von Gesundheit Plus! 🚑');
  const [isSendingSMS, setIsSendingSMS] = useState(false);
  const [isSendingWhatsApp, setIsSendingWhatsApp] = useState(false);
  const [smsResult, setSmsResult] = useState(null);
  const [whatsappResult, setWhatsappResult] = useState(null);
  const [debugInfo, setDebugInfo] = useState(null);

  const handleTestSMS = async () => {
    if (!testPhone) {
      toast.error('Bitte Telefonnummer eingeben');
      return;
    }

    setIsSendingSMS(true);
    setSmsResult(null);
    setDebugInfo(null);

    try {
      const formattedPhone = formatPhoneE164(testPhone, '49');
      
      setDebugInfo({
        originalPhone: testPhone,
        formattedPhone: formattedPhone,
        message: testMessage,
        type: 'sms'
      });

      const response = await base44.functions.invoke('twilio-send-message', {
        to: formattedPhone,
        message: testMessage,
        type: 'sms'
      });

      setSmsResult({
        success: response.data.success,
        messageSid: response.data.messageSid,
        error: response.data.error,
        fullResponse: response.data
      });

      if (response.data.success) {
        toast.success('✅ SMS erfolgreich gesendet!');
      } else {
        toast.error(`❌ SMS-Fehler: ${response.data.error}`);
      }

    } catch (error) {
      console.error('SMS Test Error:', error);
      setSmsResult({
        success: false,
        error: error.message,
        errorDetails: error.response?.data || error
      });
      toast.error(`❌ Fehler: ${error.message}`);
    } finally {
      setIsSendingSMS(false);
    }
  };

  const handleTestWhatsApp = async () => {
    if (!testPhone) {
      toast.error('Bitte Telefonnummer eingeben');
      return;
    }

    setIsSendingWhatsApp(true);
    setWhatsappResult(null);
    setDebugInfo(null);

    try {
      const formattedPhone = formatPhoneE164(testPhone, '49');
      
      setDebugInfo({
        originalPhone: testPhone,
        formattedPhone: formattedPhone,
        message: testMessage,
        type: 'whatsapp'
      });

      const response = await base44.functions.invoke('twilio-send-message', {
        to: formattedPhone,
        message: testMessage,
        type: 'whatsapp'
      });

      setWhatsappResult({
        success: response.data.success,
        messageSid: response.data.messageSid,
        error: response.data.error,
        fullResponse: response.data
      });

      if (response.data.success) {
        toast.success('✅ WhatsApp erfolgreich gesendet!');
      } else {
        toast.error(`❌ WhatsApp-Fehler: ${response.data.error}`);
      }

    } catch (error) {
      console.error('WhatsApp Test Error:', error);
      setWhatsappResult({
        success: false,
        error: error.message,
        errorDetails: error.response?.data || error
      });
      toast.error(`❌ Fehler: ${error.message}`);
    } finally {
      setIsSendingWhatsApp(false);
    }
  };

  return (
    <div className="p-6 space-y-6 pb-24">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Twilio Integration - Debug Mode
        </h1>
        <p className="text-gray-600">
          Setup & Test mit detaillierter Fehleranalyse
        </p>
      </div>

      <Card className="border-2 border-blue-200 bg-blue-50">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <AlertCircle className="h-5 w-5 text-blue-600" />
            Setup erforderlich
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="bg-white rounded-lg p-4 space-y-3">
            <h3 className="font-semibold text-gray-900">
              1. Twilio Account & Secrets
            </h3>
            <Button
              onClick={() => window.open('https://www.twilio.com/try-twilio', '_blank')}
              variant="outline"
              size="sm"
            >
              <ExternalLink className="h-4 w-4 mr-2" />
              Twilio Account erstellen
            </Button>
            <p className="text-sm text-gray-600 mb-2">
              In Dashboard → Settings → Secrets eintragen:
            </p>
            <div className="space-y-2">
              <SecretItem 
                name="TWILIO_ACCOUNT_SID"
                description="Account SID (beginnt mit AC...)"
              />
              <SecretItem 
                name="TWILIO_AUTH_TOKEN"
                description="Auth Token aus Twilio Console"
              />
              <SecretItem 
                name="TWILIO_PHONE_NUMBER"
                description="SMS-Nummer (E.164: +4915123456789)"
              />
              <SecretItem 
                name="TWILIO_WHATSAPP_NUMBER"
                description="WhatsApp-Nummer (E.164: +14155238886)"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Send className="h-5 w-5 text-green-600" />
            Integration testen
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label htmlFor="testPhone">Telefonnummer</Label>
            <Input
              id="testPhone"
              type="tel"
              placeholder="+491512345678 oder 01512345678"
              value={testPhone}
              onChange={(e) => setTestPhone(e.target.value)}
              className="mt-1"
            />
            <p className="text-xs text-gray-500 mt-1">
              Mit +49 oder ohne (wird automatisch formatiert)
            </p>
          </div>

          <div>
            <Label htmlFor="testMessage">Nachricht</Label>
            <Textarea
              id="testMessage"
              value={testMessage}
              onChange={(e) => setTestMessage(e.target.value)}
              rows={3}
              className="mt-1"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Button
              onClick={handleTestSMS}
              disabled={isSendingSMS || !testPhone}
              className="bg-blue-600 hover:bg-blue-700"
            >
              {isSendingSMS ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Sende...
                </>
              ) : (
                <>
                  <Phone className="h-4 w-4 mr-2" />
                  SMS senden
                </>
              )}
            </Button>

            <Button
              onClick={handleTestWhatsApp}
              disabled={isSendingWhatsApp || !testPhone}
              className="bg-green-600 hover:bg-green-700"
            >
              {isSendingWhatsApp ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Sende...
                </>
              ) : (
                <>
                  <MessageSquare className="h-4 w-4 mr-2" />
                  WhatsApp
                </>
              )}
            </Button>
          </div>

          {debugInfo && (
            <Card className="border-2 border-purple-200 bg-purple-50">
              <CardHeader>
                <CardTitle className="text-sm">🔍 Debug Info</CardTitle>
              </CardHeader>
              <CardContent>
                <pre className="text-xs bg-white p-3 rounded overflow-auto">
                  {JSON.stringify(debugInfo, null, 2)}
                </pre>
              </CardContent>
            </Card>
          )}

          {smsResult && (
            <div className={`rounded-lg p-4 ${smsResult.success ? 'bg-green-50 border-2 border-green-200' : 'bg-red-50 border-2 border-red-200'}`}>
              <div className="flex items-center gap-2 mb-2">
                {smsResult.success ? (
                  <>
                    <CheckCircle className="h-5 w-5 text-green-600" />
                    <p className="font-semibold text-green-900">SMS erfolgreich!</p>
                  </>
                ) : (
                  <>
                    <AlertCircle className="h-5 w-5 text-red-600" />
                    <p className="font-semibold text-red-900">SMS fehlgeschlagen</p>
                  </>
                )}
              </div>
              {smsResult.success ? (
                <p className="text-sm text-gray-600">
                  Message SID: <code className="bg-white px-2 py-1 rounded text-xs">{smsResult.messageSid}</code>
                </p>
              ) : (
                <div className="space-y-2">
                  <p className="text-sm text-red-700 font-semibold">{smsResult.error}</p>
                  {smsResult.errorDetails && (
                    <pre className="text-xs bg-white p-2 rounded overflow-auto text-gray-700">
                      {JSON.stringify(smsResult.errorDetails, null, 2)}
                    </pre>
                  )}
                </div>
              )}
            </div>
          )}

          {whatsappResult && (
            <div className={`rounded-lg p-4 ${whatsappResult.success ? 'bg-green-50 border-2 border-green-200' : 'bg-red-50 border-2 border-red-200'}`}>
              <div className="flex items-center gap-2 mb-2">
                {whatsappResult.success ? (
                  <>
                    <CheckCircle className="h-5 w-5 text-green-600" />
                    <p className="font-semibold text-green-900">WhatsApp erfolgreich!</p>
                  </>
                ) : (
                  <>
                    <AlertCircle className="h-5 w-5 text-red-600" />
                    <p className="font-semibold text-red-900">WhatsApp fehlgeschlagen</p>
                  </>
                )}
              </div>
              {whatsappResult.success ? (
                <p className="text-sm text-gray-600">
                  Message SID: <code className="bg-white px-2 py-1 rounded text-xs">{whatsappResult.messageSid}</code>
                </p>
              ) : (
                <div className="space-y-2">
                  <p className="text-sm text-red-700 font-semibold">{whatsappResult.error}</p>
                  {whatsappResult.errorDetails && (
                    <pre className="text-xs bg-white p-2 rounded overflow-auto text-gray-700">
                      {JSON.stringify(whatsappResult.errorDetails, null, 2)}
                    </pre>
                  )}
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      <Card className="border-2 border-yellow-200 bg-yellow-50">
        <CardHeader>
          <CardTitle>💡 Häufige Fehlerursachen</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="text-sm text-gray-700 space-y-2">
            <li><strong>❌ "Twilio credentials not configured"</strong><br/>
            → Secrets in Dashboard → Settings → Secrets eintragen</li>
            <li><strong>❌ "Invalid phone number format"</strong><br/>
            → Nummer muss E.164 Format haben (+491512345678)</li>
            <li><strong>❌ "Authentication failed"</strong><br/>
            → Account SID oder Auth Token falsch</li>
            <li><strong>❌ "Phone number not opted-in"</strong><br/>
            → Bei Trial-Account: Nummer in Twilio Console verifizieren</li>
            <li><strong>❌ Request failed with status 400</strong><br/>
            → Backend-Funktion nicht deployed oder Fehler im Request</li>
          </ul>
        </CardContent>
      </Card>
    </div>
  );
}

function SecretItem({ name, description }) {
  return (
    <div className="bg-gray-50 rounded p-3">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <code className="text-sm font-mono text-purple-700">{name}</code>
          <p className="text-xs text-gray-600 mt-1">{description}</p>
        </div>
        <Button
          size="sm"
          variant="ghost"
          onClick={() => {
            navigator.clipboard.writeText(name);
            toast.success('Kopiert!');
          }}
          className="flex-shrink-0"
        >
          <Copy className="h-3 w-3" />
        </Button>
      </div>
    </div>
  );
}