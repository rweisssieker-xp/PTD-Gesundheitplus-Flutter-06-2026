import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Progress } from "@/components/ui/progress";
import { ChevronRight, Mic, Volume2, Shield, CheckCircle } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";
import { useNavigate } from "react-router-dom";
import { createPageUrl } from "@/utils";
import ConsentManager from "./ConsentManager";
import StorageModeSelector from "./StorageModeSelector";
import { useStorage } from "@/lib/StorageContext";

const onboardingSteps = [
  {
    id: 'welcome',
    title: "Willkommen bei Gesundheit Plus",
    subtitle: "Ihre digitale Gesundheitsakte",
    type: 'info',
    content: `
      **Gesundheit Plus** hilft Ihnen, Ihre Gesundheitsdaten sicher und übersichtlich zu verwalten.

      **Was Sie erwartet:**
      • 📋 Digitale Patientenakte
      • 💊 Medikamentenverwaltung
      • 🚨 Notfall-System mit KI
      • 🧠 KI-Gesundheitscoach
      • 📱 Immer verfügbar

      **Datenschutz:**
      Ihre Daten bleiben in Deutschland und werden verschlüsselt gespeichert.
    `,
    voicePrompt: "Willkommen bei Gesundheit Plus, Ihrer digitalen Gesundheitsakte. Ich begleite Sie durch die Einrichtung."
  },
  {
    id: 'storage',
    title: "Datenspeicherung",
    subtitle: "Wo sollen Ihre Daten gespeichert werden?",
    type: 'storage',
    voicePrompt: "Bitte wählen Sie, ob Ihre Gesundheitsdaten nur lokal auf diesem Gerät oder in der Cloud gespeichert werden sollen."
  },
  {
    id: 'privacy',
    title: "Datenschutz-Einwilligungen",
    subtitle: "Ihre Privatsphäre ist uns wichtig",
    type: 'consent',
    voicePrompt: "Bitte nehmen Sie sich einen Moment Zeit, um die Datenschutz-Einwilligungen zu prüfen."
  },
  {
    id: 'personal',
    title: "Persönliche Angaben",
    subtitle: "Grundlegende Informationen",
    type: 'form',
    fields: [
      { name: "date_of_birth", label: "Geburtsdatum", type: "date", required: true },
      { name: "gender", label: "Geschlecht", type: "select", options: ["männlich", "weiblich", "divers"], required: true }
    ],
    voicePrompt: "Bitte geben Sie zunächst Ihr Geburtsdatum und Ihr Geschlecht ein."
  },
  {
    id: 'health',
    title: "Gesundheitsdaten",
    subtitle: "Wichtige medizinische Informationen",
    type: 'form',
    fields: [
      { name: "height", label: "Körpergröße (cm)", type: "number", required: false },
      { name: "weight", label: "Gewicht (kg)", type: "number", required: false },
      { name: "blood_type", label: "Blutgruppe", type: "select", options: ["A+", "A-", "B+", "B-", "AB+", "AB-", "0+", "0-", "Unbekannt"], required: false }
    ],
    voicePrompt: "Bitte geben Sie Ihre Körpergröße, Gewicht und Blutgruppe ein, falls bekannt."
  },
  {
    id: 'emergency',
    title: "Notfallkontakt (optional)",
    subtitle: "Für den Notfall erreichbar",
    type: 'form',
    fields: [
      { name: "emergency_contact_name", label: "Name", type: "text", required: false },
      { name: "emergency_contact_phone", label: "Telefonnummer", type: "tel", required: false, placeholder: "+49..." }
    ],
    voicePrompt: "Optional: Geben Sie einen Notfallkontakt an. Sie können dies auch später einrichten."
  },
  {
    id: 'complete',
    title: "Einrichtung abgeschlossen!",
    subtitle: "Sie können jetzt starten",
    type: 'completion',
    content: `
      ✅ **Ihre Gesundheitsakte ist bereit!**

      **Nächste Schritte:**
      1. Fügen Sie Medikamente und Allergien hinzu
      2. Richten Sie weitere Notfallkontakte ein
      3. Erstellen Sie Ihr KI-Notfallprofil
      4. Scannen Sie wichtige Dokumente

      **Tipp:** Erkunden Sie den KI-Gesundheitscoach für personalisierte Empfehlungen!
    `,
    voicePrompt: "Herzlichen Glückwunsch! Ihre Gesundheitsakte ist eingerichtet. Sie können jetzt starten."
  }
];

export default function OnboardingWizard({ onComplete }) {
  const [currentStep, setCurrentStep] = useState(0);
  const [formData, setFormData] = useState({});
  const [isListening, setIsListening] = useState(false);
  const [consents, setConsents] = useState(null);
  const navigate = useNavigate();
  const { mode: storageMode } = useStorage();

  useEffect(() => {
    speakStep();
  }, [currentStep]);

  const speakStep = () => {
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(onboardingSteps[currentStep].voicePrompt);
      utterance.lang = 'de-DE';
      utterance.rate = 0.9;
      window.speechSynthesis.speak(utterance);
    }
  };

  const startVoiceInput = (fieldName) => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      toast.error("Spracherkennung nicht verfügbar");
      return;
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    const recognition = new SpeechRecognition();
    
    recognition.lang = 'de-DE';
    recognition.continuous = false;
    recognition.interimResults = false;

    recognition.onstart = () => {
      setIsListening(true);
      toast.info("Sprechen Sie jetzt...");
    };

    recognition.onresult = (event) => {
      const transcript = event.results[0][0].transcript;
      setFormData({ ...formData, [fieldName]: transcript });
      toast.success("Spracheingabe erfolgreich");
    };

    recognition.onerror = () => {
      setIsListening(false);
      toast.error("Spracherkennung fehlgeschlagen");
    };

    recognition.onend = () => {
      setIsListening(false);
    };

    recognition.start();
  };

  const handleStorageSelected = () => {
    setCurrentStep(currentStep + 1);
  };

  const handleConsentComplete = (consentData) => {
    setConsents(consentData);
    toast.success("Einwilligungen gespeichert");
    setCurrentStep(currentStep + 1);
  };

  const handleNext = async () => {
    const step = onboardingSteps[currentStep];

    if (step.type === 'form') {
      const requiredFields = step.fields.filter(f => f.required);
      
      for (const field of requiredFields) {
        if (!formData[field.name]) {
          toast.error(`Bitte füllen Sie das Feld "${field.label}" aus`);
          return;
        }
      }
    }

    if (currentStep < onboardingSteps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      await completeOnboarding();
    }
  };

  const completeOnboarding = async () => {
    try {
      // Save user data
      const userData = {
        ...formData,
        onboarding_completed: true,
        onboarding_step: onboardingSteps.length
      };

      await base44.auth.updateMe(userData);
      
      // Create medical history if blood type provided
      if (formData.blood_type && formData.blood_type !== "Unbekannt") {
        const existingHistory = await base44.entities.MedicalHistory.list();
        if (existingHistory.length === 0) {
          await base44.entities.MedicalHistory.create({
            blood_type: formData.blood_type,
            diagnoses: [],
            surgeries: [],
            lifestyle: {}
          });
        }
      }

      // Create emergency contact if provided
      if (formData.emergency_contact_name && formData.emergency_contact_phone) {
        await base44.entities.EmergencyContact.create({
          name: formData.emergency_contact_name,
          phone: formData.emergency_contact_phone,
          relationship: "Sonstige",
          priority: 1,
          notify_via_sms: true,
          notify_via_email: false
        });
      }

      toast.success("✅ Einrichtung abgeschlossen!", {
        description: "Willkommen bei Gesundheit Plus"
      });

      if (onComplete) onComplete();
      
      setTimeout(() => {
        navigate(createPageUrl("Home"));
      }, 1500);
      
    } catch (error) {
      console.error("Onboarding error:", error);
      toast.error("Fehler beim Speichern der Daten");
    }
  };

  const progress = ((currentStep + 1) / onboardingSteps.length) * 100;
  const step = onboardingSteps[currentStep];

  return (
    <div className="min-h-screen bg-gradient-to-b from-red-50 to-white p-6 flex items-center justify-center">
      <div className="max-w-2xl w-full space-y-6">
        {/* Progress */}
        <div>
          <Progress value={progress} className="h-3 mb-4" />
          <p className="text-sm text-gray-500 text-center">
            Schritt {currentStep + 1} von {onboardingSteps.length}
          </p>
        </div>

        {/* Content based on step type */}
        {step.type === 'info' && (
          <Card className="border-2 shadow-xl">
            <CardHeader className="text-center bg-gradient-to-r from-red-600 to-red-700 text-white">
              <CardTitle className="text-2xl">{step.title}</CardTitle>
              <p className="text-red-100">{step.subtitle}</p>
            </CardHeader>
            <CardContent className="pt-6 space-y-4">
              <Button
                onClick={speakStep}
                variant="outline"
                className="w-full"
                size="sm"
              >
                <Volume2 className="h-4 w-4 mr-2" />
                Anleitung vorlesen
              </Button>

              <div className="prose prose-sm max-w-none">
                {step.content.split('\n').map((line, i) => (
                  <p key={i} className="text-gray-700 mb-2">{line}</p>
                ))}
              </div>

              <Button onClick={handleNext} className="w-full" size="lg">
                Los geht's
                <ChevronRight className="h-5 w-5 ml-2" />
              </Button>
            </CardContent>
          </Card>
        )}

        {step.type === 'storage' && (
          <Card className="border-2 shadow-xl">
            <CardContent className="pt-6">
              <StorageModeSelector onSelected={handleStorageSelected} />
            </CardContent>
          </Card>
        )}

        {step.type === 'consent' && (
          <ConsentManager onComplete={handleConsentComplete} />
        )}

        {step.type === 'form' && (
          <Card className="border-2 shadow-xl">
            <CardHeader className="text-center">
              <CardTitle className="text-2xl">{step.title}</CardTitle>
              <p className="text-gray-600">{step.subtitle}</p>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button
                onClick={speakStep}
                variant="outline"
                className="w-full"
                size="sm"
              >
                <Volume2 className="h-4 w-4 mr-2" />
                Anleitung vorlesen
              </Button>

              {step.fields.map((field) => (
                <div key={field.name}>
                  <Label>{field.label} {field.required && <span className="text-red-600">*</span>}</Label>
                  {field.type === "select" ? (
                    <select
                      className="w-full p-3 border-2 rounded-md mt-1"
                      value={formData[field.name] || ""}
                      onChange={(e) => setFormData({ ...formData, [field.name]: e.target.value })}
                    >
                      <option value="">Bitte wählen</option>
                      {field.options.map(opt => (
                        <option key={opt} value={opt}>{opt}</option>
                      ))}
                    </select>
                  ) : (
                    <div className="flex gap-2 mt-1">
                      <Input
                        type={field.type}
                        value={formData[field.name] || ""}
                        onChange={(e) => setFormData({ ...formData, [field.name]: e.target.value })}
                        placeholder={field.placeholder || field.label}
                        className="text-lg h-12"
                      />
                      {field.type === "text" && (
                        <Button
                          onClick={() => startVoiceInput(field.name)}
                          variant="outline"
                          size="icon"
                          disabled={isListening}
                          className="h-12 w-12"
                        >
                          <Mic className={`h-5 w-5 ${isListening ? 'animate-pulse text-red-500' : ''}`} />
                        </Button>
                      )}
                    </div>
                  )}
                </div>
              ))}

              <div className="pt-4 space-y-2">
                <Button onClick={handleNext} className="w-full h-12" size="lg">
                  Weiter
                  <ChevronRight className="h-5 w-5 ml-2" />
                </Button>
                {currentStep > 0 && (
                  <Button
                    onClick={() => setCurrentStep(currentStep - 1)}
                    variant="outline"
                    className="w-full"
                  >
                    Zurück
                  </Button>
                )}
              </div>

              <p className="text-xs text-center text-gray-500 pt-4">
                {step.fields.some(f => f.required) ? 'Pflichtfelder sind mit * markiert' : 'Optional - '} Sie können diese Informationen später jederzeit ändern
              </p>
            </CardContent>
          </Card>
        )}

        {step.type === 'completion' && (
          <Card className="border-2 shadow-xl border-green-200 bg-green-50">
            <CardHeader className="text-center">
              <div className="h-20 w-20 rounded-full bg-green-600 flex items-center justify-center mx-auto mb-4">
                <CheckCircle className="h-12 w-12 text-white" />
              </div>
              <CardTitle className="text-2xl text-green-900">{step.title}</CardTitle>
              <p className="text-green-700">{step.subtitle}</p>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button
                onClick={speakStep}
                variant="outline"
                className="w-full"
                size="sm"
              >
                <Volume2 className="h-4 w-4 mr-2" />
                Anleitung vorlesen
              </Button>

              <div className="bg-white rounded-lg p-4 border-2 border-green-200">
                {step.content.split('\n').filter(l => l.trim()).map((line, i) => (
                  <p key={i} className="text-gray-700 mb-2">{line}</p>
                ))}
              </div>

              <Button onClick={completeOnboarding} className="w-full h-14 bg-green-600 hover:bg-green-700" size="lg">
                <CheckCircle className="h-5 w-5 mr-2" />
                Zur Startseite
              </Button>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}