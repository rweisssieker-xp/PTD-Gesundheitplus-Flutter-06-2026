import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";
import { Globe, ArrowRight, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";

const languages = [
  { code: "de", name: "Deutsch" },
  { code: "en", name: "English" },
  { code: "tr", name: "Türkçe" },
  { code: "ar", name: "العربية" },
  { code: "fr", name: "Français" },
  { code: "es", name: "Español" },
  { code: "pl", name: "Polski" },
  { code: "ru", name: "Русский" }
];

export default function MultilingualInput({ onTranslated, placeholder = "Text eingeben..." }) {
  const [inputText, setInputText] = useState("");
  const [selectedLanguage, setSelectedLanguage] = useState("de");
  const [isTranslating, setIsTranslating] = useState(false);
  const [translatedText, setTranslatedText] = useState("");

  const translateText = async () => {
    if (!inputText.trim()) {
      toast.error("Bitte Text eingeben");
      return;
    }

    if (selectedLanguage === "de") {
      onTranslated(inputText);
      toast.success("Text übernommen");
      return;
    }

    setIsTranslating(true);

    try {
      const result = await base44.integrations.Core.InvokeLLM({
        prompt: `Übersetze folgenden Text aus ${languages.find(l => l.code === selectedLanguage)?.name} ins Deutsche. Gib nur die Übersetzung zurück, ohne zusätzliche Erklärungen: "${inputText}"`,
        response_json_schema: {
          type: "object",
          properties: {
            translation: { type: "string" }
          }
        }
      });

      if (result.translation) {
        setTranslatedText(result.translation);
        onTranslated(result.translation);
        toast.success("Text übersetzt und übernommen");
      }
    } catch (error) {
      toast.error("Fehler bei der Übersetzung");
      console.error(error);
    } finally {
      setIsTranslating(false);
    }
  };

  return (
    <Card className="border-2 bg-gradient-to-br from-indigo-50 to-purple-50">
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          <Globe className="h-5 w-5" />
          Mehrsprachige Eingabe
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <label className="text-sm font-semibold text-gray-700 mb-2 block">
            Sprache auswählen:
          </label>
          <div className="grid grid-cols-4 gap-2">
            {languages.map((lang) => (
              <Button
                key={lang.code}
                onClick={() => setSelectedLanguage(lang.code)}
                variant={selectedLanguage === lang.code ? "default" : "outline"}
                size="sm"
                className={selectedLanguage === lang.code ? "bg-indigo-600" : ""}
              >
                {lang.name}
              </Button>
            ))}
          </div>
        </div>

        <div>
          <label className="text-sm font-semibold text-gray-700 mb-2 block">
            Text in {languages.find(l => l.code === selectedLanguage)?.name}:
          </label>
          <Textarea
            placeholder={placeholder}
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            rows={4}
            className="resize-none"
          />
        </div>

        {translatedText && (
          <div className="p-3 bg-white rounded-lg border-2 border-green-200">
            <p className="text-sm font-semibold text-gray-700 mb-1">
              Deutsche Übersetzung:
            </p>
            <p className="text-gray-900">{translatedText}</p>
          </div>
        )}

        <Button
          onClick={translateText}
          disabled={isTranslating || !inputText.trim()}
          className="w-full bg-indigo-600 hover:bg-indigo-700"
        >
          {isTranslating ? (
            <>
              <Loader2 className="h-5 w-5 mr-2 animate-spin" />
              Übersetze...
            </>
          ) : (
            <>
              {selectedLanguage === "de" ? "Übernehmen" : "Übersetzen"}
              <ArrowRight className="h-5 w-5 ml-2" />
            </>
          )}
        </Button>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-xs text-blue-800">
            <strong>Info:</strong> Sie können Informationen in Ihrer Muttersprache eingeben. 
            Die App übersetzt automatisch ins Deutsche.
          </p>
        </div>
      </CardContent>
    </Card>
  );
}