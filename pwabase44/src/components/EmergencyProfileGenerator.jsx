/**
 * AI-Powered Emergency Profile Generator
 * Analyzes medical data and generates comprehensive emergency profile for first responders
 */

import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { 
  Brain, 
  Loader2, 
  CheckCircle, 
  AlertTriangle,
  Download,
  RefreshCw,
  Shield,
  Activity,
  AlertCircle,
  FileText,
  Zap
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";
import { useQueryClient } from "@tanstack/react-query";

export default function EmergencyProfileGenerator() {
  const [isGenerating, setIsGenerating] = useState(false);
  const [profile, setProfile] = useState(null);
  const [user, setUser] = useState(null);
  const queryClient = useQueryClient();

  useEffect(() => {
    loadUserProfile();
  }, []);

  const loadUserProfile = async () => {
    try {
      const userData = await base44.auth.me();
      setUser(userData);
      
      if (userData.emergency_profile) {
        setProfile(userData.emergency_profile);
      }
    } catch (error) {
      console.error('Error loading profile:', error);
    }
  };

  const collectMedicalData = async () => {
    try {
      const [medications, allergies, medicalHistory, vaccinations, healthPasses] = await Promise.all([
        base44.entities.Medication.filter({ active: true }).catch(() => []),
        base44.entities.Allergy.list().catch(() => []),
        base44.entities.MedicalHistory.list().catch(() => []),
        base44.entities.Vaccination.list().catch(() => []),
        base44.entities.HealthPass.list().catch(() => [])
      ]);

      return {
        user,
        medications,
        allergies,
        medicalHistory: medicalHistory[0] || null,
        vaccinations,
        healthPasses
      };
    } catch (error) {
      console.error('Error collecting data:', error);
      return null;
    }
  };

  const generateProfile = async () => {
    setIsGenerating(true);
    
    try {
      const medicalData = await collectMedicalData();
      
      if (!medicalData) {
        toast.error('Fehler beim Laden der medizinischen Daten');
        return;
      }

      // Calculate age
      let age = null;
      if (user?.date_of_birth) {
        const birthDate = new Date(user.date_of_birth);
        age = Math.floor((new Date() - birthDate) / 31557600000);
      }

      // Prepare comprehensive medical summary
      const medicalSummary = {
        patient: {
          age: age,
          gender: user?.gender || 'unbekannt',
          weight: user?.weight,
          height: user?.height,
          is_pregnant: user?.is_pregnant || false,
          pregnancy_week: user?.pregnancy_week
        },
        current_medications: medicalData.medications.map(m => ({
          name: m.name,
          dosage: m.dosage,
          frequency: m.frequency,
          reason: m.reason,
          side_effects: m.side_effects
        })),
        allergies: medicalData.allergies.map(a => ({
          allergen: a.allergen,
          category: a.category,
          severity: a.severity,
          symptoms: a.symptoms
        })),
        diagnoses: medicalData.medicalHistory?.diagnoses || [],
        surgeries: medicalData.medicalHistory?.surgeries || [],
        blood_type: medicalData.medicalHistory?.blood_type,
        family_history: medicalData.medicalHistory?.family_history,
        lifestyle: medicalData.medicalHistory?.lifestyle,
        implants: medicalData.healthPasses.filter(h => 
          h.pass_type.includes('Implantat') || 
          h.pass_type.includes('Endoprothese') || 
          h.pass_type.includes('Herzschrittmacher')
        ).map(h => ({
          type: h.pass_type,
          title: h.title,
          date: h.date_implanted
        })),
        recent_vaccinations: medicalData.vaccinations
          .filter(v => {
            const sixMonthsAgo = new Date();
            sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
            return new Date(v.date_given) > sixMonthsAgo;
          })
          .map(v => ({
            vaccine: v.vaccine_name,
            date: v.date_given
          }))
      };

      // Enhanced AI prompt for emergency profile generation
      const prompt = `Sie sind ein erfahrener Notfallmediziner und erstellen ein NOTFALL-PROFIL für Ersthelfer und Rettungsdienste.

PATIENT-DATEN:
${JSON.stringify(medicalSummary, null, 2)}

AUFGABE: Erstellen Sie ein strukturiertes, priorisiertes Notfallprofil, das lebensrettend sein kann.

WICHTIG: 
- Fokus auf SOFORT handlungsrelevante Informationen
- Priorisierung nach Kritikalität
- Kurz, präzise, medizinisch korrekt
- Berücksichtigen Sie Medikamenten-Interaktionen mit gängigen Notfallmedikamenten
- Beachten Sie absolute Kontraindikationen
- Geben Sie konkrete Handlungsempfehlungen

Analysieren Sie:
1. Kritische Warnungen (lebensbedrohliche Allergien, Kontraindikationen)
2. Medikamenten-Interaktionen mit typischen Notfallmedikamenten (Adrenalin, Morphin, Aspirin, Benzodiazepine, etc.)
3. Risikobewertung basierend auf Vorerkrankungen
4. Empfohlene Sofortmaßnahmen priorisiert nach Wichtigkeit
5. Besonderheiten für Transport und Behandlung

Geben Sie das Profil im folgenden JSON-Format zurück (keine zusätzlichen Erklärungen):`;

      const responseSchema = {
        type: "object",
        properties: {
          summary: {
            type: "string",
            description: "2-3 Sätze Zusammenfassung für Ersthelfer"
          },
          critical_warnings: {
            type: "array",
            items: {
              type: "object",
              properties: {
                severity: {
                  type: "string",
                  enum: ["critical", "high", "medium"]
                },
                warning: {
                  type: "string"
                },
                action: {
                  type: "string"
                }
              },
              required: ["severity", "warning", "action"]
            }
          },
          contraindications: {
            type: "array",
            items: {
              type: "string"
            },
            description: "Liste absoluter Kontraindikationen"
          },
          medication_interactions: {
            type: "array",
            items: {
              type: "object",
              properties: {
                emergency_drug: {
                  type: "string"
                },
                interaction: {
                  type: "string"
                },
                severity: {
                  type: "string",
                  enum: ["critical", "major", "moderate", "minor"]
                },
                recommendation: {
                  type: "string"
                }
              },
              required: ["emergency_drug", "interaction", "severity", "recommendation"]
            }
          },
          immediate_actions: {
            type: "array",
            items: {
              type: "object",
              properties: {
                priority: {
                  type: "number"
                },
                action: {
                  type: "string"
                },
                rationale: {
                  type: "string"
                }
              },
              required: ["priority", "action", "rationale"]
            }
          },
          risk_assessment: {
            type: "object",
            properties: {
              overall_risk_level: {
                type: "string",
                enum: ["low", "moderate", "high", "critical"]
              },
              specific_risks: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    risk: {
                      type: "string"
                    },
                    likelihood: {
                      type: "string"
                    },
                    impact: {
                      type: "string"
                    }
                  }
                }
              }
            },
            required: ["overall_risk_level"]
          },
          transport_considerations: {
            type: "array",
            items: {
              type: "string"
            }
          },
          communication_aids: {
            type: "object",
            properties: {
              patient_can_communicate: {
                type: "boolean"
              },
              language_barriers: {
                type: "array",
                items: {
                  type: "string"
                }
              },
              cognitive_considerations: {
                type: "string"
              }
            }
          }
        },
        required: ["summary", "critical_warnings", "contraindications", "immediate_actions", "risk_assessment"]
      };

      toast.info('KI analysiert medizinische Daten...', {
        description: 'Dies kann 30-60 Sekunden dauern'
      });

      // Call AI to generate profile
      const result = await base44.integrations.Core.InvokeLLM({
        prompt: prompt,
        response_json_schema: responseSchema
      });

      // Add metadata
      const generatedProfile = {
        ...result,
        version: '2.0',
        generated_at: new Date().toISOString()
      };

      // Save to user profile
      await base44.auth.updateMe({
        emergency_profile: generatedProfile
      });

      setProfile(generatedProfile);
      
      toast.success('✅ Notfallprofil erstellt!', {
        description: 'KI-generiertes Profil wurde gespeichert'
      });

      // Refresh user data
      await loadUserProfile();

    } catch (error) {
      console.error('Profile generation error:', error);
      toast.error('Fehler bei der Profil-Generierung', {
        description: error.message
      });
    } finally {
      setIsGenerating(false);
    }
  };

  const downloadProfile = () => {
    if (!profile) return;

    const profileText = formatProfileForDownload(profile);
    const blob = new Blob([profileText], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `notfallprofil_${new Date().toISOString().split('T')[0]}.txt`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success('Profil heruntergeladen');
  };

  const formatProfileForDownload = (profile) => {
    let text = '═══════════════════════════════════════\n';
    text += '   KI-GENERIERTES NOTFALLPROFIL\n';
    text += `   Version ${profile.version}\n`;
    text += `   Erstellt: ${new Date(profile.generated_at).toLocaleString('de-DE')}\n`;
    text += '═══════════════════════════════════════\n\n';

    text += '📋 ZUSAMMENFASSUNG:\n';
    text += profile.summary + '\n\n';

    if (profile.critical_warnings && profile.critical_warnings.length > 0) {
      text += '🚨 KRITISCHE WARNUNGEN:\n';
      profile.critical_warnings.forEach((w, i) => {
        text += `${i + 1}. [${w.severity.toUpperCase()}] ${w.warning}\n`;
        text += `   → Maßnahme: ${w.action}\n\n`;
      });
    }

    if (profile.contraindications && profile.contraindications.length > 0) {
      text += '🚫 ABSOLUTE KONTRAINDIKATIONEN:\n';
      profile.contraindications.forEach((c, i) => {
        text += `${i + 1}. ${c}\n`;
      });
      text += '\n';
    }

    if (profile.medication_interactions && profile.medication_interactions.length > 0) {
      text += '💊 MEDIKAMENTEN-INTERAKTIONEN:\n';
      profile.medication_interactions.forEach((m, i) => {
        text += `${i + 1}. ${m.emergency_drug} [${m.severity.toUpperCase()}]\n`;
        text += `   Interaction: ${m.interaction}\n`;
        text += `   Empfehlung: ${m.recommendation}\n\n`;
      });
    }

    if (profile.immediate_actions && profile.immediate_actions.length > 0) {
      text += '✅ SOFORTMASSNAHMEN (priorisiert):\n';
      profile.immediate_actions
        .sort((a, b) => a.priority - b.priority)
        .forEach((a) => {
          text += `${a.priority}. ${a.action}\n`;
          text += `   Begründung: ${a.rationale}\n\n`;
        });
    }

    if (profile.risk_assessment) {
      text += '📊 RISIKOBEWERTUNG:\n';
      text += `Gesamt-Risiko: ${profile.risk_assessment.overall_risk_level?.toUpperCase() || 'UNBEKANNT'}\n\n`;
      
      if (profile.risk_assessment.specific_risks && profile.risk_assessment.specific_risks.length > 0) {
        text += 'Spezifische Risiken:\n';
        profile.risk_assessment.specific_risks.forEach((r, i) => {
          text += `${i + 1}. ${r.risk}\n`;
          text += `   Wahrscheinlichkeit: ${r.likelihood} | Auswirkung: ${r.impact}\n`;
        });
        text += '\n';
      }
    }

    if (profile.transport_considerations && profile.transport_considerations.length > 0) {
      text += '🚑 TRANSPORT-ÜBERLEGUNGEN:\n';
      profile.transport_considerations.forEach((t, i) => {
        text += `${i + 1}. ${t}\n`;
      });
      text += '\n';
    }

    text += '═══════════════════════════════════════\n';
    text += 'Generiert von: Gesundheit Plus AI\n';
    text += 'Für medizinisches Fachpersonal\n';
    text += '═══════════════════════════════════════\n';

    return text;
  };

  const profileAge = profile?.generated_at 
    ? Math.floor((new Date() - new Date(profile.generated_at)) / (1000 * 60 * 60 * 24))
    : null;

  const isOutdated = profileAge && profileAge > 90; // Older than 90 days

  return (
    <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-pink-50">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Brain className="h-6 w-6 text-purple-600" />
          KI-Notfallprofil Generator
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Description */}
        <div className="flex gap-3">
          <Shield className="h-5 w-5 text-purple-600 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-purple-900">
            <p className="font-semibold mb-1">Intelligentes Notfallprofil für Ersthelfer</p>
            <p className="text-xs text-purple-700">
              Die KI analysiert Ihre medizinischen Daten und erstellt ein priorisiertes Notfallprofil mit
              kritischen Warnungen, Kontraindikationen und Handlungsempfehlungen.
            </p>
          </div>
        </div>

        {/* Current Profile Status */}
        {profile ? (
          <div className="bg-white rounded-lg p-4 border-2 border-purple-200">
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-2">
                <CheckCircle className="h-5 w-5 text-green-600" />
                <div>
                  <p className="font-semibold text-gray-900">Profil vorhanden</p>
                  <p className="text-xs text-gray-600">
                    Erstellt: {new Date(profile.generated_at).toLocaleDateString('de-DE')}
                    {profileAge !== null && ` (vor ${profileAge} Tagen)`}
                  </p>
                </div>
              </div>
              {isOutdated && (
                <AlertTriangle className="h-5 w-5 text-orange-500" />
              )}
            </div>

            {isOutdated && (
              <div className="bg-orange-50 border border-orange-200 rounded-lg p-2 mb-3">
                <p className="text-xs text-orange-800">
                  ⚠️ Profil älter als 90 Tage - Aktualisierung empfohlen
                </p>
              </div>
            )}

            {/* Profile Summary */}
            <EmergencyProfilePreview profile={profile} />

            {/* Actions */}
            <div className="flex gap-2 mt-3">
              <Button
                onClick={downloadProfile}
                variant="outline"
                size="sm"
                className="flex-1"
              >
                <Download className="h-4 w-4 mr-2" />
                Download
              </Button>
              <Button
                onClick={generateProfile}
                disabled={isGenerating}
                variant="outline"
                size="sm"
                className="flex-1"
              >
                <RefreshCw className="h-4 w-4 mr-2" />
                Aktualisieren
              </Button>
            </div>
          </div>
        ) : (
          <div className="text-center py-4">
            <div className="h-16 w-16 rounded-full bg-purple-100 flex items-center justify-center mx-auto mb-3">
              <FileText className="h-8 w-8 text-purple-600" />
            </div>
            <p className="text-sm text-gray-700 mb-4">
              Noch kein Notfallprofil vorhanden
            </p>
            <Button
              onClick={generateProfile}
              disabled={isGenerating}
              className="bg-purple-600 hover:bg-purple-700"
            >
              {isGenerating ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  KI analysiert... (30-60s)
                </>
              ) : (
                <>
                  <Zap className="h-4 w-4 mr-2" />
                  Profil generieren
                </>
              )}
            </Button>
          </div>
        )}

        {/* Info Box */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <div className="flex gap-2">
            <AlertCircle className="h-4 w-4 text-blue-600 flex-shrink-0 mt-0.5" />
            <p className="text-xs text-blue-900">
              <strong>Empfehlung:</strong> Aktualisieren Sie Ihr Profil bei Änderungen Ihrer Medikation,
              neuen Diagnosen oder alle 3 Monate. Das Profil wird automatisch bei Notfall-Meldungen mit versendet.
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// Preview Component for Emergency Profile
function EmergencyProfilePreview({ profile }) {
  const [expanded, setExpanded] = useState(false);

  const riskColors = {
    low: 'text-green-600 bg-green-100',
    moderate: 'text-yellow-600 bg-yellow-100',
    high: 'text-orange-600 bg-orange-100',
    critical: 'text-red-600 bg-red-100'
  };

  const severityColors = {
    critical: 'text-red-600',
    major: 'text-orange-600',
    high: 'text-orange-600',
    moderate: 'text-yellow-600',
    medium: 'text-yellow-600',
    minor: 'text-blue-600'
  };

  if (!profile) return null;

  return (
    <div className="space-y-2">
      {/* Risk Level Badge */}
      {profile.risk_assessment?.overall_risk_level && (
        <div className="flex items-center gap-2">
          <Activity className="h-4 w-4 text-gray-500" />
          <span className="text-xs text-gray-600">Risiko-Level:</span>
          <span className={`text-xs font-semibold px-2 py-0.5 rounded ${riskColors[profile.risk_assessment.overall_risk_level]}`}>
            {profile.risk_assessment.overall_risk_level.toUpperCase()}
          </span>
        </div>
      )}

      {/* Critical Warnings Count */}
      {profile.critical_warnings && profile.critical_warnings.length > 0 && (
        <div className="flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-red-600" />
          <span className="text-xs font-semibold text-red-600">
            {profile.critical_warnings.length} kritische Warnung(en)
          </span>
        </div>
      )}

      {/* Summary Preview */}
      <p className="text-xs text-gray-700 italic">
        "{profile.summary?.substring(0, 120)}{profile.summary?.length > 120 ? '...' : ''}"
      </p>

      {/* Expand/Collapse Button */}
      <Button
        variant="ghost"
        size="sm"
        onClick={() => setExpanded(!expanded)}
        className="text-xs h-7 px-2"
      >
        {expanded ? 'Weniger anzeigen' : 'Details anzeigen'}
      </Button>

      {/* Expanded Details */}
      {expanded && (
        <div className="space-y-3 pt-2 border-t">
          {/* Critical Warnings */}
          {profile.critical_warnings && profile.critical_warnings.length > 0 && (
            <div>
              <p className="text-xs font-semibold text-gray-900 mb-1">🚨 Kritische Warnungen:</p>
              <div className="space-y-1">
                {profile.critical_warnings.slice(0, 3).map((w, i) => (
                  <div key={i} className="text-xs bg-red-50 border border-red-200 rounded p-2">
                    <p className={`font-semibold ${severityColors[w.severity]}`}>
                      [{w.severity.toUpperCase()}] {w.warning}
                    </p>
                    <p className="text-gray-600 text-[10px] mt-0.5">→ {w.action}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Contraindications */}
          {profile.contraindications && profile.contraindications.length > 0 && (
            <div>
              <p className="text-xs font-semibold text-gray-900 mb-1">🚫 Kontraindikationen:</p>
              <ul className="text-xs text-gray-700 space-y-0.5 ml-4 list-disc">
                {profile.contraindications.slice(0, 3).map((c, i) => (
                  <li key={i}>{c}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Top Immediate Actions */}
          {profile.immediate_actions && profile.immediate_actions.length > 0 && (
            <div>
              <p className="text-xs font-semibold text-gray-900 mb-1">✅ Top-Maßnahmen:</p>
              <ol className="text-xs text-gray-700 space-y-1 ml-4 list-decimal">
                {profile.immediate_actions
                  .sort((a, b) => a.priority - b.priority)
                  .slice(0, 3)
                  .map((a, i) => (
                    <li key={i}>
                      <span className="font-medium">{a.action}</span>
                      <p className="text-[10px] text-gray-600">{a.rationale}</p>
                    </li>
                  ))}
              </ol>
            </div>
          )}
        </div>
      )}
    </div>
  );
}