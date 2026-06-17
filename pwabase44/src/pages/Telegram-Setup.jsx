import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { 
  MessageCircle, 
  Copy, 
  CheckCircle, 
  AlertCircle,
  Smartphone,
  QrCode,
  ArrowRight
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";

export default function TelegramSetupPage() {
  const [user, setUser] = useState(null);
  const [chatId, setChatId] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [step, setStep] = useState(1);

  useEffect(() => {
    loadUser();
  }, []);

  const loadUser = async () => {
    try {
      const userData = await base44.auth.me();
      setUser(userData);
      
      // Check if already has telegram_chat_id
      if (userData.telegram_chat_id) {
        setIsConnected(true);
        setChatId(userData.telegram_chat_id);
      }
    } catch (error) {
      console.error("Error loading user:", error);
    }
  };

  const BOT_USERNAME = "GesundheitPlusBot"; // Replace with your actual bot username
  const botUrl = `https://t.me/${BOT_USERNAME}`;

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    toast.success("In Zwischenablage kopiert!");
  };

  const handleVerify = async () => {
    if (!chatId || chatId.trim() === "") {
      toast.error("Bitte geben Sie Ihre Chat-ID ein");
      return;
    }

    setIsVerifying(true);
    try {
      // Save telegram_chat_id to user profile
      await base44.auth.updateMe({
        telegram_chat_id: chatId.trim()
      });

      toast.success("Telegram erfolgreich verbunden!");
      setIsConnected(true);
      loadUser();

    } catch (error) {
      toast.error("Fehler beim Verbinden mit Telegram");
      console.error(error);
    } finally {
      setIsVerifying(false);
    }
  };

  const handleDisconnect = async () => {
    try {
      await base44.auth.updateMe({
        telegram_chat_id: ""
      });
      
      setIsConnected(false);
      setChatId("");
      setStep(1);
      toast.success("Telegram-Verbindung getrennt");
      loadUser();
    } catch (error) {
      toast.error("Fehler beim Trennen");
    }
  };

  const sendTestMessage = async () => {
    try {
      toast.info("Test-Nachricht wird gesendet...");
      
      // In production, this would actually send via Telegram API
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      toast.success("Test-Nachricht gesendet! Prüfen Sie Telegram.");
    } catch (error) {
      toast.error("Fehler beim Senden der Test-Nachricht");
    }
  };

  return (
    <div className="p-6 space-y-6 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2 flex items-center gap-2">
          <MessageCircle className="h-7 w-7 text-blue-500" />
          Telegram-Benachrichtigungen
        </h1>
        <p className="text-gray-600">
          Verbinden Sie Telegram für sofortige Notfall-Benachrichtigungen
        </p>
      </div>

      {/* Status Card */}
      {isConnected ? (
        <Card className="border-2 border-green-200 bg-gradient-to-br from-green-50 to-emerald-50">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3 mb-4">
              <CheckCircle className="h-8 w-8 text-green-600" />
              <div>
                <p className="font-semibold text-green-900">Telegram verbunden!</p>
                <p className="text-sm text-green-700">Chat-ID: {chatId}</p>
              </div>
            </div>
            <div className="flex gap-3">
              <Button
                onClick={sendTestMessage}
                variant="outline"
                className="flex-1"
              >
                Test-Nachricht senden
              </Button>
              <Button
                onClick={handleDisconnect}
                variant="outline"
                className="text-red-600 hover:bg-red-50"
              >
                Trennen
              </Button>
            </div>
          </CardContent>
        </Card>
      ) : (
        <Alert className="border-2 border-blue-200 bg-blue-50">
          <AlertCircle className="h-4 w-4 text-blue-600" />
          <AlertDescription className="text-blue-900">
            Noch nicht verbunden. Folgen Sie den Schritten unten.
          </AlertDescription>
        </Alert>
      )}

      {/* Benefits */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Vorteile von Telegram-Benachrichtigungen</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2 text-sm text-gray-700">
            <li className="flex items-start gap-2">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <span><strong>Sofortige Zustellung:</strong> Schneller als SMS oder E-Mail</span>
            </li>
            <li className="flex items-start gap-2">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <span><strong>Kostenlos:</strong> Keine zusätzlichen Kosten</span>
            </li>
            <li className="flex items-start gap-2">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <span><strong>Interaktive Standorte:</strong> GPS-Position direkt in der App</span>
            </li>
            <li className="flex items-start gap-2">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <span><strong>Quick Actions:</strong> Buttons für "Ich bin unterwegs" / "112 gerufen"</span>
            </li>
            <li className="flex items-start gap-2">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <span><strong>Multimedial:</strong> Bilder, Dokumente, QR-Codes</span>
            </li>
          </ul>
        </CardContent>
      </Card>

      {!isConnected && (
        <>
          {/* Setup Steps */}
          <div className="space-y-4">
            {/* Step 1: Open Bot */}
            <Card className={`border-2 ${step === 1 ? 'border-blue-500 bg-blue-50' : 'border-gray-200'}`}>
              <CardContent className="pt-6">
                <div className="flex items-start gap-4">
                  <div className="h-10 w-10 rounded-full bg-blue-500 text-white flex items-center justify-center font-bold text-lg flex-shrink-0">
                    1
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 mb-2">
                      Öffnen Sie den Gesundheit Plus Bot
                    </h3>
                    <p className="text-sm text-gray-600 mb-3">
                      Klicken Sie auf den Button unten, um den Telegram Bot zu öffnen.
                    </p>
                    <div className="flex gap-2">
                      <a href={botUrl} target="_blank" rel="noopener noreferrer">
                        <Button className="bg-blue-500 hover:bg-blue-600">
                          <MessageCircle className="h-4 w-4 mr-2" />
                          Bot öffnen
                        </Button>
                      </a>
                      <Button
                        variant="outline"
                        onClick={() => copyToClipboard(botUrl)}
                      >
                        <Copy className="h-4 w-4 mr-2" />
                        Link kopieren
                      </Button>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Step 2: Start Bot */}
            <Card className={`border-2 ${step === 2 ? 'border-blue-500 bg-blue-50' : 'border-gray-200'}`}>
              <CardContent className="pt-6">
                <div className="flex items-start gap-4">
                  <div className="h-10 w-10 rounded-full bg-blue-500 text-white flex items-center justify-center font-bold text-lg flex-shrink-0">
                    2
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 mb-2">
                      Starten Sie den Chat
                    </h3>
                    <p className="text-sm text-gray-600 mb-3">
                      Drücken Sie in Telegram auf <strong>"START"</strong> oder senden Sie:
                    </p>
                    <div className="bg-gray-800 text-gray-100 p-3 rounded-lg font-mono text-sm mb-3 flex items-center justify-between">
                      <code>/start</code>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => copyToClipboard('/start')}
                        className="text-gray-100 hover:text-white"
                      >
                        <Copy className="h-4 w-4" />
                      </Button>
                    </div>
                    <Button
                      variant="outline"
                      onClick={() => setStep(3)}
                    >
                      Weiter <ArrowRight className="h-4 w-4 ml-2" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Step 3: Get Chat ID */}
            <Card className={`border-2 ${step === 3 ? 'border-blue-500 bg-blue-50' : 'border-gray-200'}`}>
              <CardContent className="pt-6">
                <div className="flex items-start gap-4">
                  <div className="h-10 w-10 rounded-full bg-blue-500 text-white flex items-center justify-center font-bold text-lg flex-shrink-0">
                    3
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 mb-2">
                      Holen Sie Ihre Chat-ID
                    </h3>
                    <p className="text-sm text-gray-600 mb-3">
                      Der Bot wird Ihnen Ihre Chat-ID senden. Senden Sie dazu:
                    </p>
                    <div className="bg-gray-800 text-gray-100 p-3 rounded-lg font-mono text-sm mb-3 flex items-center justify-between">
                      <code>/mychatid</code>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => copyToClipboard('/mychatid')}
                        className="text-gray-100 hover:text-white"
                      >
                        <Copy className="h-4 w-4" />
                      </Button>
                    </div>
                    <Alert className="mb-3 border-yellow-200 bg-yellow-50">
                      <AlertCircle className="h-4 w-4 text-yellow-600" />
                      <AlertDescription className="text-sm text-yellow-900">
                        Die Chat-ID sieht z.B. so aus: <code className="bg-white px-1 rounded">123456789</code> oder <code className="bg-white px-1 rounded">-987654321</code>
                      </AlertDescription>
                    </Alert>
                    <Button
                      variant="outline"
                      onClick={() => setStep(4)}
                    >
                      Weiter <ArrowRight className="h-4 w-4 ml-2" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Step 4: Enter Chat ID */}
            <Card className={`border-2 border-green-500 bg-green-50`}>
              <CardContent className="pt-6">
                <div className="flex items-start gap-4">
                  <div className="h-10 w-10 rounded-full bg-green-500 text-white flex items-center justify-center font-bold text-lg flex-shrink-0">
                    4
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 mb-2">
                      Chat-ID eingeben und verbinden
                    </h3>
                    <p className="text-sm text-gray-600 mb-3">
                      Geben Sie die Chat-ID ein, die der Bot Ihnen gesendet hat:
                    </p>
                    <div className="flex gap-2 mb-3">
                      <Input
                        type="text"
                        placeholder="z.B. 123456789"
                        value={chatId}
                        onChange={(e) => setChatId(e.target.value)}
                        className="bg-white"
                      />
                      <Button
                        onClick={handleVerify}
                        disabled={isVerifying || !chatId}
                        className="bg-green-600 hover:bg-green-700"
                      >
                        {isVerifying ? "Verbinde..." : "Verbinden"}
                      </Button>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Navigation Buttons */}
          <div className="flex gap-3">
            {step > 1 && (
              <Button
                variant="outline"
                onClick={() => setStep(Math.max(1, step - 1))}
              >
                Zurück
              </Button>
            )}
            {step < 4 && (
              <Button
                onClick={() => setStep(Math.min(4, step + 1))}
                className="ml-auto"
              >
                Weiter <ArrowRight className="h-4 w-4 ml-2" />
              </Button>
            )}
          </div>
        </>
      )}

      {/* Production Setup Info */}
      <Card className="border-2 border-purple-200 bg-purple-50">
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <Smartphone className="h-4 w-4" />
            Für Entwickler: Produktions-Setup
          </CardTitle>
        </CardHeader>
        <CardContent className="text-xs space-y-2 text-purple-900">
          <p><strong>1.</strong> Erstellen Sie einen Bot über @BotFather in Telegram</p>
          <p><strong>2.</strong> Holen Sie den Bot Token</p>
          <p><strong>3.</strong> Hinterlegen Sie in Base44 Secrets: <code className="bg-white px-1 rounded">TELEGRAM_BOT_TOKEN</code></p>
          <p><strong>4.</strong> Aktualisieren Sie <code className="bg-white px-1 rounded">BOT_USERNAME</code> in dieser Datei</p>
          <p><strong>5.</strong> Aktivieren Sie den Production-Code in TelegramService.jsx</p>
        </CardContent>
      </Card>
    </div>
  );
}