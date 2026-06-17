/**
 * Consent Manager Component
 * GDPR-compliant consent management
 */

import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { 
  Shield, 
  CheckCircle, 
  X,
  Info,
  AlertTriangle
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";

export default function ConsentManager({ onComplete }) {
  const [consents, setConsents] = useState({
    essential: true, // Always required
    emergency_notifications: false,
    ai_analysis: false,
    health_recommendations: false,
    data_storage: false
  });
  const [hasAccepted, setHasAccepted] = useState(false);

  useEffect(() => {
    loadConsents();
  }, []);

  const loadConsents = async () => {
    try {
      const user = await base44.auth.me();
      if (user.privacy_consents) {
        setConsents(user.privacy_consents);
        setHasAccepted(true);
      }
    } catch (error) {
      console.error('Load consents error:', error);
    }
  };

  const handleConsentChange = (key, value) => {
    setConsents(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const handleAcceptAll = async () => {
    const allConsents = {
      essential: true,
      emergency_notifications: true,
      ai_analysis: true,
      health_recommendations: true,
      data_storage: true,
      accepted_at: new Date().toISOString()
    };

    try {
      await base44.auth.updateMe({
        privacy_consents: allConsents
      });

      setConsents(allConsents);
      setHasAccepted(true);
      toast.success('Einwilligungen gespeichert');

      if (onComplete) {
        onComplete(allConsents);
      }
    } catch (error) {
      toast.error('Fehler beim Speichern');
    }
  };

  const handleAcceptSelected = async () => {
    const selectedConsents = {
      ...consents,
      accepted_at: new Date().toISOString()
    };

    try {
      await base44.auth.updateMe({
        privacy_consents: selectedConsents
      });

      setHasAccepted(true);
      toast.success('Einwilligungen gespeichert');

      if (onComplete) {
        onComplete(selectedConsents);
      }
    } catch (error) {
      toast.error('Fehler beim Speichern');
    }
  };

  const handleReject = () => {
    const minimalConsents = {
      essential: true,
      emergency_notifications: false,
      ai_analysis: false,
      health_recommendations: false,
      data_storage: false,
      accepted_at: new Date().toISOString()
    };

    setConsents(minimalConsents);
    
    toast.info('Nur notwendige Funktionen aktiviert', {
      description: 'Sie können die Einstellungen jederzeit ändern'
    });

    if (onComplete) {
      onComplete(minimalConsents);
    }
  };

  const consentItems = [
    {
      key: 'essential',
      title: 'Notwendige Funktionen',
      description: 'Grundlegende Funktionalität der App (Login, Datenspeicherung)',
      required: true,
      icon: Shield
    },
    {
      key: 'emergency_notifications',
      title: 'Notfall-Benachrichtigungen',
      description: 'Ermöglicht das Senden von Notfall-Alarmen an Ihre hinterlegten Kontakte inkl. Standort und Gesundheitsdaten',
      required: false,
      icon: AlertTriangle,
      color: 'text-red-600'
    },
    {
      key: 'ai_analysis',
      title: 'KI-gestützte Analysen',
      description: 'Nutzung von KI zur Analyse Ihrer Gesundheitsdaten für Notfallprofile und Risikoeinschätzungen',
      required: false,
      icon: Shield,
      color: 'text-purple-600'
    },
    {
      key: 'health_recommendations',
      title: 'Gesundheitsempfehlungen',
      description: 'Personalisierte Empfehlungen zu Vorsorge, Medikation und Lifestyle basierend auf Ihren Daten',
      required: false,
      icon: CheckCircle,
      color: 'text-green-600'
    },
    {
      key: 'data_storage',
      title: 'Langfristige Datenspeicherung',
      description: 'Speicherung Ihrer Gesundheitsdaten für Verlaufsanalysen und historische Auswertungen',
      required: false,
      icon: Shield,
      color: 'text-blue-600'
    }
  ];

  return (
    <Card className="border-2 border-blue-200">
      <CardHeader className="bg-gradient-to-r from-blue-600 to-blue-700 text-white">
        <CardTitle className="flex items-center gap-2">
          <Shield className="h-6 w-6" />
          Datenschutz-Einwilligungen
        </CardTitle>
        <p className="text-sm text-blue-100 mt-2">
          Wir respektieren Ihre Privatsphäre. Bitte wählen Sie, welche Funktionen Sie nutzen möchten.
        </p>
      </CardHeader>
      <CardContent className="pt-6 space-y-6">
        {/* Info Box */}
        <div className="bg-blue-50 border-2 border-blue-200 rounded-lg p-4">
          <div className="flex gap-3">
            <Info className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-blue-900">
              <p className="font-semibold mb-1">Ihre Rechte (DSGVO)</p>
              <ul className="space-y-1 ml-4 list-disc text-xs">
                <li>Alle Daten bleiben in Deutschland</li>
                <li>Keine Weitergabe an Dritte</li>
                <li>Jederzeit widerrufbar</li>
                <li>Vollständiger Datenexport möglich</li>
                <li>Löschung auf Anfrage</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Consent Items */}
        <div className="space-y-4">
          {consentItems.map((item) => {
            const Icon = item.icon;
            return (
              <div 
                key={item.key}
                className={`p-4 rounded-lg border-2 ${
                  item.required 
                    ? 'bg-gray-50 border-gray-300' 
                    : consents[item.key]
                      ? 'bg-green-50 border-green-200'
                      : 'bg-white border-gray-200'
                }`}
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="flex items-start gap-3 flex-1">
                    <Icon className={`h-5 w-5 ${item.color || 'text-gray-600'} flex-shrink-0 mt-0.5`} />
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <Label htmlFor={item.key} className="font-semibold text-gray-900 cursor-pointer">
                          {item.title}
                        </Label>
                        {item.required && (
                          <span className="text-xs bg-gray-200 text-gray-700 px-2 py-0.5 rounded">
                            Erforderlich
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-gray-600">
                        {item.description}
                      </p>
                    </div>
                  </div>
                  <Switch
                    id={item.key}
                    checked={consents[item.key]}
                    onCheckedChange={(checked) => handleConsentChange(item.key, checked)}
                    disabled={item.required}
                  />
                </div>
              </div>
            );
          })}
        </div>

        {/* Action Buttons */}
        {!hasAccepted ? (
          <div className="space-y-3 pt-4 border-t">
            <Button
              onClick={handleAcceptAll}
              className="w-full h-12 bg-green-600 hover:bg-green-700"
            >
              <CheckCircle className="h-5 w-5 mr-2" />
              Alle akzeptieren
            </Button>
            <Button
              onClick={handleAcceptSelected}
              variant="outline"
              className="w-full h-12 border-2"
            >
              Auswahl speichern
            </Button>
            <Button
              onClick={handleReject}
              variant="ghost"
              className="w-full"
            >
              <X className="h-4 w-4 mr-2" />
              Nur notwendige
            </Button>
          </div>
        ) : (
          <div className="pt-4 border-t">
            <div className="bg-green-50 border-2 border-green-200 rounded-lg p-4 mb-3">
              <div className="flex items-center gap-2 text-green-900">
                <CheckCircle className="h-5 w-5" />
                <p className="font-semibold">Einwilligungen gespeichert</p>
              </div>
              <p className="text-sm text-green-700 mt-1">
                Sie können Ihre Einstellungen jederzeit in den Datenschutz-Einstellungen ändern.
              </p>
            </div>
            <Button
              onClick={handleAcceptSelected}
              variant="outline"
              className="w-full"
            >
              Änderungen speichern
            </Button>
          </div>
        )}

        {/* Footer */}
        <div className="text-xs text-gray-500 text-center pt-4 border-t">
          <p>
            Mehr Informationen in unserer{' '}
            <a href="/Datenschutz" className="text-blue-600 hover:underline">
              Datenschutzerklärung
            </a>
          </p>
        </div>
      </CardContent>
    </Card>
  );
}