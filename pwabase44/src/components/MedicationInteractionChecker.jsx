/**
 * Medication Interaction Checker
 * Prüft Wechselwirkungen zwischen Medikamenten in Echtzeit
 */

import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  AlertTriangle,
  AlertCircle,
  Info,
  CheckCircle,
  Loader2,
  X,
  RefreshCw
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";
import { motion, AnimatePresence } from "framer-motion";

const SEVERITY_CONFIG = {
  critical: {
    icon: AlertTriangle,
    color: "text-red-600",
    bgColor: "bg-red-50",
    borderColor: "border-red-300",
    badgeColor: "bg-red-600"
  },
  major: {
    icon: AlertCircle,
    color: "text-orange-600",
    bgColor: "bg-orange-50",
    borderColor: "border-orange-300",
    badgeColor: "bg-orange-600"
  },
  moderate: {
    icon: Info,
    color: "text-yellow-600",
    bgColor: "bg-yellow-50",
    borderColor: "border-yellow-300",
    badgeColor: "bg-yellow-600"
  },
  minor: {
    icon: Info,
    color: "text-blue-600",
    bgColor: "bg-blue-50",
    borderColor: "border-blue-300",
    badgeColor: "bg-blue-600"
  }
};

export default function MedicationInteractionChecker({ 
  medications = [], 
  newMedication = null,
  onClose,
  autoCheck = true 
}) {
  const [isChecking, setIsChecking] = useState(false);
  const [interactions, setInteractions] = useState(null);
  const [lastChecked, setLastChecked] = useState(null);

  React.useEffect(() => {
    if (autoCheck && medications.length > 0) {
      checkInteractions();
    }
  }, [medications, newMedication, autoCheck]);

  const checkInteractions = async () => {
    if (medications.length === 0 && !newMedication) {
      toast.info("Keine Medikamente zum Prüfen vorhanden");
      return;
    }

    setIsChecking(true);
    setInteractions(null);

    try {
      const medList = newMedication 
        ? [...medications, newMedication]
        : medications;

      const activeMeds = medList.filter(m => m.active !== false);

      if (activeMeds.length < 2) {
        setInteractions({
          hasInteractions: false,
          message: "Mindestens 2 aktive Medikamente erforderlich für Interaktionsprüfung"
        });
        setIsChecking(false);
        return;
      }

      const medNames = activeMeds.map(m => m.name).join(", ");
      
      const prompt = `Du bist ein pharmazeutischer Experte. Prüfe die folgenden Medikamente auf Wechselwirkungen:

MEDIKAMENTE:
${activeMeds.map(m => `- ${m.name} (${m.dosage}, ${m.frequency})`).join('\n')}

ANALYSE FOLGENDE ASPEKTE:
1. Kritische Wechselwirkungen (lebensbedrohlich)
2. Wichtige Wechselwirkungen (ernsthaft)
3. Moderate Wechselwirkungen (Vorsicht geboten)
4. Geringfügige Wechselwirkungen (Information)

Für jede Wechselwirkung:
- Betroffene Medikamente
- Art der Wechselwirkung
- Schweregrad
- Empfehlung (was tun?)

WICHTIG: Sei präzise und evidenzbasiert. Keine Wechselwirkung = sage es klar.`;

      const result = await base44.integrations.Core.InvokeLLM({
        prompt,
        response_json_schema: {
          type: "object",
          properties: {
            has_interactions: { type: "boolean" },
            overall_risk_level: { 
              type: "string", 
              enum: ["safe", "monitor", "caution", "danger"] 
            },
            summary: { type: "string" },
            interactions: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  medications_involved: {
                    type: "array",
                    items: { type: "string" }
                  },
                  severity: {
                    type: "string",
                    enum: ["critical", "major", "moderate", "minor"]
                  },
                  description: { type: "string" },
                  mechanism: { type: "string" },
                  recommendation: { type: "string" },
                  symptoms_to_watch: {
                    type: "array",
                    items: { type: "string" }
                  }
                }
              }
            },
            general_recommendations: {
              type: "array",
              items: { type: "string" }
            }
          }
        }
      });

      setInteractions(result);
      setLastChecked(new Date());

      // Create notification if critical interactions found
      if (result.interactions?.some(i => i.severity === 'critical')) {
        await base44.entities.Notification.create({
          title: "⚠️ Kritische Medikamenten-Wechselwirkung",
          message: `Es wurden kritische Wechselwirkungen in Ihrer Medikation festgestellt. Bitte kontaktieren Sie umgehend Ihren Arzt.`,
          type: "warning",
          priority: "high"
        });

        toast.error("⚠️ KRITISCHE WECHSELWIRKUNG GEFUNDEN!", {
          duration: 10000
        });
      }

    } catch (error) {
      console.error("Interaction check error:", error);
      toast.error("Fehler bei der Interaktionsprüfung");
      setInteractions({
        error: true,
        message: error.message
      });
    } finally {
      setIsChecking(false);
    }
  };

  const getRiskLevelDisplay = (level) => {
    const config = {
      safe: { text: "Sicher", color: "bg-green-600", icon: CheckCircle },
      monitor: { text: "Überwachen", color: "bg-blue-600", icon: Info },
      caution: { text: "Vorsicht", color: "bg-orange-600", icon: AlertCircle },
      danger: { text: "Gefahr", color: "bg-red-600", icon: AlertTriangle }
    };
    return config[level] || config.monitor;
  };

  if (!interactions && !isChecking) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="text-center space-y-4">
            <div className="w-16 h-16 mx-auto bg-blue-100 rounded-full flex items-center justify-center">
              <RefreshCw className="h-8 w-8 text-blue-600" />
            </div>
            <p className="text-gray-600">
              Prüfen Sie Ihre Medikamente auf Wechselwirkungen
            </p>
            <Button onClick={checkInteractions} className="w-full">
              Interaktionen prüfen
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -20 }}
      >
        <Card className="border-2">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center gap-2">
                <AlertCircle className="h-5 w-5 text-blue-600" />
                Wechselwirkungsprüfung
              </CardTitle>
              {onClose && (
                <Button variant="ghost" size="icon" onClick={onClose}>
                  <X className="h-4 w-4" />
                </Button>
              )}
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            {isChecking ? (
              <div className="text-center py-8 space-y-3">
                <Loader2 className="h-12 w-12 animate-spin text-blue-600 mx-auto" />
                <p className="text-gray-600">Analysiere Medikamenten-Wechselwirkungen...</p>
                <p className="text-sm text-gray-500">Dies kann 10-15 Sekunden dauern</p>
              </div>
            ) : interactions?.error ? (
              <Alert className="border-red-300 bg-red-50">
                <AlertTriangle className="h-4 w-4 text-red-600" />
                <AlertDescription className="text-red-800">
                  {interactions.message}
                </AlertDescription>
              </Alert>
            ) : interactions?.has_interactions === false ? (
              <Alert className="border-green-300 bg-green-50">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <AlertDescription className="text-green-800">
                  <strong>Keine bekannten Wechselwirkungen gefunden!</strong>
                  <p className="mt-1 text-sm">{interactions.summary}</p>
                </AlertDescription>
              </Alert>
            ) : interactions ? (
              <div className="space-y-4">
                {/* Overall Risk Level */}
                <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div className="flex items-center gap-2">
                    {React.createElement(
                      getRiskLevelDisplay(interactions.overall_risk_level).icon,
                      { className: "h-5 w-5" }
                    )}
                    <span className="font-semibold">Risiko-Level:</span>
                  </div>
                  <Badge className={getRiskLevelDisplay(interactions.overall_risk_level).color}>
                    {getRiskLevelDisplay(interactions.overall_risk_level).text}
                  </Badge>
                </div>

                {/* Summary */}
                {interactions.summary && (
                  <Alert>
                    <Info className="h-4 w-4" />
                    <AlertDescription>{interactions.summary}</AlertDescription>
                  </Alert>
                )}

                {/* Interactions List */}
                {interactions.interactions?.length > 0 && (
                  <div className="space-y-3">
                    <h3 className="font-semibold text-gray-900">
                      Gefundene Wechselwirkungen ({interactions.interactions.length})
                    </h3>
                    {interactions.interactions.map((interaction, idx) => {
                      const config = SEVERITY_CONFIG[interaction.severity] || SEVERITY_CONFIG.moderate;
                      const Icon = config.icon;
                      
                      return (
                        <motion.div
                          key={idx}
                          initial={{ opacity: 0, x: -20 }}
                          animate={{ opacity: 1, x: 0 }}
                          transition={{ delay: idx * 0.1 }}
                        >
                          <Card className={`border-2 ${config.borderColor} ${config.bgColor}`}>
                            <CardContent className="pt-4 space-y-2">
                              <div className="flex items-start justify-between">
                                <div className="flex items-center gap-2">
                                  <Icon className={`h-5 w-5 ${config.color}`} />
                                  <Badge className={config.badgeColor}>
                                    {interaction.severity.toUpperCase()}
                                  </Badge>
                                </div>
                              </div>

                              <div className="space-y-2 text-sm">
                                <div>
                                  <strong className="text-gray-900">Betroffene Medikamente:</strong>
                                  <p className="text-gray-700">
                                    {interaction.medications_involved.join(" + ")}
                                  </p>
                                </div>

                                <div>
                                  <strong className="text-gray-900">Beschreibung:</strong>
                                  <p className="text-gray-700">{interaction.description}</p>
                                </div>

                                {interaction.mechanism && (
                                  <div>
                                    <strong className="text-gray-900">Mechanismus:</strong>
                                    <p className="text-gray-700">{interaction.mechanism}</p>
                                  </div>
                                )}

                                <div className="bg-white/50 rounded p-3 border">
                                  <strong className="text-gray-900">💡 Empfehlung:</strong>
                                  <p className="text-gray-700 mt-1">{interaction.recommendation}</p>
                                </div>

                                {interaction.symptoms_to_watch?.length > 0 && (
                                  <div>
                                    <strong className="text-gray-900">⚠️ Symptome beobachten:</strong>
                                    <ul className="list-disc list-inside text-gray-700 mt-1">
                                      {interaction.symptoms_to_watch.map((symptom, i) => (
                                        <li key={i}>{symptom}</li>
                                      ))}
                                    </ul>
                                  </div>
                                )}
                              </div>
                            </CardContent>
                          </Card>
                        </motion.div>
                      );
                    })}
                  </div>
                )}

                {/* General Recommendations */}
                {interactions.general_recommendations?.length > 0 && (
                  <div className="bg-blue-50 border-2 border-blue-300 rounded-lg p-4">
                    <h3 className="font-semibold text-gray-900 mb-2 flex items-center gap-2">
                      <Info className="h-4 w-4 text-blue-600" />
                      Allgemeine Empfehlungen
                    </h3>
                    <ul className="space-y-1 text-sm text-gray-700">
                      {interactions.general_recommendations.map((rec, idx) => (
                        <li key={idx} className="flex items-start gap-2">
                          <span>•</span>
                          <span>{rec}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {/* Last Checked */}
                {lastChecked && (
                  <p className="text-xs text-gray-500 text-center">
                    Zuletzt geprüft: {lastChecked.toLocaleString('de-DE')}
                  </p>
                )}

                {/* Recheck Button */}
                <Button
                  onClick={checkInteractions}
                  variant="outline"
                  className="w-full"
                  disabled={isChecking}
                >
                  <RefreshCw className="h-4 w-4 mr-2" />
                  Erneut prüfen
                </Button>
              </div>
            ) : null}

            {/* Disclaimer */}
            <Alert className="border-gray-300">
              <AlertCircle className="h-4 w-4 text-gray-600" />
              <AlertDescription className="text-xs text-gray-600">
                Diese Prüfung ersetzt keine ärztliche Beratung. Bei Unsicherheiten kontaktieren Sie Ihren Arzt oder Apotheker.
              </AlertDescription>
            </Alert>
          </CardContent>
        </Card>
      </motion.div>
    </AnimatePresence>
  );
}