import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Mic, MicOff } from "lucide-react";
import { toast } from "sonner";

export default function VoiceInput({ onResult, buttonText = "Spracheingabe" }) {
  const [isListening, setIsListening] = useState(false);

  const startListening = () => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      toast.error("Spracherkennung wird von Ihrem Browser nicht unterstützt");
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
      onResult(transcript);
      toast.success("Spracheingabe erfolgreich");
    };

    recognition.onerror = (event) => {
      setIsListening(false);
      toast.error("Spracherkennung fehlgeschlagen");
    };

    recognition.onend = () => {
      setIsListening(false);
    };

    recognition.start();
  };

  return (
    <Button
      type="button"
      variant={isListening ? "destructive" : "outline"}
      onClick={startListening}
      disabled={isListening}
      className="w-full"
    >
      {isListening ? (
        <>
          <MicOff className="h-5 w-5 mr-2 animate-pulse" />
          Zuhören...
        </>
      ) : (
        <>
          <Mic className="h-5 w-5 mr-2" />
          {buttonText}
        </>
      )}
    </Button>
  );
}