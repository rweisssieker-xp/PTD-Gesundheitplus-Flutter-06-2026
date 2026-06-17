import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { 
  Brain, 
  AlertCircle, 
  CheckCircle, 
  Activity, 
  Pill,
  Calendar,
  TrendingUp,
  Clock,
  AlertTriangle,
  Info,
  ChevronRight
} from "lucide-react";

/**
 * MedicalInsights Component
 * Displays AI-generated insights and medical entities from scanned documents
 * 
 * @param {Object} document - The document containing medical data
 * @param {Function} onActionClick - Callback when an action is clicked
 */
export default function MedicalInsights({ document, onActionClick }) {
  // Early return if no insights available
  if (!document?.ai_insights && !document?.medical_entities && !document?.suggested_actions) {
    return null;
  }

  const { ai_insights, medical_entities, suggested_actions } = document;

  // Configuration for urgency levels
  const urgencyConfig = {
    low: { color: "bg-blue-100 text-blue-800 border-blue-200", icon: Info },
    medium: { color: "bg-yellow-100 text-yellow-800 border-yellow-200", icon: Clock },
    high: { color: "bg-orange-100 text-orange-800 border-orange-200", icon: AlertTriangle },
    urgent: { color: "bg-red-100 text-red-800 border-red-200", icon: AlertCircle }
  };

  const urgencyInfo = urgencyConfig[ai_insights?.urgency_level] || urgencyConfig.low;
  const UrgencyIcon = urgencyInfo.icon;

  // Configuration for action types
  const actionTypeConfig = {
    schedule_appointment: { icon: Calendar, label: "Termin vereinbaren", color: "text-blue-600" },
    add_medication: { icon: Pill, label: "Medikament hinzufügen", color: "text-orange-600" },
    update_allergy: { icon: AlertCircle, label: "Allergie aktualisieren", color: "text-red-600" },
    add_vaccination: { icon: Activity, label: "Impfung hinzufügen", color: "text-purple-600" },
    follow_up: { icon: Clock, label: "Nachverfolgung", color: "text-indigo-600" },
    contact_doctor: { icon: AlertTriangle, label: "Arzt kontaktieren", color: "text-red-600" },
    lifestyle_change: { icon: TrendingUp, label: "Lebensstil", color: "text-green-600" }
  };

  // Configuration for lab result statuses
  const labStatusIcons = {
    normal: { icon: CheckCircle, color: "text-green-600" },
    abnormal: { icon: AlertCircle, color: "text-orange-600" },
    critical: { icon: AlertTriangle, color: "text-red-600" }
  };

  return (
    <div className="space-y-4">
      {/* AI Summary Section */}
      {ai_insights && (
        <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-pink-50">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Brain className="h-5 w-5 text-purple-600" />
              KI-Analyse
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {ai_insights.summary && (
              <div>
                <p className="text-sm text-gray-700 leading-relaxed">{ai_insights.summary}</p>
              </div>
            )}

            {ai_insights.urgency_level && (
              <div className={`flex items-center gap-2 p-3 rounded-lg border-2 ${urgencyInfo.color}`}>
                <UrgencyIcon className="h-5 w-5 flex-shrink-0" />
                <div>
                  <p className="text-sm font-semibold">
                    Dringlichkeit: {
                      ai_insights.urgency_level === 'urgent' ? 'Dringend' :
                      ai_insights.urgency_level === 'high' ? 'Hoch' :
                      ai_insights.urgency_level === 'medium' ? 'Mittel' : 'Niedrig'
                    }
                  </p>
                  {ai_insights.requires_attention && (
                    <p className="text-xs mt-1">Erfordert Ihre Aufmerksamkeit</p>
                  )}
                </div>
              </div>
            )}

            {ai_insights.key_findings && Array.isArray(ai_insights.key_findings) && ai_insights.key_findings.length > 0 && (
              <div>
                <p className="text-sm font-semibold text-gray-900 mb-2">Wichtigste Erkenntnisse:</p>
                <ul className="space-y-2">
                  {ai_insights.key_findings.map((finding, idx) => (
                    <li key={idx} className="flex items-start gap-2 text-sm text-gray-700">
                      <CheckCircle className="h-4 w-4 text-purple-600 mt-0.5 flex-shrink-0" />
                      <span>{finding}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Medical Entities Sections */}
      {medical_entities && (
        <>
          {/* Diagnoses */}
          {medical_entities.diagnoses && Array.isArray(medical_entities.diagnoses) && medical_entities.diagnoses.length > 0 && (
            <Card className="border-2">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Activity className="h-5 w-5 text-red-600" />
                  Diagnosen
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {medical_entities.diagnoses.map((diagnosis, idx) => (
                    <div key={idx} className="p-3 bg-gray-50 rounded-lg">
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className="font-semibold text-gray-900">{diagnosis.condition || 'Nicht angegeben'}</p>
                          {diagnosis.icd_code && (
                            <p className="text-xs text-gray-600 mt-1">ICD-Code: {diagnosis.icd_code}</p>
                          )}
                        </div>
                        {diagnosis.severity && (
                          <Badge variant="outline">{diagnosis.severity}</Badge>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Medications */}
          {medical_entities.medications && Array.isArray(medical_entities.medications) && medical_entities.medications.length > 0 && (
            <Card className="border-2">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Pill className="h-5 w-5 text-orange-600" />
                  Medikamente
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {medical_entities.medications.map((med, idx) => (
                    <div key={idx} className="p-3 bg-orange-50 rounded-lg border border-orange-200">
                      <p className="font-semibold text-gray-900">{med.name || 'Nicht angegeben'}</p>
                      <div className="mt-1 space-y-1">
                        {med.dosage && (
                          <p className="text-sm text-gray-700">Dosierung: {med.dosage}</p>
                        )}
                        {med.frequency && (
                          <p className="text-sm text-gray-700">Häufigkeit: {med.frequency}</p>
                        )}
                        {med.duration && (
                          <p className="text-sm text-gray-700">Dauer: {med.duration}</p>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Lab Results */}
          {medical_entities.lab_results && Array.isArray(medical_entities.lab_results) && medical_entities.lab_results.length > 0 && (
            <Card className="border-2">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Activity className="h-5 w-5 text-blue-600" />
                  Laborwerte
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {medical_entities.lab_results.map((result, idx) => {
                    const statusInfo = labStatusIcons[result.status] || labStatusIcons.normal;
                    const StatusIcon = statusInfo.icon;
                    
                    return (
                      <div key={idx} className="p-3 bg-blue-50 rounded-lg border border-blue-200">
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex-1">
                            <p className="font-semibold text-gray-900">{result.test_name || 'Nicht angegeben'}</p>
                            <div className="mt-1">
                              <p className="text-sm text-gray-700">
                                Wert: <span className="font-semibold">{result.value} {result.unit || ''}</span>
                              </p>
                              {result.reference_range && (
                                <p className="text-xs text-gray-600">
                                  Referenzbereich: {result.reference_range}
                                </p>
                              )}
                            </div>
                          </div>
                          <StatusIcon className={`h-5 w-5 ${statusInfo.color} flex-shrink-0`} />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Procedures */}
          {medical_entities.procedures && Array.isArray(medical_entities.procedures) && medical_entities.procedures.length > 0 && (
            <Card className="border-2">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Activity className="h-5 w-5 text-indigo-600" />
                  Prozeduren
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2">
                  {medical_entities.procedures.map((procedure, idx) => (
                    <li key={idx} className="flex items-start gap-2 text-sm text-gray-700">
                      <CheckCircle className="h-4 w-4 text-indigo-600 mt-0.5 flex-shrink-0" />
                      <span>{procedure}</span>
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
          )}

          {/* Allergies */}
          {medical_entities.allergies && Array.isArray(medical_entities.allergies) && medical_entities.allergies.length > 0 && (
            <Card className="border-2 border-red-200 bg-red-50">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2 text-red-900">
                  <AlertCircle className="h-5 w-5 text-red-600" />
                  Allergien
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {medical_entities.allergies.map((allergy, idx) => (
                    <Badge key={idx} className="bg-red-600">
                      {allergy}
                    </Badge>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Vaccinations */}
          {medical_entities.vaccinations && Array.isArray(medical_entities.vaccinations) && medical_entities.vaccinations.length > 0 && (
            <Card className="border-2">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Activity className="h-5 w-5 text-purple-600" />
                  Impfungen
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {medical_entities.vaccinations.map((vacc, idx) => (
                    <div key={idx} className="p-3 bg-purple-50 rounded-lg border border-purple-200">
                      <p className="font-semibold text-gray-900">{vacc.vaccine || 'Nicht angegeben'}</p>
                      {vacc.date && (
                        <p className="text-sm text-gray-700 mt-1">Datum: {vacc.date}</p>
                      )}
                      {vacc.batch_number && (
                        <p className="text-xs text-gray-600 mt-1">Charge: {vacc.batch_number}</p>
                      )}
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </>
      )}

      {/* Suggested Actions */}
      {suggested_actions && Array.isArray(suggested_actions) && suggested_actions.length > 0 && (
        <Card className="border-2 border-green-200 bg-gradient-to-br from-green-50 to-emerald-50">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              Empfohlene Aktionen
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {suggested_actions
                .filter(action => action && !action.completed)
                .sort((a, b) => {
                  const priorityOrder = { high: 0, medium: 1, low: 2 };
                  return (priorityOrder[a.priority] || 2) - (priorityOrder[b.priority] || 2);
                })
                .map((action, idx) => {
                  const config = actionTypeConfig[action.action_type] || {};
                  const ActionIcon = config.icon || ChevronRight;
                  const priorityColors = {
                    high: "border-red-300 bg-red-50",
                    medium: "border-yellow-300 bg-yellow-50",
                    low: "border-blue-300 bg-blue-50"
                  };

                  return (
                    <div
                      key={idx}
                      className={`p-4 rounded-lg border-2 ${priorityColors[action.priority] || priorityColors.low}`}
                    >
                      <div className="flex items-start gap-3">
                        <ActionIcon className={`h-5 w-5 ${config.color || 'text-gray-600'} mt-0.5 flex-shrink-0`} />
                        <div className="flex-1">
                          <div className="flex items-start justify-between gap-2 mb-1">
                            <p className="font-semibold text-gray-900">{config.label || 'Aktion'}</p>
                            <Badge variant="outline" className="text-xs">
                              {action.priority === 'high' ? 'Wichtig' : 
                               action.priority === 'medium' ? 'Normal' : 'Niedrig'}
                            </Badge>
                          </div>
                          <p className="text-sm text-gray-700">{action.description || 'Keine Beschreibung'}</p>
                          {onActionClick && (
                            <Button
                              onClick={() => onActionClick(action)}
                              size="sm"
                              className="mt-3"
                            >
                              Aktion ausführen
                              <ChevronRight className="h-4 w-4 ml-1" />
                            </Button>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}