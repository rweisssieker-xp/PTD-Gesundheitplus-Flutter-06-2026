import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { base44 } from "@/api/base44Client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { AlertTriangle, CheckCircle, ShieldAlert, RefreshCw, ChevronDown, ChevronUp } from "lucide-react";
import { toast } from "sonner";

const SEVERITY_CONFIG = {
  contraindicated: { label: "Kontraindiziert", color: "bg-red-100 text-red-800 border-red-300", icon: "🚫" },
  major: { label: "Schwerwiegend", color: "bg-red-50 text-red-700 border-red-200", icon: "⛔" },
  moderate: { label: "Moderat", color: "bg-orange-50 text-orange-700 border-orange-200", icon: "⚠️" },
  minor: { label: "Gering", color: "bg-yellow-50 text-yellow-700 border-yellow-200", icon: "ℹ️" },
  unknown: { label: "Unbekannt", color: "bg-gray-50 text-gray-700 border-gray-200", icon: "❓" },
};

export default function AllergyMedicationCheck({ newMedicationName = null }) {
  const entities = useEntities();
  const [checkResult, setCheckResult] = useState(null);
  const [isChecking, setIsChecking] = useState(false);
  const [expanded, setExpanded] = useState(true);

  const { data: allergies = [] } = useQuery({
    queryKey: ['allergies'],
    queryFn: () => entities.Allergy.list('-created_date'),
  });

  const { data: medications = [] } = useQuery({
    queryKey: ['medications'],
    queryFn: () => entities.Medication.list('-created_date'),
  });

  const activeMeds = medications.filter(m => m.active !== false);
  const medNames = newMedicationName
    ? [...new Set([...activeMeds.map(m => m.name), newMedicationName])]
    : activeMeds.map(m => m.name);

  const allergyNames = allergies
    .filter(a => a.category === "Medikament")
    .map(a => a.allergen);

  const runCheck = async () => {
    if (medNames.length === 0 && allergyNames.length === 0) {
      toast.info("Keine Medikamente oder Medikamenten-Allergien vorhanden.");
      return;
    }
    setIsChecking(true);
    setExpanded(true);
    try {
      const prompt = `
Du bist ein medizinischer Fachassistent. Analysiere folgende Kombination:

Aktive Medikamente: ${medNames.length > 0 ? medNames.join(", ") : "keine"}
Bekannte Medikamenten-Allergien: ${allergyNames.length > 0 ? allergyNames.join(", ") : "keine"}
${newMedicationName ? `\nNEU HINZUGEFÜGTES Medikament: "${newMedicationName}" — prüfe besonders dieses!` : ""}

Prüfe:
1. Wechselwirkungen zwischen den Medikamenten untereinander
2. Kreuzreaktionen zwischen Medikamenten und den Allergien
3. Kontraindikationen

Antworte NUR mit JSON:
{
  "interactions": [
    {
      "drug1": "...",
      "drug2": "...",
      "severity": "contraindicated|major|moderate|minor|unknown",
      "description": "kurze Erklärung auf Deutsch",
      "recommendation": "kurze Empfehlung auf Deutsch"
    }
  ],
  "allergy_conflicts": [
    {
      "medication": "...",
      "allergen": "...",
      "severity": "contraindicated|major|moderate|minor",
      "description": "kurze Erklärung auf Deutsch",
      "recommendation": "kurze Empfehlung auf Deutsch"
    }
  ],
  "overall_risk": "low|moderate|high|critical",
  "summary": "Zusammenfassung auf Deutsch in 1-2 Sätzen"
}

Nur klinisch relevante Wechselwirkungen aufführen, keine Kleinigkeiten.`;

      const result = await base44.integrations.Core.InvokeLLM({
        prompt,
        response_json_schema: {
          type: "object",
          properties: {
            interactions: { type: "array", items: { type: "object" } },
            allergy_conflicts: { type: "array", items: { type: "object" } },
            overall_risk: { type: "string" },
            summary: { type: "string" },
          },
        },
      });

      setCheckResult(result);

      // Save to DrugInteractionCheck entity
      const hasWarnings =
        result.interactions?.length > 0 || result.allergy_conflicts?.length > 0;
      if (hasWarnings) {
        await entities.Notification.create({
          title: newMedicationName
            ? `⚠️ Neues Medikament: Wechselwirkung gefunden`
            : `⚠️ Medikamenten-Check: Wechselwirkungen gefunden`,
          message: result.summary,
          type: "warning",
          read: false,
          priority: result.overall_risk === "critical" || result.overall_risk === "high" ? "high" : "medium",
        });
        toast.warning("Wechselwirkungen gefunden – bitte prüfen!");
      } else {
        toast.success("Keine relevanten Wechselwirkungen gefunden.");
      }
    } catch (e) {
      toast.error("Fehler bei der Prüfung. Bitte erneut versuchen.");
    } finally {
      setIsChecking(false);
    }
  };

  const riskColors = {
    low: "bg-green-100 text-green-800 border-green-300",
    moderate: "bg-yellow-100 text-yellow-800 border-yellow-300",
    high: "bg-orange-100 text-orange-800 border-orange-300",
    critical: "bg-red-100 text-red-800 border-red-300",
  };
  const riskLabels = { low: "Kein Risiko", moderate: "Moderates Risiko", high: "Hohes Risiko", critical: "Kritisch" };

  const totalWarnings = (checkResult?.interactions?.length ?? 0) + (checkResult?.allergy_conflicts?.length ?? 0);

  return (
    <Card className={`border-2 ${checkResult && totalWarnings > 0 ? "border-orange-400" : "border-gray-200"}`}>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShieldAlert className={`h-5 w-5 ${checkResult && totalWarnings > 0 ? "text-orange-500" : "text-gray-500"}`} />
            <CardTitle className="text-base">
              Allergie & Wechselwirkungs-Check
              {newMedicationName && (
                <span className="ml-2 text-sm font-normal text-orange-600">
                  — neu: „{newMedicationName}"
                </span>
              )}
            </CardTitle>
          </div>
          <div className="flex items-center gap-2">
            {checkResult && (
              <button onClick={() => setExpanded(e => !e)} className="text-gray-400 hover:text-gray-700">
                {expanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
              </button>
            )}
            <Button
              size="sm"
              onClick={runCheck}
              disabled={isChecking}
              className="bg-blue-600 hover:bg-blue-700 text-white"
            >
              {isChecking ? (
                <RefreshCw className="h-4 w-4 animate-spin mr-1" />
              ) : (
                <ShieldAlert className="h-4 w-4 mr-1" />
              )}
              {isChecking ? "Prüfe..." : "Jetzt prüfen"}
            </Button>
          </div>
        </div>
        <p className="text-xs text-gray-500 mt-1">
          {medNames.length} Medikament(e) · {allergyNames.length} Medikamenten-Allergie(n)
        </p>
      </CardHeader>

      {checkResult && expanded && (
        <CardContent className="pt-0 space-y-4">
          {/* Overall Risk */}
          <div className={`flex items-center gap-2 px-3 py-2 rounded-lg border ${riskColors[checkResult.overall_risk] || riskColors.low}`}>
            {totalWarnings === 0 ? (
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0" />
            ) : (
              <AlertTriangle className="h-5 w-5 flex-shrink-0" />
            )}
            <div>
              <p className="font-semibold text-sm">{riskLabels[checkResult.overall_risk] ?? "Unbekannt"}</p>
              <p className="text-xs">{checkResult.summary}</p>
            </div>
          </div>

          {/* Allergy Conflicts */}
          {checkResult.allergy_conflicts?.length > 0 && (
            <div>
              <h4 className="text-sm font-semibold text-red-700 mb-2 flex items-center gap-1">
                <AlertTriangle className="h-4 w-4" /> Allergie-Konflikte ({checkResult.allergy_conflicts.length})
              </h4>
              <div className="space-y-2">
                {checkResult.allergy_conflicts.map((c, i) => {
                  const sev = SEVERITY_CONFIG[c.severity] || SEVERITY_CONFIG.unknown;
                  return (
                    <div key={i} className={`p-3 rounded-lg border text-sm ${sev.color}`}>
                      <div className="flex items-center gap-2 font-semibold mb-1">
                        <span>{sev.icon}</span>
                        <span>{c.medication}</span>
                        <span className="text-xs font-normal">↔ Allergen: {c.allergen}</span>
                        <Badge variant="outline" className={`ml-auto text-xs ${sev.color}`}>{sev.label}</Badge>
                      </div>
                      <p className="text-xs">{c.description}</p>
                      {c.recommendation && (
                        <p className="text-xs mt-1 font-medium">→ {c.recommendation}</p>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Drug Interactions */}
          {checkResult.interactions?.length > 0 && (
            <div>
              <h4 className="text-sm font-semibold text-orange-700 mb-2 flex items-center gap-1">
                <AlertTriangle className="h-4 w-4" /> Medikamenten-Wechselwirkungen ({checkResult.interactions.length})
              </h4>
              <div className="space-y-2">
                {checkResult.interactions.map((c, i) => {
                  const sev = SEVERITY_CONFIG[c.severity] || SEVERITY_CONFIG.unknown;
                  return (
                    <div key={i} className={`p-3 rounded-lg border text-sm ${sev.color}`}>
                      <div className="flex items-center gap-2 font-semibold mb-1">
                        <span>{sev.icon}</span>
                        <span>{c.drug1}</span>
                        <span className="text-xs font-normal">↔ {c.drug2}</span>
                        <Badge variant="outline" className={`ml-auto text-xs ${sev.color}`}>{sev.label}</Badge>
                      </div>
                      <p className="text-xs">{c.description}</p>
                      {c.recommendation && (
                        <p className="text-xs mt-1 font-medium">→ {c.recommendation}</p>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {totalWarnings === 0 && (
            <div className="flex items-center gap-2 text-green-700 text-sm">
              <CheckCircle className="h-4 w-4" />
              Keine klinisch relevanten Wechselwirkungen oder Allergie-Konflikte gefunden.
            </div>
          )}

          <p className="text-xs text-gray-400 border-t pt-2">
            ⚕️ Diese Prüfung ersetzt keine ärztliche Beratung. Bei Unsicherheit bitte Arzt oder Apotheke kontaktieren.
          </p>
        </CardContent>
      )}

      {!checkResult && (
        <CardContent className="pt-0">
          <p className="text-xs text-gray-400">
            Klicken Sie auf „Jetzt prüfen", um Ihre Medikamente automatisch auf Wechselwirkungen und Allergie-Konflikte zu analysieren.
          </p>
        </CardContent>
      )}
    </Card>
  );
}