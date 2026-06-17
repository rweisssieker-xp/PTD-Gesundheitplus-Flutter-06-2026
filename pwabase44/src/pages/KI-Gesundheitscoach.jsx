/**
 * AI Health Coach Page
 * Comprehensive health analysis, risk assessment, and personalized recommendations
 */

import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { 
  Brain, 
  Activity,
  TrendingUp,
  AlertTriangle,
  CheckCircle,
  Loader2,
  RefreshCw,
  Sparkles,
  Heart,
  Pill,
  Calendar,
  MessageSquare,
  Target,
  Award
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";
import HealthAIChat from "@/components/HealthAIChat";

export default function KIGesundheitscoachPage() {
  const [analysis, setAnalysis] = useState(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [showChat, setShowChat] = useState(false);
  const [lastAnalysis, setLastAnalysis] = useState(null);

  useEffect(() => {
    loadSavedAnalysis();
  }, []);

  const loadSavedAnalysis = async () => {
    try {
      const user = await base44.auth.me();
      if (user.last_health_analysis) {
        setAnalysis(user.last_health_analysis);
        setLastAnalysis(user.last_health_analysis.analyzed_at);
      }
    } catch (error) {
      console.error('Error loading analysis:', error);
    }
  };

  const performAnalysis = async () => {
    setIsAnalyzing(true);
    
    try {
      const user = await base44.auth.me();
      
      // Collect comprehensive health data
      const [medications, allergies, medicalHistory, appointments, vaccinations] = await Promise.all([
        base44.entities.Medication.filter({ active: true }).catch(() => []),
        base44.entities.Allergy.list().catch(() => []),
        base44.entities.MedicalHistory.list().catch(() => []),
        base44.entities.Appointment.list().catch(() => []),
        base44.entities.Vaccination.list().catch(() => [])
      ]);

      const age = user.date_of_birth 
        ? Math.floor((new Date() - new Date(user.date_of_birth)) / 31557600000)
        : null;

      const healthData = {
        patient: {
          age: age,
          gender: user.gender || 'unbekannt',
          weight: user.weight,
          height: user.height,
          bmi: user.weight && user.height ? (user.weight / Math.pow(user.height / 100, 2)).toFixed(1) : null,
          is_pregnant: user.is_pregnant || false
        },
        medications: medications.map(m => ({
          name: m.name,
          dosage: m.dosage,
          frequency: m.frequency,
          reason: m.reason,
          start_date: m.start_date,
          side_effects: m.side_effects
        })),
        allergies: allergies.map(a => ({
          allergen: a.allergen,
          severity: a.severity,
          category: a.category,
          symptoms: a.symptoms
        })),
        diagnoses: medicalHistory[0]?.diagnoses || [],
        surgeries: medicalHistory[0]?.surgeries || [],
        lifestyle: medicalHistory[0]?.lifestyle || {},
        blood_type: medicalHistory[0]?.blood_type,
        family_history: medicalHistory[0]?.family_history,
        upcoming_appointments: appointments
          .filter(a => new Date(a.date) > new Date())
          .length,
        recent_vaccinations: vaccinations
          .filter(v => {
            const sixMonthsAgo = new Date();
            sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
            return new Date(v.date_given) > sixMonthsAgo;
          })
          .map(v => v.vaccine_name)
      };

      // Enhanced AI prompt
      const prompt = `Sie sind ein KI-Gesundheitscoach, der eine umfassende Gesundheitsanalyse durchführt.

GESUNDHEITSDATEN:
${JSON.stringify(healthData, null, 2)}

AUFGABE: Führen Sie eine ganzheitliche Gesundheitsanalyse durch:

1. GESUNDHEITSSCORE (1-10): Bewerten Sie den aktuellen Gesundheitszustand
2. RISIKOBEWERTUNG: Identifizieren Sie konkrete Risiken mit Evidenz
3. MEDIKAMENTEN-ANALYSE: Überprüfen Sie Compliance, Interaktionen, Optimierungspotential
4. LIFESTYLE-EMPFEHLUNGEN: Konkrete, umsetzbare Verbesserungen
5. PRÄVENTIONSLÜCKEN: Fehlende Vorsorge, Impfungen, Screenings
6. POSITIVE ASPEKTE: Was läuft gut?
7. PRIORISIERTE HANDLUNGSEMPFEHLUNGEN

Seien Sie:
- Evidenzbasiert und medizinisch fundiert
- Konkret und handlungsorientiert
- Motivierend und positiv
- Ehrlich bei Risiken
- Praktisch in Empfehlungen

Geben Sie das Ergebnis im folgenden JSON-Format zurück:`;

      const responseSchema = {
        type: "object",
        properties: {
          overall_health_score: {
            type: "number",
            description: "1-10 (10=optimal)"
          },
          risk_level: {
            type: "string",
            enum: ["low", "moderate", "high", "critical"]
          },
          summary: {
            type: "string",
            description: "Zusammenfassung in 2-3 Sätzen"
          },
          identified_risks: {
            type: "array",
            items: {
              type: "object",
              properties: {
                risk: { type: "string" },
                severity: { type: "string", enum: ["low", "medium", "high", "critical"] },
                evidence: { type: "string" },
                recommendation: { type: "string" },
                actionable: { type: "boolean" }
              }
            }
          },
          medication_concerns: {
            type: "array",
            items: {
              type: "object",
              properties: {
                concern: { type: "string" },
                affected_medications: { type: "array", items: { type: "string" } },
                recommendation: { type: "string" }
              }
            }
          },
          lifestyle_recommendations: {
            type: "array",
            items: {
              type: "object",
              properties: {
                category: { type: "string" },
                current_status: { type: "string" },
                recommendation: { type: "string" },
                impact: { type: "string" },
                priority: { type: "number" }
              }
            }
          },
          preventive_care_gaps: {
            type: "array",
            items: {
              type: "object",
              properties: {
                missing_item: { type: "string" },
                importance: { type: "string" },
                recommended_action: { type: "string" },
                urgency: { type: "string" }
              }
            }
          },
          positive_aspects: {
            type: "array",
            items: { type: "string" }
          },
          priority_actions: {
            type: "array",
            items: {
              type: "object",
              properties: {
                action: { type: "string" },
                priority: { type: "number" },
                deadline: { type: "string" },
                category: { type: "string" }
              }
            }
          }
        },
        required: ["overall_health_score", "risk_level", "summary"]
      };

      toast.info('KI analysiert Ihre Gesundheitsdaten...', {
        description: 'Dies kann 30-60 Sekunden dauern'
      });

      // Call AI
      const result = await base44.integrations.Core.InvokeLLM({
        prompt: prompt,
        response_json_schema: responseSchema
      });

      const analysisResult = {
        ...result,
        analyzed_at: new Date().toISOString()
      };

      // Save to user profile
      await base44.auth.updateMe({
        last_health_analysis: analysisResult
      });

      setAnalysis(analysisResult);
      setLastAnalysis(analysisResult.analyzed_at);

      toast.success('✅ Gesundheitsanalyse abgeschlossen!');

    } catch (error) {
      console.error('Analysis error:', error);
      toast.error('Fehler bei der Analyse', {
        description: error.message
      });
    } finally {
      setIsAnalyzing(false);
    }
  };

  const riskColors = {
    low: 'border-green-200 bg-green-50 text-green-900',
    moderate: 'border-yellow-200 bg-yellow-50 text-yellow-900',
    high: 'border-orange-200 bg-orange-50 text-orange-900',
    critical: 'border-red-200 bg-red-50 text-red-900'
  };

  const scoreColor = (score) => {
    if (score >= 8) return 'text-green-600';
    if (score >= 6) return 'text-yellow-600';
    if (score >= 4) return 'text-orange-600';
    return 'text-red-600';
  };

  const daysSinceAnalysis = lastAnalysis 
    ? Math.floor((new Date() - new Date(lastAnalysis)) / (1000 * 60 * 60 * 24))
    : null;

  return (
    <div className="p-6 space-y-6 pb-24">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2 flex items-center gap-2">
              <Brain className="h-7 w-7 text-purple-600" />
              KI-Gesundheitscoach
            </h1>
            <p className="text-gray-600">
              Personalisierte Gesundheitsanalyse und Empfehlungen
            </p>
            {lastAnalysis && (
              <p className="text-xs text-gray-500 mt-1">
                Letzte Analyse: {new Date(lastAnalysis).toLocaleDateString('de-DE')} 
                {daysSinceAnalysis !== null && ` (vor ${daysSinceAnalysis} Tagen)`}
              </p>
            )}
          </div>
          <div className="flex gap-2">
            <Button
              onClick={() => setShowChat(true)}
              variant="outline"
              size="sm"
              className="gap-2"
            >
              <MessageSquare className="h-4 w-4" />
              Chat
            </Button>
            <Button
              onClick={performAnalysis}
              disabled={isAnalyzing}
              className="bg-purple-600 hover:bg-purple-700 gap-2"
            >
              {isAnalyzing ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Analysiere...
                </>
              ) : (
                <>
                  <RefreshCw className="h-4 w-4" />
                  {analysis ? 'Aktualisieren' : 'Analyse starten'}
                </>
              )}
            </Button>
          </div>
        </div>

        {isAnalyzing && (
          <Card className="border-2 border-purple-200 bg-purple-50">
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <Loader2 className="h-8 w-8 animate-spin text-purple-600" />
                <div>
                  <p className="font-semibold text-purple-900">KI analysiert Ihre Gesundheitsdaten...</p>
                  <p className="text-sm text-purple-700">Medikamente, Allergien, Lifestyle, Risiken • 30-60 Sekunden</p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {!analysis && !isAnalyzing && (
          <Card className="border-2 border-purple-200">
            <CardContent className="pt-6">
              <div className="text-center py-8">
                <div className="h-20 w-20 rounded-full bg-purple-100 flex items-center justify-center mx-auto mb-4">
                  <Sparkles className="h-10 w-10 text-purple-600" />
                </div>
                <h2 className="text-xl font-bold text-gray-900 mb-2">
                  Noch keine Analyse vorhanden
                </h2>
                <p className="text-gray-600 mb-6 max-w-md mx-auto">
                  Lassen Sie die KI Ihre Gesundheitsdaten analysieren und erhalten Sie personalisierte Empfehlungen, 
                  Risikoeinschätzungen und Handlungsvorschläge.
                </p>
                <div className="grid grid-cols-2 gap-4 max-w-md mx-auto mb-6">
                  <div className="text-center p-3 bg-blue-50 rounded-lg">
                    <Activity className="h-6 w-6 text-blue-600 mx-auto mb-1" />
                    <p className="text-xs font-semibold text-blue-900">Gesundheitsscore</p>
                  </div>
                  <div className="text-center p-3 bg-green-50 rounded-lg">
                    <Target className="h-6 w-6 text-green-600 mx-auto mb-1" />
                    <p className="text-xs font-semibold text-green-900">Handlungsplan</p>
                  </div>
                  <div className="text-center p-3 bg-orange-50 rounded-lg">
                    <AlertTriangle className="h-6 w-6 text-orange-600 mx-auto mb-1" />
                    <p className="text-xs font-semibold text-orange-900">Risikowarnung</p>
                  </div>
                  <div className="text-center p-3 bg-purple-50 rounded-lg">
                    <TrendingUp className="h-6 w-6 text-purple-600 mx-auto mb-1" />
                    <p className="text-xs font-semibold text-purple-900">Verbesserungen</p>
                  </div>
                </div>
                <Button
                  onClick={performAnalysis}
                  className="bg-purple-600 hover:bg-purple-700"
                  size="lg"
                >
                  <Brain className="h-5 w-5 mr-2" />
                  Jetzt analysieren
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {analysis && !isAnalyzing && (
          <>
            {/* Health Score & Risk Level */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Card className="border-2 border-purple-200">
                <CardHeader>
                  <CardTitle className="text-lg flex items-center gap-2">
                    <Activity className="h-5 w-5 text-purple-600" />
                    Gesundheitsscore
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-center">
                    <div className={`text-6xl font-bold ${scoreColor(analysis.overall_health_score)}`}>
                      {analysis.overall_health_score}/10
                    </div>
                    <p className="text-sm text-gray-600 mt-2">
                      {analysis.overall_health_score >= 8 ? 'Ausgezeichnet' :
                       analysis.overall_health_score >= 6 ? 'Gut' :
                       analysis.overall_health_score >= 4 ? 'Verbesserungsbedarf' : 'Handlungsbedarf'}
                    </p>
                  </div>
                </CardContent>
              </Card>

              <Card className={`border-2 ${riskColors[analysis.risk_level]}`}>
                <CardHeader>
                  <CardTitle className="text-lg flex items-center gap-2">
                    <AlertTriangle className="h-5 w-5" />
                    Risiko-Level
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-center">
                    <div className="text-4xl font-bold mb-2">
                      {analysis.risk_level.toUpperCase()}
                    </div>
                    <p className="text-sm">
                      {analysis.identified_risks?.length || 0} identifizierte Risiken
                    </p>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Summary */}
            <Card className="border-2 border-blue-200 bg-blue-50">
              <CardContent className="pt-6">
                <p className="text-gray-900 text-center font-medium">
                  {analysis.summary}
                </p>
              </CardContent>
            </Card>

            {/* Priority Actions */}
            {analysis.priority_actions && analysis.priority_actions.length > 0 && (
              <Card className="border-2 border-green-200">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Target className="h-5 w-5 text-green-600" />
                    Prioritäten-Liste
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {analysis.priority_actions
                      .sort((a, b) => a.priority - b.priority)
                      .slice(0, 5)
                      .map((action, index) => (
                        <div key={index} className="flex gap-3 items-start p-3 bg-green-50 rounded-lg border border-green-200">
                          <div className="h-8 w-8 rounded-full bg-green-600 text-white flex items-center justify-center font-bold flex-shrink-0">
                            {action.priority}
                          </div>
                          <div className="flex-1">
                            <p className="font-semibold text-gray-900">{action.action}</p>
                            <div className="flex gap-2 mt-1">
                              <span className="text-xs bg-white px-2 py-0.5 rounded">{action.category}</span>
                              {action.deadline && (
                                <span className="text-xs bg-white px-2 py-0.5 rounded flex items-center gap-1">
                                  <Calendar className="h-3 w-3" />
                                  {action.deadline}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                      ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Positive Aspects */}
            {analysis.positive_aspects && analysis.positive_aspects.length > 0 && (
              <Card className="border-2 border-green-200 bg-green-50">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-lg">
                    <Award className="h-5 w-5 text-green-600" />
                    Das machen Sie bereits gut!
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-2">
                    {analysis.positive_aspects.map((aspect, index) => (
                      <li key={index} className="flex items-start gap-2">
                        <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
                        <span className="text-gray-900">{aspect}</span>
                      </li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            )}

            {/* Identified Risks */}
            {analysis.identified_risks && analysis.identified_risks.length > 0 && (
              <Card className="border-2 border-orange-200">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <AlertTriangle className="h-5 w-5 text-orange-600" />
                    Identifizierte Risiken ({analysis.identified_risks.length})
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  {analysis.identified_risks.map((risk, index) => (
                    <div key={index} className="border-l-4 border-orange-500 pl-4 py-2">
                      <div className="flex items-start justify-between mb-1">
                        <p className="font-semibold text-gray-900">{risk.risk}</p>
                        <span className={`text-xs px-2 py-0.5 rounded ${
                          risk.severity === 'critical' ? 'bg-red-100 text-red-800' :
                          risk.severity === 'high' ? 'bg-orange-100 text-orange-800' :
                          risk.severity === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-blue-100 text-blue-800'
                        }`}>
                          {risk.severity.toUpperCase()}
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mb-2">{risk.evidence}</p>
                      <p className="text-sm text-gray-900">
                        <strong>→ Empfehlung:</strong> {risk.recommendation}
                      </p>
                    </div>
                  ))}
                </CardContent>
              </Card>
            )}

            {/* Lifestyle Recommendations */}
            {analysis.lifestyle_recommendations && analysis.lifestyle_recommendations.length > 0 && (
              <Card className="border-2 border-blue-200">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <TrendingUp className="h-5 w-5 text-blue-600" />
                    Lifestyle-Empfehlungen
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  {analysis.lifestyle_recommendations
                    .sort((a, b) => (a.priority || 99) - (b.priority || 99))
                    .map((rec, index) => (
                      <div key={index} className="p-3 bg-blue-50 rounded-lg border border-blue-200">
                        <div className="flex items-start justify-between mb-2">
                          <p className="font-semibold text-blue-900">{rec.category}</p>
                          {rec.priority && (
                            <span className="text-xs bg-blue-600 text-white px-2 py-0.5 rounded">
                              Priorität {rec.priority}
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-gray-700 mb-2">
                          <strong>Status:</strong> {rec.current_status}
                        </p>
                        <p className="text-sm text-gray-900 mb-1">
                          <strong>→ Empfehlung:</strong> {rec.recommendation}
                        </p>
                        <p className="text-xs text-gray-600">
                          <strong>Auswirkung:</strong> {rec.impact}
                        </p>
                      </div>
                    ))}
                </CardContent>
              </Card>
            )}

            {/* Medication Concerns */}
            {analysis.medication_concerns && analysis.medication_concerns.length > 0 && (
              <Card className="border-2 border-yellow-200">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Pill className="h-5 w-5 text-yellow-600" />
                    Medikamenten-Hinweise
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  {analysis.medication_concerns.map((concern, index) => (
                    <div key={index} className="p-3 bg-yellow-50 rounded-lg border border-yellow-200">
                      <p className="font-semibold text-yellow-900 mb-2">{concern.concern}</p>
                      {concern.affected_medications && concern.affected_medications.length > 0 && (
                        <p className="text-sm text-gray-700 mb-2">
                          <strong>Betroffene Medikamente:</strong> {concern.affected_medications.join(', ')}
                        </p>
                      )}
                      <p className="text-sm text-gray-900">
                        <strong>→ Empfehlung:</strong> {concern.recommendation}
                      </p>
                    </div>
                  ))}
                </CardContent>
              </Card>
            )}

            {/* Preventive Care Gaps */}
            {analysis.preventive_care_gaps && analysis.preventive_care_gaps.length > 0 && (
              <Card className="border-2 border-purple-200">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Heart className="h-5 w-5 text-purple-600" />
                    Präventions-Lücken
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-2">
                  {analysis.preventive_care_gaps.map((gap, index) => (
                    <div key={index} className="flex items-start gap-3 p-3 bg-purple-50 rounded-lg border border-purple-200">
                      <CheckCircle className="h-5 w-5 text-purple-600 flex-shrink-0 mt-0.5" />
                      <div className="flex-1">
                        <div className="flex items-start justify-between mb-1">
                          <p className="font-semibold text-gray-900">{gap.missing_item}</p>
                          {gap.urgency && (
                            <span className={`text-xs px-2 py-0.5 rounded ${
                              gap.urgency === 'urgent' ? 'bg-red-100 text-red-800' :
                              gap.urgency === 'soon' ? 'bg-yellow-100 text-yellow-800' :
                              'bg-blue-100 text-blue-800'
                            }`}>
                              {gap.urgency}
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-gray-700 mb-1">
                          <strong>Wichtigkeit:</strong> {gap.importance}
                        </p>
                        <p className="text-sm text-gray-900">
                          <strong>→ Aktion:</strong> {gap.recommended_action}
                        </p>
                      </div>
                    </div>
                  ))}
                </CardContent>
              </Card>
            )}
          </>
        )}

        {/* Disclaimer */}
        <Card className="border-2 border-gray-200 bg-gray-50">
          <CardContent className="pt-6">
            <div className="flex gap-3 text-sm text-gray-700">
              <AlertTriangle className="h-5 w-5 text-gray-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold mb-1">Wichtiger Hinweis</p>
                <p className="text-xs">
                  Diese KI-Analyse dient zur Orientierung und Gesundheitsförderung. Sie ersetzt NICHT die 
                  professionelle medizinische Beratung, Diagnose oder Behandlung durch einen Arzt. Bei 
                  gesundheitlichen Beschwerden oder Fragen konsultieren Sie bitte immer einen Arzt.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* AI Chat Modal */}
      {showChat && <HealthAIChat onClose={() => setShowChat(false)} />}
    </div>
  );
}