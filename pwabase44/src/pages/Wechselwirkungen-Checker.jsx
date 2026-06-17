import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Pill,
  AlertTriangle,
  CheckCircle,
  AlertCircle,
  Loader2,
  ShieldAlert,
  Info,
  Brain,
  RefreshCw,
  Ban,
  Activity
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { formatDistanceToNow } from "date-fns";
import { de } from "date-fns/locale";

const SEVERITY_CONFIG = {
  contraindicated: {
    label: "Kontraindiziert",
    color: "bg-red-100 text-red-900 border-red-300",
    cardBorder: "border-red-300",
    cardBg: "bg-red-50",
    icon: Ban,
    iconColor: "text-red-600"
  },
  major: {
    label: "Schwerwiegend",
    color: "bg-orange-100 text-orange-900 border-orange-300",
    cardBorder: "border-orange-300",
    cardBg: "bg-orange-50",
    icon: AlertTriangle,
    iconColor: "text-orange-600"
  },
  moderate: {
    label: "Mäßig",
    color: "bg-yellow-100 text-yellow-900 border-yellow-300",
    cardBorder: "border-yellow-300",
    cardBg: "bg-yellow-50",
    icon: AlertCircle,
    iconColor: "text-yellow-600"
  },
  minor: {
    label: "Gering",
    color: "bg-blue-100 text-blue-900 border-blue-300",
    cardBorder: "border-blue-200",
    cardBg: "bg-blue-50",
    icon: Info,
    iconColor: "text-blue-600"
  },
  unknown: {
    label: "Unbekannt",
    color: "bg-gray-100 text-gray-900 border-gray-300",
    cardBorder: "border-gray-200",
    cardBg: "bg-gray-50",
    icon: Info,
    iconColor: "text-gray-600"
  }
};

const RISK_COLORS = {
  low: "bg-green-100 text-green-800 border-green-200",
  moderate: "bg-yellow-100 text-yellow-800 border-yellow-200",
  high: "bg-orange-100 text-orange-800 border-orange-200",
  critical: "bg-red-100 text-red-800 border-red-200"
};

export default function WechselwirkungenCheckerPage() {
  const queryClient = useQueryClient();
  const [selectedMeds, setSelectedMeds] = useState([]);
  const [isChecking, setIsChecking] = useState(false);
  const [result, setResult] = useState(null);

  const { data: medications = [] } = useQuery({
    queryKey: ["active-medications-icheck"],
    queryFn: () => base44.entities.Medication.filter({ active: true })
  });

  const { data: lastChecks = [] } = useQuery({
    queryKey: ["drug-interaction-checks"],
    queryFn: () => base44.entities.DrugInteractionCheck.list("-checked_at", 5)
  });

  useEffect(() => {
    // Auto-select all active medications
    if (medications.length > 0) {
      setSelectedMeds(medications.map(m => m.name));
    }
  }, [medications]);

  const saveMutation = useMutation({
    mutationFn: (data) => base44.entities.DrugInteractionCheck.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["drug-interaction-checks"] });
    }
  });

  const handleCheck = async () => {
    if (selectedMeds.length < 2) {
      toast.error("Mindestens 2 Medikamente für die Prüfung erforderlich");
      return;
    }

    setIsChecking(true);
    setResult(null);

    try {
      toast.info("KI prüft Wechselwirkungen...", { description: "Nutzt pharmazeutisches Fachwissen" });

      const prompt = `Du bist ein klinischer Pharmakologe. Analysiere die Wechselwirkungen zwischen folgenden Medikamenten:

Medikamentenliste: ${selectedMeds.join(", ")}

Überprüfe ALLE möglichen Paarungskombinationen auf klinisch relevante Wechselwirkungen.

Bewerte jede Interaktion nach Schweregrad:
- contraindicated: Absolute Kontraindikation, nicht gleichzeitig verwenden
- major: Schwerwiegend, medizinische Überwachung nötig
- moderate: Mäßig, Vorsicht empfohlen
- minor: Gering, meistens gut verträglich

Gib nur real bekannte, klinisch dokumentierte Interaktionen an. Wenn keine Interaktion bekannt ist, gib keine erfundene an.

Antworte ausschließlich auf Deutsch.`;

      const schema = {
        type: "object",
        properties: {
          summary: { type: "string" },
          overall_risk: { type: "string", enum: ["low", "moderate", "high", "critical"] },
          interactions_found: {
            type: "array",
            items: {
              type: "object",
              properties: {
                drug1: { type: "string" },
                drug2: { type: "string" },
                severity: { type: "string", enum: ["contraindicated", "major", "moderate", "minor", "unknown"] },
                description: { type: "string" },
                recommendation: { type: "string" }
              },
              required: ["drug1", "drug2", "severity", "description", "recommendation"]
            }
          }
        },
        required: ["summary", "overall_risk", "interactions_found"]
      };

      const aiResult = await base44.integrations.Core.InvokeLLM({
        prompt,
        response_json_schema: schema,
        model: "claude_sonnet_4_6"
      });

      const checkData = {
        ...aiResult,
        medications_checked: selectedMeds,
        checked_at: new Date().toISOString()
      };

      setResult(checkData);
      saveMutation.mutate(checkData);

      if (aiResult.interactions_found?.length === 0) {
        toast.success("Keine bekannten Wechselwirkungen gefunden");
      } else {
        const criticalCount = aiResult.interactions_found?.filter(
          i => i.severity === "contraindicated" || i.severity === "major"
        ).length;
        if (criticalCount > 0) {
          toast.error(`${criticalCount} schwerwiegende Wechselwirkung(en) gefunden!`);
        } else {
          toast.warning(`${aiResult.interactions_found.length} Wechselwirkung(en) gefunden`);
        }
      }
    } catch (error) {
      console.error("Interaction check error:", error);
      toast.error("Fehler bei der Prüfung: " + error.message);
    } finally {
      setIsChecking(false);
    }
  };

  const toggleMed = (name) => {
    setSelectedMeds(prev =>
      prev.includes(name) ? prev.filter(m => m !== name) : [...prev, name]
    );
    setResult(null);
  };

  return (
    <div className="p-6 space-y-6 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-1 flex items-center gap-2">
          <ShieldAlert className="h-7 w-7 text-orange-600" />
          Wechselwirkungs-Checker
        </h1>
        <p className="text-gray-600">KI-gestützter Pharma-Interaktions-Check mit medizinischem Fachwissen</p>
      </div>

      {/* Medication Selection */}
      <Card className="border-2 border-orange-200 bg-orange-50">
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <Pill className="h-5 w-5 text-orange-600" />
            Zu prüfende Medikamente ({selectedMeds.length} ausgewählt)
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {medications.length === 0 ? (
            <p className="text-sm text-gray-600 text-center py-4">
              Keine aktiven Medikamente hinterlegt. Bitte erst Medikamente in der Medikations-Verwaltung eintragen.
            </p>
          ) : (
            <div className="flex flex-wrap gap-2">
              {medications.map((med) => (
                <button
                  key={med.id}
                  onClick={() => toggleMed(med.name)}
                  className={`px-3 py-2 rounded-lg text-sm font-medium border-2 transition-all ${
                    selectedMeds.includes(med.name)
                      ? "bg-orange-600 text-white border-orange-600"
                      : "bg-white text-gray-700 border-gray-200 hover:border-orange-300"
                  }`}
                >
                  <Pill className="h-3 w-3 inline mr-1" />
                  {med.name}
                  {med.dosage && <span className="opacity-70 text-xs ml-1">({med.dosage})</span>}
                </button>
              ))}
            </div>
          )}

          <Button
            onClick={handleCheck}
            disabled={isChecking || selectedMeds.length < 2}
            className="w-full h-12 bg-orange-600 hover:bg-orange-700 text-white mt-2"
          >
            {isChecking ? (
              <>
                <Loader2 className="h-5 w-5 mr-2 animate-spin" />
                KI prüft Wechselwirkungen... (20-30s)
              </>
            ) : (
              <>
                <Brain className="h-5 w-5 mr-2" />
                Wechselwirkungen prüfen ({selectedMeds.length} Medikamente)
              </>
            )}
          </Button>
          {selectedMeds.length < 2 && medications.length >= 2 && (
            <p className="text-xs text-center text-gray-500">Mindestens 2 Medikamente auswählen</p>
          )}
        </CardContent>
      </Card>

      {/* Result */}
      {result && (
        <div className="space-y-4">
          {/* Overall Risk */}
          <Card className={`border-2 ${RISK_COLORS[result.overall_risk] || RISK_COLORS.low}`}>
            <CardContent className="pt-5 pb-5">
              <div className="flex items-center gap-3">
                <Activity className="h-8 w-8" />
                <div>
                  <p className="text-sm font-semibold">Gesamt-Risikobewertung</p>
                  <p className="text-2xl font-bold uppercase">{
                    result.overall_risk === "low" ? "Niedrig" :
                    result.overall_risk === "moderate" ? "Mäßig" :
                    result.overall_risk === "high" ? "Hoch" : "Kritisch"
                  }</p>
                </div>
                <Badge className={`ml-auto text-sm px-3 py-1 ${RISK_COLORS[result.overall_risk]}`}>
                  {result.interactions_found?.length || 0} Interaktion(en)
                </Badge>
              </div>
            </CardContent>
          </Card>

          {/* Summary */}
          {result.summary && (
            <Card className="border-2 border-blue-200 bg-blue-50">
              <CardContent className="pt-5 pb-5">
                <div className="flex gap-3">
                  <Brain className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
                  <p className="text-sm text-blue-900">{result.summary}</p>
                </div>
              </CardContent>
            </Card>
          )}

          {/* No interactions */}
          {result.interactions_found?.length === 0 && (
            <Card className="border-2 border-green-200 bg-green-50">
              <CardContent className="py-8 text-center">
                <CheckCircle className="h-12 w-12 text-green-600 mx-auto mb-3" />
                <p className="font-semibold text-green-900">Keine bekannten Wechselwirkungen</p>
                <p className="text-sm text-green-700 mt-1">
                  Zwischen den geprüften Medikamenten wurden keine klinisch relevanten Interaktionen gefunden.
                </p>
              </CardContent>
            </Card>
          )}

          {/* Interactions List */}
          {result.interactions_found?.length > 0 && (
            <div className="space-y-3">
              <h3 className="font-semibold text-gray-900">Gefundene Wechselwirkungen</h3>
              {result.interactions_found
                .sort((a, b) => {
                  const order = { contraindicated: 0, major: 1, moderate: 2, minor: 3, unknown: 4 };
                  return (order[a.severity] ?? 5) - (order[b.severity] ?? 5);
                })
                .map((interaction, idx) => {
                  const cfg = SEVERITY_CONFIG[interaction.severity] || SEVERITY_CONFIG.unknown;
                  const Icon = cfg.icon;
                  return (
                    <Card key={idx} className={`border-2 ${cfg.cardBorder} ${cfg.cardBg}`}>
                      <CardContent className="pt-4 pb-4">
                        <div className="flex items-start gap-3">
                          <Icon className={`h-6 w-6 ${cfg.iconColor} flex-shrink-0 mt-0.5`} />
                          <div className="flex-1">
                            <div className="flex items-center gap-2 flex-wrap mb-2">
                              <span className="font-bold text-gray-900">{interaction.drug1}</span>
                              <span className="text-gray-500">+</span>
                              <span className="font-bold text-gray-900">{interaction.drug2}</span>
                              <Badge className={`text-xs ${cfg.color}`}>{cfg.label}</Badge>
                            </div>
                            <p className="text-sm text-gray-800 mb-2">{interaction.description}</p>
                            <div className="bg-white/70 p-3 rounded-lg border">
                              <p className="text-xs font-semibold text-gray-700 mb-1">Empfehlung:</p>
                              <p className="text-sm text-gray-800">{interaction.recommendation}</p>
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
            </div>
          )}
        </div>
      )}

      {/* Last Checks History */}
      {lastChecks.length > 0 && !result && (
        <div>
          <h3 className="font-semibold text-gray-900 mb-3">Letzte Prüfungen</h3>
          <div className="space-y-2">
            {lastChecks.map((check) => (
              <Card key={check.id} className="border border-gray-200 hover:shadow-md transition-shadow">
                <CardContent className="pt-3 pb-3">
                  <div className="flex items-center justify-between gap-2">
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {check.medications_checked?.join(", ")}
                      </p>
                      <p className="text-xs text-gray-500 mt-0.5">
                        {check.checked_at
                          ? formatDistanceToNow(new Date(check.checked_at), { addSuffix: true, locale: de })
                          : ""}
                      </p>
                    </div>
                    <Badge className={`text-xs ${RISK_COLORS[check.overall_risk] || RISK_COLORS.low}`}>
                      {check.interactions_found?.length || 0} Wechselwirkung(en)
                    </Badge>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* Disclaimer */}
      <Card className="border-2 border-gray-200 bg-gray-50">
        <CardContent className="pt-5 pb-5">
          <div className="flex gap-3">
            <Info className="h-5 w-5 text-gray-600 flex-shrink-0 mt-0.5" />
            <div className="text-xs text-gray-600">
              <p className="font-semibold text-gray-900 mb-1">Wichtiger Hinweis</p>
              <p>
                Diese Prüfung dient nur zur Orientierung und ersetzt nicht die Beratung durch einen Arzt oder Apotheker.
                Bei Bedenken wenden Sie sich bitte an Ihren behandelnden Arzt oder eine Apotheke.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}