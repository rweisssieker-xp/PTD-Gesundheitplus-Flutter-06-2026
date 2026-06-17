import React, { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Volume2, VolumeX } from "lucide-react";
import { toast } from "sonner";

export default function VoiceNavigation({ content, autoSpeak = false }) {
  const [isSpeaking, setIsSpeaking] = useState(false);

  useEffect(() => {
    if (autoSpeak && content) {
      speakContent();
    }
  }, [autoSpeak, content]);

  const speakContent = () => {
    if (!('speechSynthesis' in window)) {
      toast.error("Sprachausgabe wird von Ihrem Browser nicht unterstützt");
      return;
    }

    if (isSpeaking) {
      window.speechSynthesis.cancel();
      setIsSpeaking(false);
      return;
    }

    const utterance = new SpeechSynthesisUtterance(content);
    utterance.lang = 'de-DE';
    utterance.rate = 0.9;
    utterance.pitch = 1;

    utterance.onstart = () => setIsSpeaking(true);
    utterance.onend = () => setIsSpeaking(false);
    utterance.onerror = () => {
      setIsSpeaking(false);
      toast.error("Fehler bei der Sprachausgabe");
    };

    window.speechSynthesis.speak(utterance);
  };

  return (
    <Button
      onClick={speakContent}
      variant={isSpeaking ? "destructive" : "outline"}
      size="icon"
      className="fixed bottom-24 right-6 h-14 w-14 rounded-full shadow-2xl z-50"
      title={isSpeaking ? "Stoppen" : "Seite vorlesen"}
    >
      {isSpeaking ? (
        <VolumeX className="h-6 w-6 animate-pulse" />
      ) : (
        <Volume2 className="h-6 w-6" />
      )}
    </Button>
  );
}