import React, { useState } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Plus, AlertCircle, Trash2, Mic } from "lucide-react";
import { toast } from "sonner";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import VoiceNavigation from "../components/VoiceNavigation";
import VoiceDataInput from "../components/VoiceDataInput";

const categories = [
  "Medikament", "Nahrungsmittel", "Pollen", "Tierhaare",
  "Hausstaubmilben", "Insektengift", "Kontaktallergie", "Sonstiges"
];

const severities = ["Leicht", "Mittel", "Schwer", "Lebensbedrohlich"];

export default function AllergienPage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingAllergy, setEditingAllergy] = useState(null);
  const [showVoiceInput, setShowVoiceInput] = useState(false);
  const [formData, setFormData] = useState({
    allergen: "",
    category: "Medikament", // Changed default to match categories array
    severity: "Mittel", // Changed default as per outline
    reaction: "", // Changed from symptoms to reaction
    diagnosed_date: "",
    diagnosed_by: "", // Retained as it's used in UI
    notes: ""
  });

  const { data: allergies, isLoading } = useQuery({
    queryKey: ['allergies'],
    queryFn: () => entities.Allergy.list('-created_date'),
    initialData: [],
  });

  const saveMutation = useMutation({
    mutationFn: (data) => {
      // Map 'reaction' from formData back to 'symptoms' for the API, assuming API still expects 'symptoms'
      const dataToSend = { ...data, symptoms: data.reaction };

      if (editingAllergy) {
        return entities.Allergy.update(editingAllergy.id, dataToSend);
      }
      return entities.Allergy.create(dataToSend);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['allergies'] });
      toast.success(editingAllergy ? "Allergie aktualisiert" : "Allergie hinzugefügt");
      handleCloseDialog();
    },
    onError: (error) => {
      toast.error(`Fehler beim Speichern: ${error.message}`);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => entities.Allergy.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['allergies'] });
      toast.success("Allergie entfernt");
    },
    onError: (error) => {
      toast.error(`Fehler beim Entfernen: ${error.message}`);
    }
  });

  const handleOpenDialog = (allergy = null) => {
    if (allergy) {
      setEditingAllergy(allergy);
      // When editing, map 'symptoms' from the fetched allergy object to 'reaction' in the form state
      setFormData({
        ...allergy,
        reaction: allergy.symptoms || "", // Ensure 'reaction' field is populated from 'symptoms'
      });
    } else {
      setEditingAllergy(null);
      setFormData({
        allergen: "",
        category: "Medikament",
        severity: "Mittel",
        reaction: "",
        diagnosed_date: "",
        diagnosed_by: "",
        notes: ""
      });
    }
    setIsDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingAllergy(null);
    // Reset formData to initial state when closing dialog
    setFormData({
      allergen: "",
      category: "Medikament",
      severity: "Mittel",
      reaction: "",
      diagnosed_date: "",
      diagnosed_by: "",
      notes: ""
    });
  };

  const handleVoiceDataExtracted = (data) => {
    setFormData((prevData) => ({
      ...prevData,
      allergen: data.allergen || prevData.allergen,
      severity: data.severity || prevData.severity,
      reaction: data.reaction || prevData.reaction
    }));
    setShowVoiceInput(false);
    setIsDialogOpen(true);
    toast.success("Daten aus Spracheingabe übernommen");
  };

  const handleSave = () => {
    if (!formData.allergen || !formData.category) {
      toast.error("Bitte Allergen und Kategorie eingeben");
      return;
    }
    saveMutation.mutate(formData);
  };

  const handleDelete = (id) => {
    if (confirm("Möchten Sie diese Allergie wirklich entfernen?")) {
      deleteMutation.mutate(id);
    }
  };

  const getSeverityColor = (severity) => {
    switch(severity) {
      case "Leicht": return "bg-yellow-100 text-yellow-800 border-yellow-200";
      case "Mittel": return "bg-orange-100 text-orange-800 border-orange-200";
      case "Schwer": return "bg-red-100 text-red-800 border-red-200";
      case "Lebensbedrohlich": return "bg-red-600 text-white border-red-700";
      default: return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const groupedAllergies = allergies.reduce((acc, allergy) => {
    const category = allergy.category || "Sonstiges";
    if (!acc[category]) acc[category] = [];
    acc[category].push(allergy);
    return acc;
  }, {});

  const severeAllergies = allergies.filter(a => a.severity === "Schwer" || a.severity === "Lebensbedrohlich");

  const generateVoiceContent = () => {
    let content = `Allergien. ${allergies.length} bekannte Allergien. `;
    if (severeAllergies.length > 0) {
      content += `WICHTIG: ${severeAllergies.length} schwere Allergien. `;
      severeAllergies.forEach(a => {
        content += `${a.allergen}, ${a.severity}. `;
      });
    }
    return content;
  };

  return (
    <div className="p-6 space-y-4 pb-24">
      <VoiceNavigation content={generateVoiceContent()} />
      
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Allergien</h1>
        <p className="text-gray-600">Ihre Allergien & Unverträglichkeiten</p>
      </div>

      {/* Voice Input Card */}
      {showVoiceInput && (
        <VoiceDataInput
          onDataExtracted={handleVoiceDataExtracted}
          entityType="allergy"
          promptText="Bitte nennen Sie mir das Allergen, den Schweregrad und die typische Reaktion."
        />
      )}

      {/* Warning Card */}
      {severeAllergies.length > 0 && (
        <Card className="border-2 border-red-300 bg-red-50">
          <CardContent className="pt-6">
            <div className="flex items-start gap-3">
              <AlertCircle className="h-6 w-6 text-red-600 flex-shrink-0 mt-1" />
              <div>
                <h3 className="font-bold text-red-900 mb-2">WICHTIG: Schwere Allergien</h3>
                <div className="space-y-1">
                  {severeAllergies.map(a => (
                    <p key={a.id} className="text-sm text-red-800">
                      • <span className="font-semibold">{a.allergen}</span> ({a.severity})
                    </p>
                  ))}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Summary and Add */}
      <div className="flex items-center justify-between gap-3">
        <Card className="flex-1 bg-gradient-to-r from-yellow-500 to-yellow-600 text-white border-0">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-yellow-100 text-sm">Bekannte Allergien</p>
                <p className="text-4xl font-bold">{allergies.length}</p>
              </div>
              <AlertCircle className="h-16 w-16 text-yellow-200" />
            </div>
          </CardContent>
        </Card>
        <div className="flex flex-col gap-2">
          <Button 
            onClick={() => setShowVoiceInput(!showVoiceInput)} 
            size="lg"
            className="bg-purple-600 hover:bg-purple-700"
          >
            <Mic className="h-5 w-5 mr-2" />
            Sprache
          </Button>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={() => handleOpenDialog()} size="lg">
                <Plus className="h-5 w-5 mr-2" />
                Hinzufügen
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>
                  {editingAllergy ? "Allergie bearbeiten" : "Neue Allergie"}
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-4 py-4">
                <div>
                  <Label>Allergen / Unverträglichkeit *</Label>
                  <Input
                    placeholder="z.B. Penicillin, Nüsse, Pollen"
                    value={formData.allergen}
                    onChange={(e) => setFormData({ ...formData, allergen: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Kategorie *</Label>
                  <Select
                    value={formData.category}
                    onValueChange={(value) => setFormData({ ...formData, category: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Kategorie wählen" />
                    </SelectTrigger>
                    <SelectContent>
                      {categories.map(cat => (
                        <SelectItem key={cat} value={cat}>{cat}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Schweregrad</Label>
                  <Select
                    value={formData.severity}
                    onValueChange={(value) => setFormData({ ...formData, severity: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {severities.map(sev => (
                        <SelectItem key={sev} value={sev}>{sev}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Reaktion</Label> {/* Changed label from Symptoms */}
                  <Textarea
                    placeholder="z.B. Hautausschlag, Atemnot, Schwellungen..."
                    value={formData.reaction} // Changed from symptoms
                    onChange={(e) => setFormData({ ...formData, reaction: e.target.value })} // Changed from symptoms
                    rows={3}
                  />
                </div>
                <div>
                  <Label>Festgestellt am</Label>
                  <Input
                    type="date"
                    value={formData.diagnosed_date}
                    onChange={(e) => setFormData({ ...formData, diagnosed_date: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Festgestellt von</Label>
                  <Input
                    placeholder="Arztname"
                    value={formData.diagnosed_by}
                    onChange={(e) => setFormData({ ...formData, diagnosed_by: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Notizen</Label>
                  <Textarea
                    placeholder="Zusätzliche Informationen..."
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    rows={3}
                  />
                </div>
                <div className="flex gap-3 pt-4">
                  <Button onClick={handleCloseDialog} variant="outline" className="flex-1">
                    Abbrechen
                  </Button>
                  <Button onClick={handleSave} className="flex-1 bg-green-600 hover:bg-green-700">
                    Speichern
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Allergies List */}
      {isLoading ? (
        <p className="text-center text-gray-500 py-8">Lade Allergien...</p>
      ) : allergies.length === 0 ? (
        <Card className="border-2 border-dashed">
          <CardContent className="py-12 text-center">
            <AlertCircle className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 mb-4">Noch keine Allergien eingetragen</p>
            <Button onClick={() => handleOpenDialog()}>
              <Plus className="h-5 w-5 mr-2" />
              Erste Allergie hinzufügen
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-6">
          {Object.entries(groupedAllergies).map(([category, items]) => (
            <div key={category}>
              <h2 className="text-lg font-semibold text-gray-700 mb-3 px-2">
                {category} ({items.length})
              </h2>
              <div className="space-y-3">
                {items.map((allergy) => (
                  <Card key={allergy.id} className="border-2 hover:shadow-lg transition-shadow">
                    <CardContent className="p-4">
                      <div className="flex justify-between items-start mb-3">
                        <div className="flex-1">
                          <div className="flex items-start gap-3">
                            <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-yellow-500 to-yellow-600 flex items-center justify-center flex-shrink-0">
                              <AlertCircle className="h-6 w-6 text-white" />
                            </div>
                            <div className="flex-1">
                              <h3 className="text-lg font-bold text-gray-900">{allergy.allergen}</h3>
                              <div className="flex flex-wrap gap-2 mt-2">
                                <Badge variant="outline">{allergy.category}</Badge>
                                <Badge className={getSeverityColor(allergy.severity)}>
                                  {allergy.severity}
                                </Badge>
                              </div>
                            </div>
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <Button
                            onClick={() => handleOpenDialog(allergy)}
                            size="sm"
                            variant="outline"
                          >
                            Bearbeiten
                          </Button>
                          <Button
                            onClick={() => handleDelete(allergy.id)}
                            size="sm"
                            variant="ghost"
                          >
                            <Trash2 className="h-4 w-4 text-red-500" />
                          </Button>
                        </div>
                      </div>

                      <div className="space-y-2">
                        {/* Display symptoms as 'reaction' or current 'symptoms' from API */}
                        {allergy.symptoms && (
                          <div>
                            <p className="text-sm font-semibold text-gray-700 mb-1">Reaktion:</p>
                            <p className="text-sm text-gray-700">{allergy.symptoms}</p>
                          </div>
                        )}
                        {allergy.diagnosed_by && (
                          <p className="text-sm text-gray-600">
                            <span className="font-semibold">Festgestellt von:</span> {allergy.diagnosed_by}
                            {allergy.diagnosed_date && ` am ${new Date(allergy.diagnosed_date).toLocaleDateString('de-DE')}`}
                          </p>
                        )}
                        {allergy.notes && (
                          <div className="mt-2 p-2 bg-yellow-50 rounded border border-yellow-200">
                            <p className="text-sm text-gray-700">{allergy.notes}</p>
                          </div>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}