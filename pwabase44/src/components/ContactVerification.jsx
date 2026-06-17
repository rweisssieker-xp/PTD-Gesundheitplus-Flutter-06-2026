/**
 * Contact Verification Component
 * Handles verification of emergency contact channels
 */

import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { 
  Shield, 
  CheckCircle, 
  XCircle,
  Clock,
  Send,
  Loader2,
  AlertCircle
} from "lucide-react";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";
import { useQueryClient } from "@tanstack/react-query";

export default function ContactVerification({ contact, channel, onClose, onVerified }) {
  const [verificationCode, setVerificationCode] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [codeSent, setCodeSent] = useState(false);
  const [timeRemaining, setTimeRemaining] = useState(0);
  const queryClient = useQueryClient();

  useEffect(() => {
    let timer;
    if (timeRemaining > 0) {
      timer = setInterval(() => {
        setTimeRemaining(prev => Math.max(0, prev - 1));
      }, 1000);
    }
    return () => clearInterval(timer);
  }, [timeRemaining]);

  const channelInfo = {
    sms: {
      label: 'SMS',
      icon: '📱',
      target: contact.phone,
      description: 'Wir senden einen 6-stelligen Code per SMS'
    },
    whatsapp: {
      label: 'WhatsApp',
      icon: '💬',
      target: contact.whatsapp_number,
      description: 'Wir senden einen 6-stelligen Code per WhatsApp'
    },
    telegram: {
      label: 'Telegram',
      icon: '✈️',
      target: contact.telegram_chat_id,
      description: 'Wir senden einen 6-stelligen Code per Telegram'
    },
    email: {
      label: 'E-Mail',
      icon: '📧',
      target: contact.email,
      description: 'Wir senden einen 6-stelligen Code per E-Mail'
    }
  };

  const info = channelInfo[channel] || {};

  const sendVerificationCode = async () => {
    setIsSending(true);

    try {
      const result = await base44.functions.sendVerificationCode({
        contactId: contact.id,
        channel: channel,
        contact: contact
      });

      if (result.success) {
        setCodeSent(true);
        setTimeRemaining(600); // 10 minutes
        toast.success('Verifizierungscode gesendet', {
          description: `Code wurde an ${info.target} gesendet`
        });
      } else if (result.simulated) {
        toast.warning('Simulations-Modus', {
          description: 'Service nicht konfiguriert. Code: 123456 (Test)'
        });
        setCodeSent(true);
        setTimeRemaining(600);
      } else {
        throw new Error(result.error || 'Fehler beim Senden');
      }
    } catch (error) {
      console.error('Send verification error:', error);
      toast.error('Fehler beim Senden', {
        description: error.message
      });
    } finally {
      setIsSending(false);
    }
  };

  const verifyCode = async () => {
    if (!verificationCode || verificationCode.length !== 6) {
      toast.error('Ungültiger Code', {
        description: 'Bitte geben Sie einen 6-stelligen Code ein'
      });
      return;
    }

    setIsVerifying(true);

    try {
      // Fetch current contact to check code
      const currentContact = await base44.entities.EmergencyContact.filter({ id: contact.id });
      
      if (!currentContact || currentContact.length === 0) {
        throw new Error('Kontakt nicht gefunden');
      }

      const contactData = currentContact[0];

      // Check if code is expired
      if (contactData.verification_code_expires) {
        const expiresAt = new Date(contactData.verification_code_expires);
        if (expiresAt < new Date()) {
          toast.error('Code abgelaufen', {
            description: 'Bitte fordern Sie einen neuen Code an'
          });
          setIsVerifying(false);
          return;
        }
      }

      // Check if code matches
      if (contactData.last_verification_code !== verificationCode) {
        toast.error('Falscher Code', {
          description: 'Der eingegebene Code ist nicht korrekt'
        });
        setIsVerifying(false);
        return;
      }

      // Update verification status
      const verificationUpdate = {
        verification_status: {
          ...contactData.verification_status,
          [`${channel}_verified`]: true,
          [`${channel}_verified_at`]: new Date().toISOString()
        },
        last_verification_code: null,
        verification_code_expires: null
      };

      await base44.entities.EmergencyContact.update(contact.id, verificationUpdate);

      // Invalidate queries
      queryClient.invalidateQueries({ queryKey: ['emergency-contacts'] });

      toast.success('✅ Verifizierung erfolgreich!', {
        description: `${info.label} wurde erfolgreich verifiziert`
      });

      if (onVerified) {
        onVerified(channel);
      }

      setTimeout(() => {
        if (onClose) {
          onClose();
        }
      }, 1500);

    } catch (error) {
      console.error('Verify code error:', error);
      toast.error('Fehler bei der Verifizierung', {
        description: error.message
      });
    } finally {
      setIsVerifying(false);
    }
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${String(secs).padStart(2, '0')}`;
  };

  const isVerified = contact.verification_status?.[`${channel}_verified`];

  if (isVerified) {
    return (
      <Card className="border-2 border-green-200 bg-green-50">
        <CardContent className="pt-6">
          <div className="text-center py-6">
            <CheckCircle className="h-16 w-16 text-green-600 mx-auto mb-4" />
            <p className="font-semibold text-green-900 mb-2">
              {info.icon} {info.label} bereits verifiziert
            </p>
            <p className="text-sm text-green-700">
              Verifiziert am {new Date(contact.verification_status[`${channel}_verified_at`]).toLocaleDateString('de-DE')}
            </p>
            {onClose && (
              <Button
                onClick={onClose}
                variant="outline"
                className="mt-4"
              >
                Schließen
              </Button>
            )}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-2 border-blue-200">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Shield className="h-5 w-5 text-blue-600" />
          {info.icon} {info.label} verifizieren
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Contact Info */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-sm font-semibold text-blue-900 mb-1">
            Kontakt: {contact.name}
          </p>
          <p className="text-sm text-blue-700">
            {info.label}: {info.target}
          </p>
        </div>

        {!codeSent ? (
          <>
            {/* Description */}
            <div className="flex gap-3">
              <AlertCircle className="h-5 w-5 text-gray-500 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-gray-700">
                <p className="mb-2">{info.description}</p>
                <p>
                  Nachdem Sie den Code erhalten haben, geben Sie ihn hier ein, um den Kanal zu verifizieren.
                </p>
              </div>
            </div>

            {/* Send Button */}
            <Button
              onClick={sendVerificationCode}
              disabled={isSending}
              className="w-full bg-blue-600 hover:bg-blue-700"
            >
              {isSending ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Wird gesendet...
                </>
              ) : (
                <>
                  <Send className="h-4 w-4 mr-2" />
                  Code senden
                </>
              )}
            </Button>
          </>
        ) : (
          <>
            {/* Code sent confirmation */}
            <div className="bg-green-50 border border-green-200 rounded-lg p-3 flex gap-3">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-green-900">
                <p className="font-semibold mb-1">Code gesendet!</p>
                <p>Bitte überprüfen Sie {info.label} und geben Sie den erhaltenen Code ein.</p>
              </div>
            </div>

            {/* Timer */}
            {timeRemaining > 0 && (
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Clock className="h-4 w-4" />
                <span>Code gültig für: {formatTime(timeRemaining)}</span>
              </div>
            )}

            {/* Code Input */}
            <div>
              <label className="text-sm font-semibold text-gray-900 mb-2 block">
                Verifizierungscode eingeben:
              </label>
              <Input
                type="text"
                placeholder="123456"
                value={verificationCode}
                onChange={(e) => setVerificationCode(e.target.value.replace(/\D/g, '').substring(0, 6))}
                className="text-center text-2xl tracking-widest font-mono"
                maxLength={6}
              />
              <p className="text-xs text-gray-500 mt-1">
                6-stelliger Code
              </p>
            </div>

            {/* Verify Button */}
            <Button
              onClick={verifyCode}
              disabled={isVerifying || verificationCode.length !== 6}
              className="w-full bg-green-600 hover:bg-green-700"
            >
              {isVerifying ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Wird verifiziert...
                </>
              ) : (
                <>
                  <Shield className="h-4 w-4 mr-2" />
                  Code verifizieren
                </>
              )}
            </Button>

            {/* Resend */}
            <Button
              onClick={sendVerificationCode}
              disabled={isSending || timeRemaining > 540} // Can resend after 1 minute
              variant="outline"
              className="w-full"
            >
              Code erneut senden
            </Button>
          </>
        )}

        {/* Cancel */}
        {onClose && (
          <Button
            onClick={onClose}
            variant="ghost"
            className="w-full"
          >
            Abbrechen
          </Button>
        )}

        {/* Info */}
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-3">
          <p className="text-xs text-gray-600">
            💡 <strong>Warum verifizieren?</strong> Die Verifizierung stellt sicher, dass Notfallbenachrichtigungen 
            auch tatsächlich ankommen und der Kontakt benachrichtigt werden kann.
          </p>
        </div>
      </CardContent>
    </Card>
  );
}