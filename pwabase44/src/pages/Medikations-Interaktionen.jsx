import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Shield, AlertTriangle, Info } from "lucide-react";
import { useNavigate } from "react-router-dom";
import MedicationInteractionChecker from "../components/MedicationInteractionChecker";

export default function MedikationsInteraktionenPage() {
  const navigate = useNavigate();

  const { data: medications = [], isLoading } = useQuery({
    queryKey: ['medications'],
    queryFn: () => base44.entities.Medication.filter({ active: true })
  });

  return (
    <div className="p-6 space-y-6 pb-24">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Medikations-Wechselwirkungen
        </h1>
        <p className="text-gray-600">
          KI-gestützte Prüfung Ihrer Medikamente auf gefährliche Wechselwirkungen
        </p>
      </div>

      {/* Info Cards */}
      <div className="grid gap-4">
        <Card className="border-2 border-blue-200 bg-blue-50">
          <CardContent className="pt-6 space-y-2">
            <div className="flex items-start gap-3">
              <Shield className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
              <div className="space-y-1">
                <p className="font-semibold text-blue-900">Sicherheit zuerst</p>
                <p className="text-sm text-blue-800">
                  Unsere KI analysiert Ihre aktiven Medikamente und warnt vor gefährlichen Kombinationen
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-2 border-amber-200 bg-amber-50">
          <CardContent className="pt-6 space-y-2">
            <div className="flex items-start gap-3">
              <AlertTriangle className="h-5 w-5 text-amber-600 flex-shrink-0 mt-0.5" />
              <div className="space-y-1">
                <p className="font-semibold text-amber-900">Was wird geprüft?</p>
                <ul className="text-sm text-amber-800 space-y-1">
                  <li>• Kritische Wechselwirkungen (lebensbedrohlich)</li>
                  <li>• Wichtige Wechselwirkungen (ernsthaft)</li>
                  <li>• Moderate Wechselwirkungen (Vorsicht)</li>
                  <li>• Dosierungsempfehlungen</li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>

        {medications.length < 2 && (
          <Card className="border-2 border-gray-200">
            <CardContent className="pt-6">
              <div className="flex items-start gap-3">
                <Info className="h-5 w-5 text-gray-600 flex-shrink-0 mt-0.5" />
                <div className="space-y-2">
                  <p className="font-semibold text-gray-900">Hinweis</p>
                  <p className="text-sm text-gray-700">
                    Sie haben aktuell {medications.length} aktive{medications.length === 1 ? 's' : ''} Medikament{medications.length !== 1 ? 'e' : ''}.
                    Für eine Wechselwirkungsprüfung benötigen Sie mindestens 2 aktive Medikamente.
                  </p>
                  <Button
                    onClick={() => navigate('/Medikation')}
                    variant="outline"
                    size="sm"
                    className="mt-2"
                  >
                    Medikamente verwalten
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Interaction Checker */}
      {isLoading ? (
        <Card>
          <CardContent className="pt-6 text-center text-gray-600">
            Lade Medikamente...
          </CardContent>
        </Card>
      ) : (
        <MedicationInteractionChecker 
          medications={medications}
          autoCheck={medications.length >= 2}
        />
      )}

      {/* Active Medications List */}
      {medications.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">
              Ihre aktiven Medikamente ({medications.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {medications.map((med) => (
                <div 
                  key={med.id}
                  className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                >
                  <div>
                    <p className="font-semibold text-gray-900">{med.name}</p>
                    <p className="text-sm text-gray-600">
                      {med.dosage} • {med.frequency}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}