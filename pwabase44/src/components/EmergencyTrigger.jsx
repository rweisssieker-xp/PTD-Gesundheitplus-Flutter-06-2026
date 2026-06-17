import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { AlertCircle, X, MapPin, Phone, Mail, Loader2, CheckCircle, Brain, MessageSquare, MessageCircle } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";
import { Textarea } from "@/components/ui/textarea";
import { sendEmergencySMSBatch, formatPhoneNumber } from "./SMSService";
import { sendEmergencyTelegramBatch } from "./TelegramService";
import { sendEmergencyWhatsAppBatch } from "./WhatsAppService";
import LiveLocationTracker from "./LiveLocationTracker";

/**
 * EmergencyTrigger Component
 * Handles the emergency alert countdown and sending process with AI-generated emergency profile
 * Now includes SMS, Telegram, WhatsApp, Email notifications + LIVE LOCATION TRACKING
 */
export default function EmergencyTrigger({ onClose }) {
  const [countdown, setCountdown] = useState(5);
  const [isSending, setIsSending] = useState(false);
  const [sent, setSent] = useState(false);
  const [location, setLocation] = useState(null);
  const [message, setMessage] = useState("");
  const [emergencyData, setEmergencyData] = useState(null);
  const [smsResults, setSmsResults] = useState(null);
  const [telegramResults, setTelegramResults] = useState(null);
  const [whatsappResults, setWhatsappResults] = useState(null);
  const [enableLiveTracking, setEnableLiveTracking] = useState(true);
  const [isTracking, setIsTracking] = useState(false);
  const [trackingId, setTrackingId] = useState(null);

  useEffect(() => {
    // Get current location
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLocation({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy
          });
        },
        (error) => {
          console.error("Location error:", error);
        }
      );
    }

    // Countdown timer
    if (countdown > 0 && !isSending && !sent) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    } else if (countdown === 0 && !isSending && !sent) {
      sendEmergencyAlert();
    }
  }, [countdown, isSending, sent]);

  const collectEmergencyData = async () => {
    try {
      const user = await base44.auth.me();
      
      const [medications, allergies, medicalHistory, contacts] = await Promise.all([
        base44.entities.Medication.filter({ active: true }).catch(() => []),
        base44.entities.Allergy.list().catch(() => []),
        base44.entities.MedicalHistory.list().catch(() => []),
        base44.entities.EmergencyContact.list().catch(() => [])
      ]);

      return {
        user,
        medications,
        allergies,
        medicalHistory: medicalHistory[0] || null,
        contacts: contacts.sort((a, b) => a.priority - b.priority),
        emergencyProfile: user.emergency_profile || null
      };
    } catch (error) {
      console.error("Error collecting emergency data:", error);
      return null;
    }
  };

  const generateEmergencyMessage = (data, shortVersion = false) => {
    if (!data) return "NOTFALL - Bitte um Hilfe!";

    const { user, medications, allergies, medicalHistory, location: loc, emergencyProfile } = data;
    
    if (shortVersion) {
      let msg = `🚨 NOTFALL von ${user.full_name || 'Patient'}\n\n`;
      
      if (loc) {
        msg += `📍 Standort:\nhttps://maps.google.com/?q=${loc.latitude},${loc.longitude}\n\n`;
      }
      
      if (enableLiveTracking) {
        msg += `📡 LIVE-TRACKING AKTIVIERT\nSie erhalten regelmäßige Standort-Updates!\n\n`;
      }
      
      if (message) {
        msg += `💬 "${message}"\n\n`;
      }

      const severeAllergies = allergies.filter(a => 
        a.severity === 'Schwer' || a.severity === 'Lebensbedrohlich'
      );
      if (severeAllergies.length > 0) {
        msg += `⚠️ KRITISCHE ALLERGIEN:\n`;
        severeAllergies.forEach(a => {
          msg += `- ${a.allergen}\n`;
        });
        msg += `\n`;
      }

      if (medications.length > 0) {
        msg += `💊 Medikamente: ${medications.slice(0, 3).map(m => m.name).join(', ')}`;
        if (medications.length > 3) msg += ` (+${medications.length - 3} mehr)`;
        msg += `\n\n`;
      }

      if (medicalHistory?.blood_type && medicalHistory.blood_type !== 'Unbekannt') {
        msg += `🩸 Blutgruppe: ${medicalHistory.blood_type}\n\n`;
      }

      if (emergencyProfile) {
        msg += `🧠 Vollständiges KI-Notfallprofil per E-Mail versendet\n\n`;
      }

      msg += `Generiert: ${new Date().toLocaleString('de-DE')}\n`;
      msg += `Gesundheit Plus Emergency Guardian`;

      return msg;
    }

    // Full version for email
    let msg = `🚨 NOTFALL-MELDUNG 🚨\n\n`;
    msg += `═══════════════════════════════════════\n`;
    msg += `PATIENT-INFORMATION\n`;
    msg += `═══════════════════════════════════════\n\n`;
    msg += `Name: ${user.full_name || 'Unbekannt'}\n`;
    
    if (user.date_of_birth) {
      const age = Math.floor((new Date() - new Date(user.date_of_birth)) / 31557600000);
      msg += `Alter: ${age} Jahre\n`;
    }
    
    if (loc) {
      msg += `\n📍 AKTUELLER STANDORT:\n`;
      msg += `Koordinaten: ${loc.latitude}, ${loc.longitude}\n`;
      msg += `Genauigkeit: ±${Math.round(loc.accuracy)}m\n`;
      msg += `Google Maps: https://maps.google.com/?q=${loc.latitude},${loc.longitude}\n`;
    }

    if (enableLiveTracking) {
      msg += `\n📡 LIVE-TRACKING:\n`;
      msg += `✅ AKTIVIERT - Sie erhalten automatische Standort-Updates\n`;
      msg += `Update-Intervall: Alle 60 Sekunden\n`;
      msg += `Dauer: 30 Minuten\n`;
    }

    if (message) {
      msg += `\n💬 PATIENTENMITTEILUNG:\n`;
      msg += `"${message}"\n`;
    }

    msg += `\n═══════════════════════════════════════\n`;
    msg += `⚠️  KRITISCHE MEDIZINISCHE INFORMATIONEN\n`;
    msg += `═══════════════════════════════════════\n\n`;

    if (emergencyProfile) {
      msg += `🧠 KI-NOTFALLPROFIL (v${emergencyProfile.version || '1.0'}):\n\n`;
      
      if (emergencyProfile.critical_warnings && emergencyProfile.critical_warnings.length > 0) {
        msg += `🚨 KRITISCHE WARNUNGEN:\n`;
        emergencyProfile.critical_warnings.forEach((w, i) => {
          msg += `${i + 1}. [${w.severity.toUpperCase()}] ${w.warning}\n`;
          msg += `   → Maßnahme: ${w.action}\n\n`;
        });
      }

      if (emergencyProfile.contraindications && emergencyProfile.contraindications.length > 0) {
        msg += `🚫 ABSOLUTE KONTRAINDIKATIONEN:\n`;
        emergencyProfile.contraindications.forEach((c, i) => {
          msg += `${i + 1}. ${c}\n`;
        });
        msg += `\n`;
      }

      if (emergencyProfile.medication_interactions && emergencyProfile.medication_interactions.length > 0) {
        msg += `💊 MEDIKAMENTÖSE INTERAKTIONEN:\n`;
        emergencyProfile.medication_interactions.forEach((m, i) => {
          msg += `${i + 1}. ${m.emergency_drug}: ${m.interaction}\n`;
          msg += `   Empfehlung: ${m.recommendation}\n\n`;
        });
      }

      if (emergencyProfile.immediate_actions && emergencyProfile.immediate_actions.length > 0) {
        msg += `✅ EMPFOHLENE SOFORTMAẞNAHMEN:\n`;
        emergencyProfile.immediate_actions
          .sort((a, b) => a.priority - b.priority)
          .slice(0, 3)
          .forEach((a) => {
            msg += `${a.priority}. ${a.action}\n`;
            msg += `   Begründung: ${a.rationale}\n\n`;
          });
      }

      if (emergencyProfile.risk_assessment) {
        msg += `📊 RISIKOBEWERTUNG: ${emergencyProfile.risk_assessment.overall_risk_level?.toUpperCase() || 'UNBEKANNT'}\n\n`;
      }

      if (emergencyProfile.summary) {
        msg += `📝 ZUSAMMENFASSUNG:\n${emergencyProfile.summary}\n\n`;
      }
    }

    msg += `═══════════════════════════════════════\n`;
    msg += `STANDARD MEDIZINISCHE DATEN\n`;
    msg += `═══════════════════════════════════════\n\n`;

    const severeAllergies = allergies.filter(a => 
      a.severity === 'Schwer' || a.severity === 'Lebensbedrohlich'
    );
    if (severeAllergies.length > 0) {
      msg += `⚠️ KRITISCHE ALLERGIEN:\n`;
      severeAllergies.forEach(a => {
        msg += `- ${a.allergen} (${a.severity})\n`;
        if (a.symptoms) msg += `  Symptome: ${a.symptoms}\n`;
      });
      msg += `\n`;
    } else if (allergies.length > 0) {
      msg += `ALLERGIEN:\n`;
      allergies.slice(0, 5).forEach(a => {
        msg += `- ${a.allergen} (${a.severity})\n`;
      });
      msg += `\n`;
    }

    if (medications.length > 0) {
      msg += `💊 AKTUELLE MEDIKAMENTE:\n`;
      medications.slice(0, 7).forEach(m => {
        msg += `- ${m.name} (${m.dosage}, ${m.frequency})\n`;
        if (m.reason) msg += `  Grund: ${m.reason}\n`;
      });
      if (medications.length > 7) {
        msg += `... und ${medications.length - 7} weitere\n`;
      }
      msg += `\n`;
    }

    if (medicalHistory?.blood_type && medicalHistory.blood_type !== 'Unbekannt') {
      msg += `🩸 BLUTGRUPPE: ${medicalHistory.blood_type}\n\n`;
    }

    if (medicalHistory?.diagnoses && medicalHistory.diagnoses.length > 0) {
      msg += `📋 WICHTIGE DIAGNOSEN:\n`;
      medicalHistory.diagnoses.slice(0, 5).forEach(d => {
        msg += `- ${d.diagnosis}`;
        if (d.date) msg += ` (${new Date(d.date).toLocaleDateString('de-DE')})`;
        msg += `\n`;
      });
      msg += `\n`;
    }

    if (medicalHistory?.surgeries && medicalHistory.surgeries.length > 0) {
      msg += `🏥 OPERATIONEN:\n`;
      medicalHistory.surgeries.slice(0, 3).forEach(s => {
        msg += `- ${s.surgery}`;
        if (s.date) msg += ` (${new Date(s.date).toLocaleDateString('de-DE')})`;
        msg += `\n`;
      });
      msg += `\n`;
    }

    msg += `═══════════════════════════════════════\n`;
    msg += `⏰ Zeitstempel: ${new Date().toLocaleString('de-DE')}\n`;
    msg += `📱 Generiert von: Gesundheit Plus - Emergency Guardian\n`;
    msg += `${emergencyProfile ? `🧠 Mit KI-Notfallprofil v${emergencyProfile.version}\n` : ''}`;
    if (enableLiveTracking) {
      msg += `📡 Mit Live-Location-Tracking (30 Min)\n`;
    }
    msg += `═══════════════════════════════════════\n`;

    return msg;
  };

  const sendEmergencyAlert = async () => {
    setIsSending(true);
    
    try {
      const data = await collectEmergencyData();
      setEmergencyData(data);

      if (!data || !data.contacts || data.contacts.length === 0) {
        toast.error("Keine Notfallkontakte eingerichtet!");
        onClose();
        return;
      }

      const contactsWithFormattedPhones = data.contacts.map(c => ({
        ...c,
        phone: formatPhoneNumber(c.phone)
      }));

      const emergencyMsgFull = generateEmergencyMessage({
        ...data,
        location
      }, false);

      const emergencyMsgShort = generateEmergencyMessage({
        ...data,
        location
      }, true);

      const notificationPromises = [];
      
      // Send initial notifications
      toast.info("📱 Sende initiale Benachrichtigungen...");
      
      const smsPromise = sendEmergencySMSBatch(
        contactsWithFormattedPhones,
        emergencyMsgShort
      ).then(results => {
        setSmsResults(results);
        if (results.sent > 0) {
          toast.success(`✅ ${results.sent} SMS erfolgreich versendet`);
        }
        if (results.failed > 0) {
          toast.warning(`⚠️ ${results.failed} SMS fehlgeschlagen`);
        }
        return results;
      }).catch(error => {
        console.error("SMS batch error:", error);
        toast.error("SMS-Versand fehlgeschlagen");
        return { sent: 0, failed: data.contacts.length };
      });
      notificationPromises.push(smsPromise);

      const telegramPromise = sendEmergencyTelegramBatch(
        data.contacts,
        emergencyMsgShort,
        location
      ).then(results => {
        setTelegramResults(results);
        if (results.sent > 0) {
          toast.success(`✅ ${results.sent} Telegram-Nachricht(en) gesendet`);
        }
        return results;
      }).catch(error => {
        console.error("Telegram batch error:", error);
        toast.error("Telegram-Versand fehlgeschlagen");
        return { sent: 0, failed: 0 };
      });
      notificationPromises.push(telegramPromise);

      const whatsappPromise = sendEmergencyWhatsAppBatch(
        data.contacts,
        emergencyMsgShort,
        location
      ).then(results => {
        setWhatsappResults(results);
        if (results.sent > 0) {
          toast.success(`✅ ${results.sent} WhatsApp-Nachricht(en) gesendet`);
        }
        return results;
      }).catch(error => {
        console.error("WhatsApp batch error:", error);
        toast.error("WhatsApp-Versand fehlgeschlagen");
        return { sent: 0, failed: 0 };
      });
      notificationPromises.push(whatsappPromise);
      
      for (const contact of data.contacts) {
        if (contact.notify_via_email && contact.email) {
          notificationPromises.push(
            base44.integrations.Core.SendEmail({
              from_name: "Gesundheit Plus - NOTFALL",
              to: contact.email,
              subject: `🚨 NOTFALL-MELDUNG von ${data.user.full_name || 'Patient'} - SOFORTIGE AUFMERKSAMKEIT ERFORDERLICH`,
              body: emergencyMsgFull
            }).catch(err => {
              console.error("Email error:", err);
              toast.warning(`E-Mail an ${contact.name} fehlgeschlagen`);
            })
          );
        }
      }

      await Promise.all(notificationPromises);

      await base44.entities.Notification.create({
        title: "🚨 Notfall-Meldung gesendet",
        message: `Ihr Notfallprofil wurde über alle Kanäle an ${data.contacts.length} Kontakt(e) gesendet.${enableLiveTracking ? ' Live-Tracking aktiviert.' : ''}`,
        type: "warning",
        priority: "high"
      });

      setSent(true);
      toast.success(`✅ Notfallmeldung erfolgreich versendet!`);

      // Start live tracking if enabled
      if (enableLiveTracking) {
        const newTrackingId = `emergency_${Date.now()}`;
        setTrackingId(newTrackingId);
        setIsTracking(true);
        toast.info("📡 Live-Tracking gestartet");
      } else {
        setTimeout(() => {
          onClose();
        }, 3000);
      }

    } catch (error) {
      console.error("Emergency alert error:", error);
      toast.error("Fehler beim Senden der Notfall-Meldung");
      onClose();
    } finally {
      setIsSending(false);
    }
  };

  const handleCancel = () => {
    setCountdown(-1);
    toast.info("Notfall-Meldung abgebrochen");
    onClose();
  };

  const handleTrackingStop = (reason) => {
    setIsTracking(false);
    setTimeout(() => {
      onClose();
    }, 2000);
  };

  // Show live tracking interface
  if (isTracking && sent && emergencyData && trackingId) {
    return (
      <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4 backdrop-blur-sm overflow-y-auto">
        <div className="w-full max-w-md py-4">
          <LiveLocationTracker
            trackingId={trackingId}
            contacts={emergencyData.contacts}
            initialMessage={message}
            durationMinutes={30}
            updateIntervalSeconds={60}
            onStop={handleTrackingStop}
          />
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4 backdrop-blur-sm">
      <Card className="w-full max-w-md border-4 border-red-600 shadow-2xl animate-in fade-in zoom-in duration-200">
        <CardHeader className="bg-gradient-to-r from-red-600 to-red-700 text-white">
          <CardTitle className="flex items-center gap-3 text-xl">
            <AlertCircle className="h-8 w-8 animate-pulse" />
            {sent ? "Notfall-Meldung gesendet" : isSending ? "Sende Notfall-Meldung..." : "NOTFALL-ALARM"}
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-6 space-y-4">
          {!isSending && !sent && (
            <>
              <div className="text-center">
                <div className="text-6xl font-bold text-red-600 mb-2 animate-pulse">
                  {countdown}
                </div>
                <p className="text-lg font-semibold text-gray-900 mb-1">
                  Sekunden bis zur Notfall-Meldung
                </p>
                <p className="text-sm text-gray-600">
                  Alle Kontakte werden benachrichtigt
                </p>
              </div>

              <div className="bg-purple-50 border-2 border-purple-200 rounded-lg p-3 space-y-2">
                <div className="flex items-center gap-2 text-sm text-purple-900 font-semibold">
                  <Brain className="h-4 w-4" />
                  <span>KI-Notfallprofil wird gesendet</span>
                </div>
                <p className="text-xs text-purple-700">
                  Inklusive personalisierter Behandlungsempfehlungen
                </p>
              </div>

              <div className="bg-blue-50 border-2 border-blue-200 rounded-lg p-3 space-y-2">
                <div className="flex items-center gap-2 text-sm text-blue-900">
                  <MapPin className="h-4 w-4" />
                  <span className="font-semibold">
                    {location ? "✓ Standort erfasst" : "Erfasse Standort..."}
                  </span>
                </div>
                <div className="flex items-center gap-2 text-sm text-blue-900">
                  <MessageSquare className="h-4 w-4" />
                  <span className="font-semibold">SMS-Benachrichtigung</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-blue-900">
                  <MessageCircle className="h-4 w-4" />
                  <span className="font-semibold">Telegram + WhatsApp</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-blue-900">
                  <Mail className="h-4 w-4" />
                  <span>E-Mail mit Details</span>
                </div>
              </div>

              {/* Live Tracking Toggle */}
              <div className="bg-orange-50 border-2 border-orange-200 rounded-lg p-3">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={enableLiveTracking}
                    onChange={(e) => setEnableLiveTracking(e.target.checked)}
                    className="h-5 w-5 rounded border-orange-300"
                  />
                  <div className="flex-1">
                    <p className="text-sm font-semibold text-orange-900">
                      📡 Live-Standortverfolgung (30 Min)
                    </p>
                    <p className="text-xs text-orange-700">
                      Kontakte erhalten alle 60 Sek. automatische Updates
                    </p>
                  </div>
                </label>
              </div>

              <div>
                <label className="text-sm font-semibold text-gray-900 mb-2 block">
                  Zusätzliche Nachricht (optional):
                </label>
                <Textarea
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="z.B. Ich bin gestürzt, Brustschmerzen, Atemnot..."
                  rows={2}
                  className="text-sm"
                />
              </div>

              <div className="flex gap-3">
                <Button
                  onClick={sendEmergencyAlert}
                  className="flex-1 h-12 bg-red-600 hover:bg-red-700 text-white font-bold"
                >
                  JETZT SENDEN
                </Button>
                <Button
                  onClick={handleCancel}
                  variant="outline"
                  className="h-12 px-6 border-2"
                >
                  <X className="h-5 w-5" />
                </Button>
              </div>

              <p className="text-xs text-center text-gray-500">
                Drücken Sie "X" um den Alarm abzubrechen
              </p>
            </>
          )}

          {isSending && (
            <div className="text-center py-8">
              <Loader2 className="h-16 w-16 animate-spin text-red-600 mx-auto mb-4" />
              <p className="text-lg font-semibold text-gray-900 mb-2">
                Sende Notfall-Informationen...
              </p>
              <div className="space-y-1">
                <p className="text-sm text-gray-600">
                  ✓ Medizinische Daten werden übermittelt
                </p>
                <p className="text-sm text-blue-600 font-semibold">
                  📱 SMS • ✈️ Telegram • 💬 WhatsApp
                </p>
                <p className="text-sm text-purple-600 font-semibold">
                  🧠 KI-Notfallprofil wird eingebunden
                </p>
                {enableLiveTracking && (
                  <p className="text-sm text-orange-600 font-semibold">
                    📡 Live-Tracking wird vorbereitet
                  </p>
                )}
              </div>
            </div>
          )}

          {sent && !isTracking && (
            <div className="text-center py-8">
              <CheckCircle className="h-16 w-16 text-green-600 mx-auto mb-4" />
              <p className="text-lg font-semibold text-gray-900 mb-2">
                Notfall-Meldung erfolgreich gesendet!
              </p>
              {emergencyData && (
                <>
                  <p className="text-sm text-gray-600 mb-2">
                    {emergencyData.contacts.length} Kontakt(e) wurden informiert
                  </p>
                  <div className="text-sm space-y-1">
                    {smsResults && smsResults.sent > 0 && (
                      <p className="text-green-600 font-semibold">
                        ✓ {smsResults.sent} SMS gesendet
                      </p>
                    )}
                    {telegramResults && telegramResults.sent > 0 && (
                      <p className="text-blue-600 font-semibold">
                        ✓ {telegramResults.sent} Telegram gesendet
                      </p>
                    )}
                    {whatsappResults && whatsappResults.sent > 0 && (
                      <p className="text-green-600 font-semibold">
                        ✓ {whatsappResults.sent} WhatsApp gesendet
                      </p>
                    )}
                  </div>
                  {emergencyData.emergencyProfile && (
                    <p className="text-xs text-purple-600 font-semibold mt-2">
                      ✓ Inklusive KI-Notfallprofil
                    </p>
                  )}
                </>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}