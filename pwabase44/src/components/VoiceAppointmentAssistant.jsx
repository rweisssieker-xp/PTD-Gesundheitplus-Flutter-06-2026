import React, { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Mic, MicOff, Volume2, Calendar, Send, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";
import MessageBubble from "./MessageBubble";

export default function VoiceAppointmentAssistant({ onAppointmentChanged }) {
  const [conversationId, setConversationId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [isListening, setIsListening] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [transcript, setTranscript] = useState("");

  useEffect(() => {
    initializeConversation();
  }, []);

  useEffect(() => {
    if (!conversationId) return;

    const unsubscribe = base44.agents.subscribeToConversation(conversationId, (data) => {
      setMessages(data.messages);
      setIsProcessing(false);
      
      // Auto-speak assistant responses
      const lastMessage = data.messages[data.messages.length - 1];
      if (lastMessage?.role === 'assistant' && lastMessage?.content) {
        speakText(lastMessage.content);
      }
    });

    return () => unsubscribe();
  }, [conversationId]);

  const initializeConversation = async () => {
    try {
      const conversation = await base44.agents.createConversation({
        agent_name: "appointment_assistant",
        metadata: {
          name: "Termin-Assistent Gespräch",
          description: "Sprachgesteuerte Terminverwaltung"
        }
      });
      setConversationId(conversation.id);
      
      // Welcome message
      const welcomeMsg = "Hallo! Ich bin Ihr Termin-Assistent. Sie können mir sagen: 'Ich möchte einen Termin vereinbaren', 'Zeige meine Termine' oder 'Ich muss einen Termin verschieben'. Wie kann ich Ihnen helfen?";
      speakText(welcomeMsg);
    } catch (error) {
      toast.error("Fehler beim Starten des Assistenten");
      console.error(error);
    }
  };

  const speakText = (text) => {
    if (!('speechSynthesis' in window)) return;
    
    window.speechSynthesis.cancel();
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
      await sendMessage(spokenText);
    };

    recognition.onerror = (event) => {
      setIsListening(false);
      toast.error("Spracherkennung fehlgeschlagen");
      console.error(event.error);
    };

    recognition.onend = () => {
      setIsListening(false);
    };

    recognition.start();
  };

  const sendMessage = async (text) => {
    if (!conversationId || !text.trim()) return;

    setIsProcessing(true);
    setTranscript("");

    try {
      const conversation = await base44.agents.getConversation(conversationId);
      await base44.agents.addMessage(conversation, {
        role: "user",
        content: text
      });
      
      // Notify parent that appointments might have changed
      if (onAppointmentChanged) {
        setTimeout(() => onAppointmentChanged(), 2000);
      }
    } catch (error) {
      setIsProcessing(false);
      toast.error("Fehler beim Senden der Nachricht");
      console.error(error);
    }
  };

  const stopSpeaking = () => {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      setIsSpeaking(false);
    }
  };

  return (
    <Card className="border-2 bg-gradient-to-br from-purple-50 to-indigo-50">
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          <Calendar className="h-5 w-5" />
          KI Termin-Assistent (Sprache)
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-gray-600">
          Sagen Sie z.B.: "Ich möchte einen Termin bei Dr. Schmidt vereinbaren" oder "Zeige meine nächsten Termine"
        </p>

        {/* Messages */}
        {messages.length > 0 && (
          <div className="max-h-64 overflow-y-auto space-y-3 p-3 bg-white rounded-lg border">
            {messages.map((msg, idx) => (
              <MessageBubble key={idx} message={msg} />
            ))}
          </div>
        )}

        {/* Transcript Display */}
        {transcript && (
          <div className="p-3 bg-blue-50 rounded-lg border-2 border-blue-200">
            <p className="text-sm font-semibold text-blue-900 mb-1">Sie haben gesagt:</p>
            <p className="text-sm text-gray-900">{transcript}</p>
          </div>
        )}

        {/* Controls */}
        <div className="flex gap-2">
          <Button
            onClick={startListening}
            disabled={isListening || isSpeaking || isProcessing}
            className={`flex-1 h-16 ${
              isListening 
                ? 'bg-red-600 hover:bg-red-700 animate-pulse' 
                : 'bg-gradient-to-r from-purple-500 to-indigo-500 hover:from-purple-600 hover:to-indigo-600'
            }`}
          >
            {isListening ? (
              <>
                <MicOff className="h-6 w-6 mr-2" />
                Zuhören...
              </>
            ) : isProcessing ? (
              <>
                <Loader2 className="h-6 w-6 mr-2 animate-spin" />
                Verarbeite...
              </>
            ) : (
              <>
                <Mic className="h-6 w-6 mr-2" />
                Sprechen
              </>
            )}
          </Button>
          
          {isSpeaking && (
            <Button
              onClick={stopSpeaking}
              variant="outline"
              size="icon"
              className="h-16 w-16"
            >
              <Volume2 className="h-6 w-6 animate-pulse" />
            </Button>
          )}
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-2">
          <Button
            onClick={() => sendMessage("Zeige meine nächsten Termine")}
            variant="outline"
            size="sm"
            disabled={isProcessing}
          >
            Meine Termine
          </Button>
          <Button
            onClick={() => sendMessage("Ich möchte einen Termin vereinbaren")}
            variant="outline"
            size="sm"
            disabled={isProcessing}
          >
            Neuer Termin
          </Button>
        </div>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-xs text-blue-800">
            <strong>Tipp:</strong> Der Assistent prüft automatisch Verfügbarkeiten und Konflikte mit bestehenden Terminen.
          </p>
        </div>
      </CardContent>
    </Card>
  );
}