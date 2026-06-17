import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { createPageUrl } from "@/utils";
import DocumentScanner from "../components/DocumentScanner";
import MedicalInsights from "../components/MedicalInsights";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { 
  Stethoscope, 
  Pill, 
  Calendar, 
  Syringe,
  FileText,
  AlertCircle,
  Save,
  FolderOpen,
  Brain,
  ChevronDown,
  ChevronUp
} from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { base44 } from "@/api/base44Client";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

const documentTypes = [
  {
    type: "Arztbrief",
    icon: Stethoscope,
    color: "from-green-500 to-green-600"
  },
  {
    type: "Rezept",
    icon: Pill,
    color: "from-orange-500 to-orange-600"
  },
  {
    type: "Laborbefund",
    icon: FileText,
    color: "from-blue-500 to-blue-600"
  },
  {
    type: "Terminkarte",
    icon: Calendar,
    color: "from-red-500 to-red-600"
  },
  {
    type: "Impfpass",
    icon: Syringe,
    color: "from-purple-500 to-purple-600"
  },
  {
    type: "Allergiepass",
    icon: AlertCircle,
    color: "from-yellow-500 to-yellow-600"
  }
];

export default function DokumentenScanPage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [selectedType, setSelectedType] = useState(null);
  const [scannedData, setScannedData] = useState(null);
  const [showAdvancedForm, setShowAdvancedForm] = useState(false);
  const [formData, setFormData] = useState({
    title: "",
    document_date: "",
    related_doctor: "",
    tags: "",
    notes: ""
  });

  const saveMutation = useMutation({
    mutationFn: (data) => base44.entities.ScannedDocument.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['scanned-documents'] });
      toast.success("Dokument erfolgreich gespeichert!");
      navigate(createPageUrl("Gescannte-Dokumente"));
    },
    onError: () => {
      toast.error("Fehler beim Speichern des Dokuments");
    }
  });

  const handleScanComplete = (data) => {
    setScannedData(data);
    
    // Pre-fill form with extracted data
    if (data.extractedData) {
      const extracted = data.extractedData;
      setFormData({
        title: extracted.suggested_title || "",
        document_date: extracted.document_date || "",
        related_doctor: extracted.doctor_name || "",
        tags: extracted.tags?.join(", ") || "",
        notes: ""
      });
    }
  };

  const handleExecuteAction = async (action) => {
    const { action_type, related_data } = action;

    try {
      switch (action_type) {
        case 'add_medication':
          if (related_data) {
            await base44.entities.Medication.create({
              name: related_data.name,
              dosage: related_data.dosage,
              frequency: related_data.frequency,
              active: true,
              prescribed_by: formData.related_doctor,
              start_date: formData.document_date || new Date().toISOString().split('T')[0]
            });
            toast.success("Medikament hinzugefügt!");
          }
          break;

        case 'schedule_appointment':
          navigate(createPageUrl("Termine"));
          toast.info("Bitte Termin manuell eintragen");
          break;

        case 'update_allergy':
          if (related_data?.allergen) {
            await base44.entities.Allergy.create({
              allergen: related_data.allergen,
              severity: related_data.severity || "Mittel",
              category: "Sonstige"
            });
            toast.success("Allergie hinzugefügt!");
          }
          break;

        case 'add_vaccination':
          if (related_data) {
            await base44.entities.Vaccination.create({
              vaccine_name: related_data.vaccine,
              date_given: related_data.date || formData.document_date,
              batch_number: related_data.batch_number
            });
            toast.success("Impfung hinzugefügt!");
          }
          break;

        default:
          toast.info("Diese Aktion muss manuell durchgeführt werden");
      }

      // Mark action as completed in the document
      const updatedActions = scannedData.extractedData.suggested_actions.map(a =>
        a === action ? { ...a, completed: true } : a
      );
      setScannedData({
        ...scannedData,
        extractedData: {
          ...scannedData.extractedData,
          suggested_actions: updatedActions
        }
      });
    } catch (error) {
      toast.error("Fehler beim Ausführen der Aktion");
      console.error(error);
    }
  };

  const handleSave = () => {
    if (!scannedData || !formData.title) {
      toast.error("Bitte füllen Sie mindestens den Titel aus");
      return;
    }

    const extracted = scannedData.extractedData;
    const documentData = {
      title: formData.title,
      document_type: extracted?.document_type || selectedType?.type || "Sonstiges",
      document_date: formData.document_date || new Date().toISOString().split('T')[0],
      image_url: scannedData.imageUrl,
      extracted_text: extracted?.full_text || "",
      medical_entities: extracted?.medical_entities || {},
      ai_insights: extracted?.ai_insights || {},
      suggested_actions: extracted?.suggested_actions || [],
      related_doctor: formData.related_doctor,
      tags: formData.tags.split(",").map(tag => tag.trim()).filter(Boolean),
      notes: formData.notes
    };

    saveMutation.mutate(documentData);
  };

  return (
    <div className="p-6 space-y-6 pb-24">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Dokument scannen</h1>
        <p className="text-gray-600">
          Fotografieren Sie Ihre Gesundheitsdokumente - die KI analysiert sie automatisch.
        </p>
      </div>

      {!selectedType ? (
        <>
          <Card>
            <CardHeader>
              <CardTitle>Was möchten Sie scannen?</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid gap-3">
                {documentTypes.map((docType) => {
                  const Icon = docType.icon;
                  return (
                    <Button
                      key={docType.type}
                      onClick={() => setSelectedType(docType)}
                      variant="outline"
                      className="w-full h-20 justify-start border-2 hover:border-gray-400"
                    >
                      <div className="flex items-center gap-4">
                        <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${docType.color} flex items-center justify-center`}>
                          <Icon className="h-6 w-6 text-white" />
                        </div>
                        <span className="text-lg font-semibold">{docType.type}</span>
                      </div>
                    </Button>
                  );
                })}
              </div>
            </CardContent>
          </Card>

          <Button
            onClick={() => navigate(createPageUrl("Gescannte-Dokumente"))}
            variant="outline"
            className="w-full"
          >
            <FolderOpen className="h-5 w-5 mr-2" />
            Gescannte Dokumente anzeigen
          </Button>
        </>
      ) : (
        <div className="space-y-4">
          <Card className="border-2 bg-gray-50">
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                {React.createElement(selectedType.icon, { 
                  className: "h-6 w-6 text-gray-700" 
                })}
                <div>
                  <p className="text-sm text-gray-600">Sie scannen:</p>
                  <p className="font-semibold text-gray-900">{selectedType.type}</p>
                </div>
                <Button
                  onClick={() => {
                    setSelectedType(null);
                    setScannedData(null);
                    setFormData({
                      title: "",
                      document_date: "",
                      related_doctor: "",
                      tags: "",
                      notes: ""
                    });
                  }}
                  variant="ghost"
                  size="sm"
                  className="ml-auto"
                >
                  Ändern
                </Button>
              </div>
            </CardContent>
          </Card>

          <DocumentScanner 
            onScanComplete={handleScanComplete}
            documentType={selectedType.type}
          />

          {scannedData && (
            <>
              {/* AI Insights and Medical Entities */}
              {scannedData.extractedData && (
                <div>
                  <div className="flex items-center gap-2 mb-4">
                    <Brain className="h-5 w-5 text-purple-600" />
                    <h2 className="text-xl font-bold text-gray-900">KI-Analyse Ergebnisse</h2>
                  </div>
                  <MedicalInsights 
                    document={{
                      ...scannedData.extractedData,
                      medical_entities: scannedData.extractedData.medical_entities,
                      ai_insights: scannedData.extractedData.ai_insights,
                      suggested_actions: scannedData.extractedData.suggested_actions
                    }}
                    onActionClick={handleExecuteAction}
                  />
                </div>
              )}

              {/* Document Details Form */}
              <Card className="border-2 border-green-200 bg-green-50">
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">Dokumentdetails</CardTitle>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setShowAdvancedForm(!showAdvancedForm)}
                    >
                      {showAdvancedForm ? (
                        <>
                          <ChevronUp className="h-4 w-4 mr-1" />
                          Weniger
                        </>
                      ) : (
                        <>
                          <ChevronDown className="h-4 w-4 mr-1" />
                          Erweitert
                        </>
                      )}
                    </Button>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label htmlFor="title">Titel *</Label>
                    <Input
                      id="title"
                      value={formData.title}
                      onChange={(e) => setFormData({...formData, title: e.target.value})}
                      placeholder="z.B. Laborbefund vom 15.11.2024"
                      className="mt-1 bg-white"
                    />
                  </div>

                  <div>
                    <Label htmlFor="document_date">Datum</Label>
                    <Input
                      id="document_date"
                      type="date"
                      value={formData.document_date}
                      onChange={(e) => setFormData({...formData, document_date: e.target.value})}
                      className="mt-1 bg-white"
                    />
                  </div>

                  {showAdvancedForm && (
                    <>
                      <div>
                        <Label htmlFor="related_doctor">Arzt / Einrichtung</Label>
                        <Input
                          id="related_doctor"
                          value={formData.related_doctor}
                          onChange={(e) => setFormData({...formData, related_doctor: e.target.value})}
                          placeholder="z.B. Dr. Müller"
                          className="mt-1 bg-white"
                        />
                      </div>

                      <div>
                        <Label htmlFor="tags">Schlagwörter (durch Komma getrennt)</Label>
                        <Input
                          id="tags"
                          value={formData.tags}
                          onChange={(e) => setFormData({...formData, tags: e.target.value})}
                          placeholder="z.B. Blutbild, Cholesterin, Routine"
                          className="mt-1 bg-white"
                        />
                      </div>

                      <div>
                        <Label htmlFor="notes">Zusätzliche Notizen</Label>
                        <Textarea
                          id="notes"
                          value={formData.notes}
                          onChange={(e) => setFormData({...formData, notes: e.target.value})}
                          placeholder="Zusätzliche Informationen..."
                          rows={3}
                          className="mt-1 bg-white"
                        />
                      </div>
                    </>
                  )}

                  <Button
                    onClick={handleSave}
                    disabled={saveMutation.isPending}
                    className="w-full h-14 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700"
                  >
                    {saveMutation.isPending ? (
                      "Speichere..."
                    ) : (
                      <>
                        <Save className="h-5 w-5 mr-2" />
                        Dokument speichern
                      </>
                    )}
                  </Button>
                </CardContent>
              </Card>
            </>
          )}
        </div>
      )}
    </div>
  );
}