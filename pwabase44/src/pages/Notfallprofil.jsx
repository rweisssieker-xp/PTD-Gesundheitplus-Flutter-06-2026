/**
 * Emergency Profile Viewer Page
 * Displays comprehensive AI-generated emergency profile
 */

import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { 
  Brain, 
  Shield, 
  AlertTriangle,
  Activity,
  Download,
  RefreshCw,
  ChevronDown,
  ChevronUp,
  AlertCircle,
  CheckCircle,
  FileText,
  Pill,
  Ban,
  Zap
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";

export default function NotfallprofilPage() {
  const [profile, setProfile] = useState(null);
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [expandedSections, setExpandedSections] = useState({
    warnings: true,
    contraindications: true,
    interactions: false,
    actions: true,
    risks: false,
    transport: false
  });

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    setIsLoading(true);
    try {
      const userData = await base44.auth.me();
      setUser(userData);
      
      if (userData.emergency_profile) {
        setProfile(userData.emergency_profile);
      }
    } catch (error) {
      console.error('Error loading profile:', error);
      toast.error('Fehler beim Laden des Profils');
    } finally {
      setIsLoading(false);
    }
  };

  const toggleSection = (section) => {
    setExpandedSections(prev => ({
      ...prev,
      [section]: !prev[section]
    }));
  };

  const downloadProfile = () => {
    if (!profile) return;

    const profileText = formatProfileForDownload(profile, user);
    const blob = new Blob([profileText], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `notfallprofil_${user?.full_name?.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.txt`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success('Profil heruntergeladen');
  };

  const formatProfileForDownload = (profile, user) => {
    let text = '═══════════════════════════════════════\n';
    text += '   NOTFALL-PROFIL FÜR ERSTHELFER\n';
    text += '═══════════════════════════════════════\n\n';
    
    if (user) {
      text += `Patient: ${user.full_name || 'Unbekannt'}\n`;
      if (user.date_of_birth) {
        const age = Math.floor((new Date() - new Date(user.date_of_birth)) / 31557600000);
        text += `Alter: ${age} Jahre\n`;
      }
      if (user.gender) text += `Geschlecht: ${user.gender}\n`;
      text += '\n';
    }

    text += `KI-Profil Version: ${profile.version}\n`;
    text += `Erstellt: ${new Date(profile.generated_at).toLocaleString('de-DE')}\n\n`;

    text += '═══════════════════════════════════════\n';
    text += '📋 ZUSAMMENFASSUNG\n';
    text += '═══════════════════════════════════════\n\n';
    text += profile.summary + '\n\n';

    if (profile.risk_assessment) {
      text += '═══════════════════════════════════════\n';
      text += '📊 RISIKOBEWERTUNG\n';
      text += '═══════════════════════════════════════\n\n';
      text += `Gesamt-Risiko: ${profile.risk_assessment.overall_risk_level?.toUpperCase() || 'UNBEKANNT'}\n\n`;
    }

    if (profile.critical_warnings && profile.critical_warnings.length > 0) {
      text += '═══════════════════════════════════════\n';
      text += '🚨 KRITISCHE WARNUNGEN\n';
      text += '═══════════════════════════════════════\n\n';
      profile.critical_warnings.forEach((w, i) => {
        text += `${i + 1}. [${w.severity.toUpperCase()}] ${w.warning}\n`;
        text += `   → Maßnahme: ${w.action}\n\n`;
      });
    }

    if (profile.contraindications && profile.contraindications.length > 0) {
      text += '═══════════════════════════════════════\n';
      text += '🚫 ABSOLUTE KONTRAINDIKATIONEN\n';
      text += '═══════════════════════════════════════\n\n';
      profile.contraindications.forEach((c, i) => {
        text += `${i + 1}. ${c}\n`;
      });
      text += '\n';
    }

    if (profile.medication_interactions && profile.medication_interactions.length > 0) {
      text += '═══════════════════════════════════════\n';
      text += '💊 MEDIKAMENTEN-INTERAKTIONEN\n';
      text += '═══════════════════════════════════════\n\n';
      profile.medication_interactions.forEach((m, i) => {
        text += `${i + 1}. ${m.emergency_drug} [${m.severity.toUpperCase()}]\n`;
        text += `   Interaktion: ${m.interaction}\n`;
        text += `   Empfehlung: ${m.recommendation}\n\n`;
      });
    }

    if (profile.immediate_actions && profile.immediate_actions.length > 0) {
      text += '═══════════════════════════════════════\n';
      text += '✅ EMPFOHLENE SOFORTMASSNAHMEN\n';
      text += '═══════════════════════════════════════\n\n';
      profile.immediate_actions
        .sort((a, b) => a.priority - b.priority)
        .forEach((a) => {
          text += `${a.priority}. ${a.action}\n`;
          text += `   Begründung: ${a.rationale}\n\n`;
        });
    }

    if (profile.risk_assessment?.specific_risks && profile.risk_assessment.specific_risks.length > 0) {
      text += '═══════════════════════════════════════\n';
      text += '⚠️ SPEZIFISCHE RISIKEN\n';
      text += '═══════════════════════════════════════\n\n';
      profile.risk_assessment.specific_risks.forEach((r, i) => {
        text += `${i + 1}. ${r.risk}\n`;
        text += `   Wahrscheinlichkeit: ${r.likelihood} | Auswirkung: ${r.impact}\n\n`;
      });
    }

    if (profile.transport_considerations && profile.transport_considerations.length > 0) {
      text += '═══════════════════════════════════════\n';
      text += '🚑 TRANSPORT-ÜBERLEGUNGEN\n';
      text += '═══════════════════════════════════════\n\n';
      profile.transport_considerations.forEach((t, i) => {
        text += `${i + 1}. ${t}\n`;
      });
      text += '\n';
    }

    if (profile.communication_aids) {
      text += '═══════════════════════════════════════\n';
      text += '💬 KOMMUNIKATIONSHILFEN\n';
      text += '═══════════════════════════════════════\n\n';
      
      if (profile.communication_aids.patient_can_communicate !== undefined) {
        text += `Kann kommunizieren: ${profile.communication_aids.patient_can_communicate ? 'JA' : 'NEIN'}\n`;
      }
      
      if (profile.communication_aids.language_barriers && profile.communication_aids.language_barriers.length > 0) {
        text += `Sprachbarrieren: ${profile.communication_aids.language_barriers.join(', ')}\n`;
      }
      
      if (profile.communication_aids.cognitive_considerations) {
        text += `Kognitive Aspekte: ${profile.communication_aids.cognitive_considerations}\n`;
      }
      text += '\n';
    }

    text += '═══════════════════════════════════════\n';
    text += 'Generiert von: Gesundheit Plus AI\n';
    text += 'Für medizinisches Fachpersonal\n';
    text += '═══════════════════════════════════════\n';

    return text;
  };

  const riskColors = {
    low: 'border-green-200 bg-green-50 text-green-900',
    moderate: 'border-yellow-200 bg-yellow-50 text-yellow-900',
    high: 'border-orange-200 bg-orange-50 text-orange-900',
    critical: 'border-red-200 bg-red-50 text-red-900'
  };

  const severityIcons = {
    critical: <AlertTriangle className="h-5 w-5 text-red-600" />,
    major: <AlertCircle className="h-5 w-5 text-orange-600" />,
    high: <AlertCircle className="h-5 w-5 text-orange-600" />,
    moderate: <AlertCircle className="h-5 w-5 text-yellow-600" />,
    medium: <AlertCircle className="h-5 w-5 text-yellow-600" />,
    minor: <AlertCircle className="h-5 w-5 text-blue-600" />
  };

  if (isLoading) {
    return (
      <div className="p-6 pb-24">
        <div className="max-w-4xl mx-auto">
          <div className="text-center py-12">
            <div className="animate-spin h-12 w-12 border-4 border-purple-600 border-t-transparent rounded-full mx-auto mb-4"></div>
            <p className="text-gray-600">Lade Notfallprofil...</p>
          </div>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="p-6 pb-24">
        <div className="max-w-4xl mx-auto">
          <Card className="border-2 border-purple-200">
            <CardContent className="pt-6">
              <div className="text-center py-12">
                <div className="h-20 w-20 rounded-full bg-purple-100 flex items-center justify-center mx-auto mb-4">
                  <FileText className="h-10 w-10 text-purple-600" />
                </div>
                <h2 className="text-xl font-bold text-gray-900 mb-2">
                  Kein Notfallprofil vorhanden
                </h2>
                <p className="text-gray-600 mb-6">
                  Erstellen Sie ein KI-generiertes Notfallprofil in der Notfall-Einrichtung
                </p>
                <Button
                  onClick={() => window.location.href = '/Notfall-Einrichtung'}
                  className="bg-purple-600 hover:bg-purple-700"
                >
                  <Zap className="h-4 w-4 mr-2" />
                  Zur Notfall-Einrichtung
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  const profileAge = Math.floor((new Date() - new Date(profile.generated_at)) / (1000 * 60 * 60 * 24));
  const isOutdated = profileAge > 90;

  return (
    <div className="p-6 space-y-6 pb-24">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2 flex items-center gap-2">
              <Brain className="h-7 w-7 text-purple-600" />
              KI-Notfallprofil
            </h1>
            <p className="text-gray-600">
              Für Ersthelfer und medizinisches Fachpersonal
            </p>
            <p className="text-xs text-gray-500 mt-1">
              Erstellt: {new Date(profile.generated_at).toLocaleDateString('de-DE')} (vor {profileAge} Tagen)
              {isOutdated && ' • ⚠️ Aktualisierung empfohlen'}
            </p>
          </div>
          <div className="flex gap-2">
            <Button onClick={downloadProfile} variant="outline" size="sm">
              <Download className="h-4 w-4 mr-2" />
              Download
            </Button>
            <Button onClick={() => window.location.href = '/Notfall-Einrichtung'} variant="outline" size="sm">
              <RefreshCw className="h-4 w-4 mr-2" />
              Aktualisieren
            </Button>
          </div>
        </div>

        {/* Risk Assessment Banner */}
        {profile.risk_assessment && (
          <Card className={`border-2 ${riskColors[profile.risk_assessment.overall_risk_level]}`}>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <Activity className="h-8 w-8" />
                <div className="flex-1">
                  <p className="text-sm font-semibold mb-1">Gesamt-Risikobewertung</p>
                  <p className="text-2xl font-bold">
                    {profile.risk_assessment.overall_risk_level?.toUpperCase() || 'UNBEKANNT'}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Summary */}
        <Card className="border-2 border-blue-200 bg-blue-50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <FileText className="h-5 w-5" />
              Zusammenfassung
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-gray-900">{profile.summary}</p>
          </CardContent>
        </Card>

        {/* Critical Warnings */}
        {profile.critical_warnings && profile.critical_warnings.length > 0 && (
          <Card className="border-2 border-red-200">
            <CardHeader className="cursor-pointer" onClick={() => toggleSection('warnings')}>
              <CardTitle className="flex items-center justify-between text-lg">
                <div className="flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5 text-red-600" />
                  Kritische Warnungen ({profile.critical_warnings.length})
                </div>
                {expandedSections.warnings ? <ChevronUp className="h-5 w-5" /> : <ChevronDown className="h-5 w-5" />}
              </CardTitle>
            </CardHeader>
            {expandedSections.warnings && (
              <CardContent className="space-y-3">
                {profile.critical_warnings.map((warning, index) => (
                  <div key={index} className="bg-red-50 border-l-4 border-red-600 p-4 rounded">
                    <div className="flex gap-3">
                      {severityIcons[warning.severity]}
                      <div className="flex-1">
                        <p className="font-semibold text-red-900 mb-1">
                          [{warning.severity.toUpperCase()}] {warning.warning}
                        </p>
                        <p className="text-sm text-red-800">
                          → <strong>Maßnahme:</strong> {warning.action}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </CardContent>
            )}
          </Card>
        )}

        {/* Contraindications */}
        {profile.contraindications && profile.contraindications.length > 0 && (
          <Card className="border-2 border-orange-200">
            <CardHeader className="cursor-pointer" onClick={() => toggleSection('contraindications')}>
              <CardTitle className="flex items-center justify-between text-lg">
                <div className="flex items-center gap-2">
                  <Ban className="h-5 w-5 text-orange-600" />
                  Absolute Kontraindikationen ({profile.contraindications.length})
                </div>
                {expandedSections.contraindications ? <ChevronUp className="h-5 w-5" /> : <ChevronDown className="h-5 w-5" />}
              </CardTitle>
            </CardHeader>
            {expandedSections.contraindications && (
              <CardContent>
                <ul className="space-y-2">
                  {profile.contraindications.map((contra, index) => (
                    <li key={index} className="flex items-start gap-2 text-gray-900">
                      <CheckCircle className="h-5 w-5 text-orange-600 flex-shrink-0 mt-0.5" />
                      <span>{contra}</span>
                    </li>
                  ))}
                </ul>
              </CardContent>
            )}
          </Card>
        )}

        {/* Medication Interactions */}
        {profile.medication_interactions && profile.medication_interactions.length > 0 && (
          <Card className="border-2 border-yellow-200">
            <CardHeader className="cursor-pointer" onClick={() => toggleSection('interactions')}>
              <CardTitle className="flex items-center justify-between text-lg">
                <div className="flex items-center gap-2">
                  <Pill className="h-5 w-5 text-yellow-600" />
                  Medikamenten-Interaktionen ({profile.medication_interactions.length})
                </div>
                {expandedSections.interactions ? <ChevronUp className="h-5 w-5" /> : <ChevronDown className="h-5 w-5" />}
              </CardTitle>
            </CardHeader>
            {expandedSections.interactions && (
              <CardContent className="space-y-3">
                {profile.medication_interactions.map((interaction, index) => (
                  <div key={index} className="bg-yellow-50 border border-yellow-200 rounded p-4">
                    <div className="flex items-start gap-3 mb-2">
                      {severityIcons[interaction.severity]}
                      <div className="flex-1">
                        <p className="font-semibold text-yellow-900">
                          {interaction.emergency_drug} <span className="text-sm">({interaction.severity.toUpperCase()})</span>
                        </p>
                      </div>
                    </div>
                    <p className="text-sm text-gray-900 ml-8 mb-2">
                      <strong>Interaktion:</strong> {interaction.interaction}
                    </p>
                    <p className="text-sm text-gray-900 ml-8">
                      <strong>Empfehlung:</strong> {interaction.recommendation}
                    </p>
                  </div>
                ))}
              </CardContent>
            )}
          </Card>
        )}

        {/* Immediate Actions */}
        {profile.immediate_actions && profile.immediate_actions.length > 0 && (
          <Card className="border-2 border-green-200">
            <CardHeader className="cursor-pointer" onClick={() => toggleSection('actions')}>
              <CardTitle className="flex items-center justify-between text-lg">
                <div className="flex items-center gap-2">
                  <Zap className="h-5 w-5 text-green-600" />
                  Empfohlene Sofortmaßnahmen ({profile.immediate_actions.length})
                </div>
                {expandedSections.actions ? <ChevronUp className="h-5 w-5" /> : <ChevronDown className="h-5 w-5" />}
              </CardTitle>
            </CardHeader>
            {expandedSections.actions && (
              <CardContent>
                <ol className="space-y-3">
                  {profile.immediate_actions
                    .sort((a, b) => a.priority - b.priority)
                    .map((action, index) => (
                      <li key={index} className="flex gap-3">
                        <div className="h-7 w-7 rounded-full bg-green-600 text-white flex items-center justify-center flex-shrink-0 font-bold">
                          {action.priority}
                        </div>
                        <div className="flex-1">
                          <p className="font-semibold text-gray-900 mb-1">{action.action}</p>
                          <p className="text-sm text-gray-600">
                            <em>Begründung:</em> {action.rationale}
                          </p>
                        </div>
                      </li>
                    ))}
                </ol>
              </CardContent>
            )}
          </Card>
        )}

        {/* Specific Risks */}
        {profile.risk_assessment?.specific_risks && profile.risk_assessment.specific_risks.length > 0 && (
          <Card className="border-2 border-gray-200">
            <CardHeader className="cursor-pointer" onClick={() => toggleSection('risks')}>
              <CardTitle className="flex items-center justify-between text-lg">
                <div className="flex items-center gap-2">
                  <Activity className="h-5 w-5 text-gray-600" />
                  Spezifische Risiken ({profile.risk_assessment.specific_risks.length})
                </div>
                {expandedSections.risks ? <ChevronUp className="h-5 w-5" /> : <ChevronDown className="h-5 w-5" />}
              </CardTitle>
            </CardHeader>
            {expandedSections.risks && (
              <CardContent className="space-y-2">
                {profile.risk_assessment.specific_risks.map((risk, index) => (
                  <div key={index} className="bg-gray-50 border border-gray-200 rounded p-3">
                    <p className="font-semibold text-gray-900 mb-1">{risk.risk}</p>
                    <div className="flex gap-4 text-sm text-gray-600">
                      <span>Wahrscheinlichkeit: <strong>{risk.likelihood}</strong></span>
                      <span>•</span>
                      <span>Auswirkung: <strong>{risk.impact}</strong></span>
                    </div>
                  </div>
                ))}
              </CardContent>
            )}
          </Card>
        )}

        {/* Transport Considerations */}
        {profile.transport_considerations && profile.transport_considerations.length > 0 && (
          <Card className="border-2 border-blue-200">
            <CardHeader className="cursor-pointer" onClick={() => toggleSection('transport')}>
              <CardTitle className="flex items-center justify-between text-lg">
                <div className="flex items-center gap-2">
                  <Shield className="h-5 w-5 text-blue-600" />
                  Transport-Überlegungen ({profile.transport_considerations.length})
                </div>
                {expandedSections.transport ? <ChevronUp className="h-5 w-5" /> : <ChevronDown className="h-5 w-5" />}
              </CardTitle>
            </CardHeader>
            {expandedSections.transport && (
              <CardContent>
                <ul className="space-y-2">
                  {profile.transport_considerations.map((consideration, index) => (
                    <li key={index} className="flex items-start gap-2 text-gray-900">
                      <CheckCircle className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
                      <span>{consideration}</span>
                    </li>
                  ))}
                </ul>
              </CardContent>
            )}
          </Card>
        )}

        {/* Footer Info */}
        <Card className="border-2 border-purple-200 bg-purple-50">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <AlertCircle className="h-5 w-5 text-purple-600 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-purple-900">
                <p className="font-semibold mb-1">Wichtiger Hinweis</p>
                <p className="text-xs">
                  Dieses Profil wurde durch künstliche Intelligenz generiert und dient als Orientierungshilfe für
                  medizinisches Fachpersonal. Es ersetzt nicht die professionelle medizinische Beurteilung vor Ort.
                  Aktualisieren Sie das Profil regelmäßig bei Änderungen Ihrer medizinischen Situation.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}