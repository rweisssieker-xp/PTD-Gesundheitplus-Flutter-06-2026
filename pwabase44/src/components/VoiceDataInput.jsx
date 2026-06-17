import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Mic, MicOff, Volume2, Check } from "lucide-react";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";

export default function VoiceDataInput({ onDataExtracted, entityType, promptText }) {
  const [isListening, setIsListening] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [transcript, setTranscript] = useState("");

  const speak = (text) => {
    if (!('speechSynthesis' in window)) return;
    
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'de-DE';
    utterance.rate = 0.9;
    utterance.onstart = () => setIsSpeaking(true);
    utterance.onend = () => setIsSpeaking(false);
    window.speechSynthesis.speak(utterance);
  };

  const startListening = () => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      toast.error("Spracherkennung wird nicht unterstützt");
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

    recognition.onresult = async (event) => {
      const spokenText = event.results[0][0].transcript;
      setTranscript(spokenText);
      setIsListening(false);
      
      toast.info("Text wird verarbeitet...");
      await processVoiceInput(spokenText);
    };

    recognition.onerror = () => {
      setIsListening(false);
      toast.error("Spracherkennung fehlgeschlagen");
    };

    recognition.onend = () => {
      setIsListening(false);
    };

    if (promptText) {
      speak(promptText);
      setTimeout(() => recognition.start(), 2000);
    } else {
      recognition.start();
    }
  };

  const processVoiceInput = async (text) => {
    try {
      const schemas = {
        medication: {
          type: "object",
          properties: {
            name: { type: "string" },
            dosage: { type: "string" },
            frequency: { type: "string" },
            prescribed_by: { type: "string" },
            reason: { type: "string" }
          }
        },
        doctor: {
          type: "object",
          properties: {
            name: { type: "string" },
            specialty: { type: "string" },
            address: { type: "string" },
            phone: { type: "string" }
          }
        },
        appointment: {
          type: "object",
          properties: {
            doctor_name: { type: "string" },
            date: { type: "string" },
            time: { type: "string" },
            reason: { type: "string" }
          }
        },
        allergy: {
          type: "object",
          properties: {
            allergen: { type: "string" },
            severity: { type: "string" },
            reaction: { type: "string" }
          }
        }
      };

      const schema = schemas[entityType] || schemas.medication;
      
      const result = await base44.integrations.Core.InvokeLLM({
        prompt: `Extrahiere strukturierte Daten aus folgendem gesprochenen Text: "${text}". 
        Gib die Informationen im angegebenen JSON-Format zurück. Falls Informationen fehlen, lasse die Felder leer.`,
        response_json_schema: schema
      });

      toast.success("Daten erfolgreich extrahiert!");
      onDataExtracted(result);
      setTranscript("");
    } catch (error) {
      toast.error("Fehler beim Verarbeiten der Spracheingabe");
      console.error(error);
    }
  };

  return (
    <Card className="border-2 bg-gradient-to-br from-purple-50 to-pink-50">
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          <Mic className="h-5 w-5" />
          Spracheingabe
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-gray-600">
          Beschreiben Sie die Informationen per Sprache. Die App extrahiert automatisch die relevanten Daten.
        </p>

        {transcript && (
          <div className="p-3 bg-white rounded-lg border-2 border-gray-200">
            <p className="text-sm font-semibold text-gray-700 mb-1">Ihr Text:</p>
            <p className="text-sm text-gray-900">{transcript}</p>
          </div>
        )}

        <div className="flex gap-2">
          <Button
            onClick={startListening}
            disabled={isListening || isSpeaking}
            className={`flex-1 h-16 ${isListening ? 'bg-red-600 hover:bg-red-700' : 'bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600'}`}
          >
            {isListening ? (
              <>
                <MicOff className="h-6 w-6 mr-2 animate-pulse" />
                Zuhören...
              </>
            ) : isSpeaking ? (
              <>
                <Volume2 className="h-6 w-6 mr-2 animate-pulse" />
                Spreche...
              </>
            ) : (
              <>
                <Mic className="h-6 w-6 mr-2" />
                Spracheingabe starten
              </>
            )}
          </Button>
        </div>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-xs text-blue-800">
            <strong>Beispiel:</strong> "Ich nehme Aspirin 100mg einmal täglich morgens, verschrieben von Dr. Müller wegen Herzproblemen"
          </p>
        </div>
      </CardContent>
    </Card>
  );
}