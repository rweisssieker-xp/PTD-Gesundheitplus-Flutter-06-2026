/**
 * Health AI Chat Component
 * Interactive AI assistant for health questions and guidance
 */

import React, { useState, useRef, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { 
  Brain, 
  Send, 
  Loader2,
  Bot,
  User,
  Sparkles,
  X
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";

export default function HealthAIChat({ onClose }) {
  const [messages, setMessages] = useState([
    {
      role: 'assistant',
      content: 'Hallo! Ich bin Ihr KI-Gesundheitsassistent. Ich kann Ihnen Fragen zu Ihrer Gesundheit, Medikation und Ihrem Notfallprofil beantworten. Wie kann ich Ihnen helfen?',
      timestamp: new Date()
    }
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const scrollRef = useRef(null);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  };

  const collectContextData = async () => {
    try {
      const user = await base44.auth.me();
      
      const [medications, allergies, medicalHistory, appointments] = await Promise.all([
        base44.entities.Medication.filter({ active: true }).catch(() => []),
        base44.entities.Allergy.list().catch(() => []),
        base44.entities.MedicalHistory.list().catch(() => []),
        base44.entities.Appointment.list().catch(() => [])
      ]);

      const age = user.date_of_birth 
        ? Math.floor((new Date() - new Date(user.date_of_birth)) / 31557600000)
        : null;

      return {
        patient: {
          age: age,
          gender: user.gender || 'unbekannt',
          has_emergency_profile: !!user.emergency_profile
        },
        medications: medications.map(m => ({
          name: m.name,
          dosage: m.dosage,
          frequency: m.frequency,
          reason: m.reason
        })),
        allergies: allergies.map(a => ({
          allergen: a.allergen,
          severity: a.severity
        })),
        diagnoses: medicalHistory[0]?.diagnoses || [],
        upcoming_appointments: appointments
          .filter(a => new Date(a.date) > new Date())
          .slice(0, 3)
          .map(a => ({
            doctor: a.doctor_name,
            date: a.date,
            reason: a.reason
          }))
      };
    } catch (error) {
      console.error('Error collecting context:', error);
      return null;
    }
  };

  const sendMessage = async () => {
    if (!input.trim() || isLoading) return;

    const userMessage = {
      role: 'user',
      content: input,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      // Collect user's medical context
      const context = await collectContextData();

      // Prepare conversation history
      const conversationHistory = messages
        .slice(-5) // Last 5 messages for context
        .map(m => `${m.role === 'user' ? 'Patient' : 'Assistent'}: ${m.content}`)
        .join('\n');

      // Enhanced prompt with medical context
      const prompt = `Sie sind ein einfühlsamer KI-Gesundheitsassistent für den Patienten.

MEDIZINISCHER KONTEXT DES PATIENTEN:
${context ? JSON.stringify(context, null, 2) : 'Keine Daten verfügbar'}

GESPRÄCHSVERLAUF:
${conversationHistory}

NEUE FRAGE DES PATIENTEN:
${userMessage.content}

ANWEISUNGEN:
- Antworten Sie persönlich und einfühlsam
- Beziehen Sie sich auf die medizinischen Daten des Patienten, wenn relevant
- Geben Sie praktische, evidenzbasierte Ratschläge
- Weisen Sie bei ernsthaften Symptomen darauf hin, einen Arzt aufzusuchen
- Seien Sie klar und verständlich, vermeiden Sie Fachjargon
- Wenn Sie etwas nicht wissen, sagen Sie es ehrlich
- Bei Medikamentenfragen: Warnen Sie vor Eigenmacht, empfehlen Sie Rücksprache mit Arzt

WICHTIG: Sie ersetzen NICHT die medizinische Beratung durch einen Arzt!

Antworten Sie auf Deutsch, klar und hilfreich (max 200 Wörter):`;

      // Call AI
      const response = await base44.integrations.Core.InvokeLLM({
        prompt: prompt
      });

      const assistantMessage = {
        role: 'assistant',
        content: typeof response === 'string' ? response : response.response || 'Entschuldigung, ich konnte keine Antwort generieren.',
        timestamp: new Date()
      };

      setMessages(prev => [...prev, assistantMessage]);

    } catch (error) {
      console.error('Chat error:', error);
      toast.error('Fehler bei der KI-Anfrage');
      
      const errorMessage = {
        role: 'assistant',
        content: 'Entschuldigung, es gab einen technischen Fehler. Bitte versuchen Sie es erneut.',
        timestamp: new Date()
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const quickQuestions = [
    "Welche Medikamente nehme ich?",
    "Gibt es Interaktionen bei meinen Medikamenten?",
    "Was bedeuten meine Allergien?",
    "Welche Vorsorgeuntersuchungen sollte ich machen?",
    "Wie kann ich meine Gesundheit verbessern?"
  ];

  const handleQuickQuestion = (question) => {
    setInput(question);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-end sm:items-center justify-center p-0 sm:p-4">
      <Card className="w-full h-full sm:h-[600px] sm:max-w-2xl border-2 border-purple-200 rounded-none sm:rounded-xl flex flex-col">
        <CardHeader className="border-b bg-gradient-to-r from-purple-600 to-pink-600 text-white flex-shrink-0">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2 text-lg">
              <Brain className="h-6 w-6" />
              KI-Gesundheitsassistent
            </CardTitle>
            {onClose && (
              <Button
                variant="ghost"
                size="icon"
                onClick={onClose}
                className="text-white hover:bg-white/20"
              >
                <X className="h-5 w-5" />
              </Button>
            )}
          </div>
          <p className="text-xs text-purple-100 mt-1">
            Evidenzbasierte Gesundheitsberatung • Ersetzt keinen Arztbesuch
          </p>
        </CardHeader>

        {/* Messages Area */}
        <ScrollArea className="flex-1 p-4" ref={scrollRef}>
          <div className="space-y-4">
            {messages.map((message, index) => (
              <div
                key={index}
                className={`flex gap-3 ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                {message.role === 'assistant' && (
                  <div className="h-8 w-8 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center flex-shrink-0">
                    <Bot className="h-5 w-5 text-white" />
                  </div>
                )}
                
                <div className={`max-w-[80%] ${message.role === 'user' ? 'order-1' : ''}`}>
                  <div
                    className={`rounded-2xl px-4 py-3 ${
                      message.role === 'user'
                        ? 'bg-purple-600 text-white'
                        : 'bg-gray-100 text-gray-900'
                    }`}
                  >
                    <p className="text-sm whitespace-pre-wrap">{message.content}</p>
                  </div>
                  <p className="text-xs text-gray-500 mt-1 px-2">
                    {message.timestamp.toLocaleTimeString('de-DE', { 
                      hour: '2-digit', 
                      minute: '2-digit' 
                    })}
                  </p>
                </div>

                {message.role === 'user' && (
                  <div className="h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center flex-shrink-0">
                    <User className="h-5 w-5 text-white" />
                  </div>
                )}
              </div>
            ))}

            {isLoading && (
              <div className="flex gap-3 justify-start">
                <div className="h-8 w-8 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center flex-shrink-0">
                  <Bot className="h-5 w-5 text-white" />
                </div>
                <div className="bg-gray-100 rounded-2xl px-4 py-3">
                  <div className="flex items-center gap-2">
                    <Loader2 className="h-4 w-4 animate-spin text-purple-600" />
                    <span className="text-sm text-gray-600">KI denkt nach...</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </ScrollArea>

        {/* Quick Questions */}
        {messages.length <= 1 && (
          <div className="px-4 pb-2 border-t">
            <p className="text-xs text-gray-600 mb-2 flex items-center gap-1">
              <Sparkles className="h-3 w-3" />
              Schnellfragen:
            </p>
            <div className="flex gap-2 flex-wrap">
              {quickQuestions.slice(0, 3).map((question, index) => (
                <Button
                  key={index}
                  variant="outline"
                  size="sm"
                  onClick={() => handleQuickQuestion(question)}
                  className="text-xs h-7"
                >
                  {question}
                </Button>
              ))}
            </div>
          </div>
        )}

        {/* Input Area */}
        <div className="border-t p-4 bg-gray-50 flex-shrink-0">
          <div className="flex gap-2">
            <Input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Stellen Sie eine Frage zu Ihrer Gesundheit..."
              disabled={isLoading}
              className="flex-1 bg-white"
            />
            <Button
              onClick={sendMessage}
              disabled={!input.trim() || isLoading}
              className="bg-purple-600 hover:bg-purple-700"
            >
              {isLoading ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                <Send className="h-5 w-5" />
              )}
            </Button>
          </div>
          <p className="text-xs text-gray-500 mt-2 text-center">
            KI-generierte Antworten • Bei Notfällen: 112 anrufen
          </p>
        </div>
      </Card>
    </div>
  );
}