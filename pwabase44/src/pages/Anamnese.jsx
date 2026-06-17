import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Plus, Trash2, QrCode, Save, FileText } from "lucide-react";
import { toast } from "sonner";
import VoiceInput from "../components/VoiceInput";
import VoiceNavigation from "../components/VoiceNavigation";
import QRCodeGenerator from "../components/QRCodeGenerator";

export default function AnamnesePage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [editMode, setEditMode] = useState(false);
  const [showQRCode, setShowQRCode] = useState(false);
  const [formData, setFormData] = useState({
    diagnoses: [],
    surgeries: [],
    family_history: "",
    lifestyle: {
      smoking: "Nichtraucher",
      alcohol: "",
      exercise: ""
    },
    blood_type: "Unbekannt"
  });

  const { data: histories, isLoading } = useQuery({
    queryKey: ['medical-history'],
    queryFn: () => entities.MedicalHistory.list(),
    initialData: [],
  });

  useEffect(() => {
    if (histories.length > 0) {
      setFormData(histories[0]);
    }
  }, [histories]);

  const saveMutation = useMutation({
    mutationFn: (data) => {
      if (histories.length > 0) {
        return entities.MedicalHistory.update(histories[0].id, data);
      }
      return entities.MedicalHistory.create(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['medical-history'] });
      toast.success("Anamnese gespeichert");
      setEditMode(false);
    },
  });

  const handleSave = () => {
    saveMutation.mutate(formData);
  };

  const addDiagnosis = () => {
    setFormData({
      ...formData,
      diagnoses: [...(formData.diagnoses || []), { diagnosis: "", date: "", doctor: "", notes: "" }]
    });
  };

  const removeDiagnosis = (index) => {
    const newDiagnoses = formData.diagnoses.filter((_, i) => i !== index);
    setFormData({ ...formData, diagnoses: newDiagnoses });
  };

  const updateDiagnosis = (index, field, value) => {
    const newDiagnoses = [...formData.diagnoses];
    newDiagnoses[index] = { ...newDiagnoses[index], [field]: value };
    setFormData({ ...formData, diagnoses: newDiagnoses });
  };

  const addSurgery = () => {
    setFormData({
      ...formData,
      surgeries: [...(formData.surgeries || []), { surgery: "", date: "", hospital: "" }]
    });
  };

  const removeSurgery = (index) => {
    const newSurgeries = formData.surgeries.filter((_, i) => i !== index);
    setFormData({ ...formData, surgeries: newSurgeries });
  };

  const updateSurgery = (index, field, value) => {
    const newSurgeries = [...formData.surgeries];
    newSurgeries[index] = { ...newSurgeries[index], [field]: value };
    setFormData({ ...formData, surgeries: newSurgeries });
  };

  const generateVoiceContent = () => {
    let content = "Ihre Krankengeschichte. ";
    if (formData.blood_type && formData.blood_type !== "Unbekannt") {
      content += `Blutgruppe: ${formData.blood_type}. `;
    }
    if (formData.diagnoses?.length > 0) {
      content += `${formData.diagnoses.length} Diagnosen eingetragen. `;
    }
    if (formData.surgeries?.length > 0) {
      content += `${formData.surgeries.length} Operationen eingetragen. `;
    }
    return content;
  };

  const prepareQRData = () => {
    return {
      type: "gesundheit_plus_anamnese",
      patient_data: {
        blood_type: formData.blood_type,
        diagnoses: formData.diagnoses,
        surgeries: formData.surgeries,
        family_history: formData.family_history,
        lifestyle: formData.lifestyle
      },
      generated_at: new Date().toISOString()
    };
  };

  if (isLoading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-screen">
        <p className="text-gray-500">Lade Anamnese...</p>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-4 pb-24">
      <VoiceNavigation content={generateVoiceContent()} />

      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Krankengeschichte</h1>
          <p className="text-gray-600">Ihre medizinische Anamnese</p>
        </div>
        {!editMode && (
          <Button onClick={() => setEditMode(true)} size="lg">
            <FileText className="h-5 w-5 mr-2" />
            Bearbeiten
          </Button>
        )}
      </div>

      {editMode ? (
        <div className="space-y-4">
          {/* Blood Type */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Blutgruppe</CardTitle>
            </CardHeader>
            <CardContent>
              <Select
                value={formData.blood_type}
                onValueChange={(value) => setFormData({ ...formData, blood_type: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {["A+", "A-", "B+", "B-", "AB+", "AB-", "0+", "0-", "Unbekannt"].map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </CardContent>
          </Card>

          {/* Diagnoses */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center justify-between">
                Diagnosen
                <Button onClick={addDiagnosis} size="sm">
                  <Plus className="h-4 w-4 mr-1" />
                  Hinzufügen
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {formData.diagnoses?.map((diagnosis, index) => (
                <div key={index} className="p-4 border-2 rounded-lg space-y-3">
                  <div className="flex justify-between items-start">
                    <Label>Diagnose {index + 1}</Label>
                    <Button
                      onClick={() => removeDiagnosis(index)}
                      size="sm"
                      variant="ghost"
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </Button>
                  </div>
                  <Input
                    placeholder="Diagnose"
                    value={diagnosis.diagnosis}
                    onChange={(e) => updateDiagnosis(index, 'diagnosis', e.target.value)}
                  />
                  <Input
                    type="date"
                    placeholder="Datum"
                    value={diagnosis.date}
                    onChange={(e) => updateDiagnosis(index, 'date', e.target.value)}
                  />
                  <Input
                    placeholder="Arzt"
                    value={diagnosis.doctor}
                    onChange={(e) => updateDiagnosis(index, 'doctor', e.target.value)}
                  />
                  <Textarea
                    placeholder="Notizen"
                    value={diagnosis.notes}
                    onChange={(e) => updateDiagnosis(index, 'notes', e.target.value)}
                  />
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Surgeries */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center justify-between">
                Operationen
                <Button onClick={addSurgery} size="sm">
                  <Plus className="h-4 w-4 mr-1" />
                  Hinzufügen
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {formData.surgeries?.map((surgery, index) => (
                <div key={index} className="p-4 border-2 rounded-lg space-y-3">
                  <div className="flex justify-between items-start">
                    <Label>Operation {index + 1}</Label>
                    <Button
                      onClick={() => removeSurgery(index)}
                      size="sm"
                      variant="ghost"
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </Button>
                  </div>
                  <Input
                    placeholder="Operation"
                    value={surgery.surgery}
                    onChange={(e) => updateSurgery(index, 'surgery', e.target.value)}
                  />
                  <Input
                    type="date"
                    value={surgery.date}
                    onChange={(e) => updateSurgery(index, 'date', e.target.value)}
                  />
                  <Input
                    placeholder="Krankenhaus"
                    value={surgery.hospital}
                    onChange={(e) => updateSurgery(index, 'hospital', e.target.value)}
                  />
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Lifestyle */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Lebensstil</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label>Rauchen</Label>
                <Select
                  value={formData.lifestyle?.smoking || "Nichtraucher"}
                  onValueChange={(value) => setFormData({
                    ...formData,
                    lifestyle: { ...formData.lifestyle, smoking: value }
                  })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Nichtraucher">Nichtraucher</SelectItem>
                    <SelectItem value="Raucher">Raucher</SelectItem>
                    <SelectItem value="Ex-Raucher">Ex-Raucher</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label>Alkohol</Label>
                <Input
                  placeholder="z.B. gelegentlich, regelmäßig, nie"
                  value={formData.lifestyle?.alcohol || ""}
                  onChange={(e) => setFormData({
                    ...formData,
                    lifestyle: { ...formData.lifestyle, alcohol: e.target.value }
                  })}
                />
              </div>
              <div>
                <Label>Sport / Bewegung</Label>
                <Input
                  placeholder="z.B. 3x wöchentlich, täglich"
                  value={formData.lifestyle?.exercise || ""}
                  onChange={(e) => setFormData({
                    ...formData,
                    lifestyle: { ...formData.lifestyle, exercise: e.target.value }
                  })}
                />
              </div>
            </CardContent>
          </Card>

          {/* Family History */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Familienanamnese</CardTitle>
            </CardHeader>
            <CardContent>
              <Textarea
                placeholder="Relevante Erkrankungen in der Familie..."
                value={formData.family_history || ""}
                onChange={(e) => setFormData({ ...formData, family_history: e.target.value })}
                rows={4}
              />
              <div className="mt-3">
                <VoiceInput
                  onResult={(text) => setFormData({ ...formData, family_history: text })}
                  buttonText="Per Sprache eingeben"
                />
              </div>
            </CardContent>
          </Card>

          <div className="flex gap-3">
            <Button onClick={() => setEditMode(false)} variant="outline" className="flex-1">
              Abbrechen
            </Button>
            <Button onClick={handleSave} className="flex-1 bg-green-600 hover:bg-green-700">
              <Save className="h-5 w-5 mr-2" />
              Speichern
            </Button>
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">QR-Code für Weitergabe</CardTitle>
            </CardHeader>
            <CardContent>
              <Button
                onClick={() => setShowQRCode(!showQRCode)}
                className="w-full"
                size="lg"
              >
                <QrCode className="h-5 w-5 mr-2" />
                {showQRCode ? "QR-Code ausblenden" : "QR-Code generieren"}
              </Button>
              <p className="text-sm text-gray-500 mt-2 text-center">
                Ärzte können Ihre Anamnese mit dem QR-Code einlesen
              </p>
            </CardContent>
          </Card>

          {showQRCode && (
            <QRCodeGenerator
              data={prepareQRData()}
              title="Anamnese QR-Code"
            />
          )}

          {formData.blood_type && formData.blood_type !== "Unbekannt" && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Blutgruppe</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-2xl font-bold text-red-600">{formData.blood_type}</p>
              </CardContent>
            </Card>
          )}

          {formData.diagnoses?.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Diagnosen</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {formData.diagnoses.map((diagnosis, index) => (
                  <div key={index} className="p-3 bg-gray-50 rounded-lg">
                    <p className="font-semibold">{diagnosis.diagnosis}</p>
                    {diagnosis.date && <p className="text-sm text-gray-600">Datum: {new Date(diagnosis.date).toLocaleDateString('de-DE')}</p>}
                    {diagnosis.doctor && <p className="text-sm text-gray-600">Arzt: {diagnosis.doctor}</p>}
                    {diagnosis.notes && <p className="text-sm text-gray-700 mt-1">{diagnosis.notes}</p>}
                  </div>
                ))}
              </CardContent>
            </Card>
          )}

          {formData.surgeries?.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Operationen</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {formData.surgeries.map((surgery, index) => (
                  <div key={index} className="p-3 bg-gray-50 rounded-lg">
                    <p className="font-semibold">{surgery.surgery}</p>
                    {surgery.date && <p className="text-sm text-gray-600">Datum: {new Date(surgery.date).toLocaleDateString('de-DE')}</p>}
                    {surgery.hospital && <p className="text-sm text-gray-600">Krankenhaus: {surgery.hospital}</p>}
                  </div>
                ))}
              </CardContent>
            </Card>
          )}

          {(formData.lifestyle?.smoking || formData.lifestyle?.alcohol || formData.lifestyle?.exercise) && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Lebensstil</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                {formData.lifestyle?.smoking && (
                  <p><span className="font-semibold">Rauchen:</span> {formData.lifestyle.smoking}</p>
                )}
                {formData.lifestyle?.alcohol && (
                  <p><span className="font-semibold">Alkohol:</span> {formData.lifestyle.alcohol}</p>
                )}
                {formData.lifestyle?.exercise && (
                  <p><span className="font-semibold">Sport:</span> {formData.lifestyle.exercise}</p>
                )}
              </CardContent>
            </Card>
          )}

          {formData.family_history && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Familienanamnese</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-gray-700">{formData.family_history}</p>
              </CardContent>
            </Card>
          )}
        </div>
      )}
    </div>
  );
}