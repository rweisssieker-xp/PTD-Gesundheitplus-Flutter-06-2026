import React, { useState } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Plus, Pill, Clock, Bell, AlertCircle, Trash2, Mic } from "lucide-react";
import { toast } from "sonner";
import AllergyMedicationCheck from "@/components/AllergyMedicationCheck";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import VoiceNavigation from "../components/VoiceNavigation";
import VoiceDataInput from "../components/VoiceDataInput";

export default function MedikationPage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingMed, setEditingMed] = useState(null);
  const [showInactive, setShowInactive] = useState(false);
  const [showVoiceInput, setShowVoiceInput] = useState(false);
  const [lastAddedMed, setLastAddedMed] = useState(null);
  const [formData, setFormData] = useState({
    name: "",
    dosage: "",
    frequency: "1x täglich",
    schedule: "",
    start_date: "",
    end_date: "",
    prescribed_by: "",
    reason: "",
    reminder_enabled: true,
    reminder_times: [""],
    refill_reminder_days: 7,
    notes: "",
    active: true
  });

  const { data: medications, isLoading } = useQuery({
    queryKey: ['medications'],
    queryFn: () => entities.Medication.list('-created_date'),
    initialData: [],
  });

  const saveMutation = useMutation({
    mutationFn: (data) => {
      if (editingMed) {
        return entities.Medication.update(editingMed.id, data);
      }
      return entities.Medication.create(data);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['medications'] });
      toast.success(editingMed ? "Medikament aktualisiert" : "Medikament hinzugefügt");
      if (!editingMed) {
        setLastAddedMed(variables.name);
      }
      handleCloseDialog();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => entities.Medication.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['medications'] });
      toast.success("Medikament entfernt");
    },
  });

  const handleVoiceDataExtracted = (data) => {
    setFormData((prevData) => ({
      ...prevData,
      name: data.name || prevData.name,
      dosage: data.dosage || prevData.dosage,
      frequency: data.frequency || prevData.frequency,
      prescribed_by: data.prescribed_by || prevData.prescribed_by,
      reason: data.reason || prevData.reason
    }));
    setShowVoiceInput(false);
    setIsDialogOpen(true);
    toast.success("Daten aus Spracheingabe übernommen");
  };

  const handleOpenDialog = (med = null) => {
    if (med) {
      setEditingMed(med);
      setFormData(med);
    } else {
      setEditingMed(null);
      setFormData({
        name: "",
        dosage: "",
        frequency: "1x täglich",
        schedule: "",
        start_date: "",
        end_date: "",
        prescribed_by: "",
        reason: "",
        reminder_enabled: true,
        reminder_times: [""],
        refill_reminder_days: 7,
        notes: "",
        active: true
      });
    }
    setIsDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingMed(null);
  };

  const handleSave = () => {
    if (!formData.name || !formData.dosage || !formData.frequency) {
      toast.error("Bitte Name, Dosierung und Häufigkeit eingeben");
      return;
    }
    saveMutation.mutate(formData);
  };

  const handleDelete = (id) => {
    if (confirm("Möchten Sie dieses Medikament wirklich entfernen?")) {
      deleteMutation.mutate(id);
    }
  };

  const addReminderTime = () => {
    setFormData({
      ...formData,
      reminder_times: [...(formData.reminder_times || []), ""]
    });
  };

  const updateReminderTime = (index, value) => {
    const newTimes = [...(formData.reminder_times || [])];
    newTimes[index] = value;
    setFormData({ ...formData, reminder_times: newTimes });
  };

  const removeReminderTime = (index) => {
    const newTimes = formData.reminder_times.filter((_, i) => i !== index);
    setFormData({ ...formData, reminder_times: newTimes });
  };

  const filteredMeds = medications.filter(med => showInactive || med.active !== false);
  const activeMeds = filteredMeds.filter(m => m.active !== false);
  const inactiveMeds = filteredMeds.filter(m => m.active === false);

  const generateVoiceContent = () => {
    const activeCount = activeMeds.length;
    let content = `Medikation. ${activeCount} aktive Medikamente. `;
    if (activeCount > 0) {
      activeMeds.slice(0, 3).forEach(med => {
        content += `${med.name}, ${med.dosage}, ${med.frequency}. `;
      });
    }
    return content;
  };

  return (
    <div className="p-6 space-y-4 pb-24">
      <VoiceNavigation content={generateVoiceContent()} />
      
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Medikation</h1>
          <p className="text-gray-600">Ihr Medikamentenplan</p>
        </div>
      </div>

      {/* Voice Input Card */}
      {showVoiceInput && (
        <VoiceDataInput
          onDataExtracted={handleVoiceDataExtracted}
          entityType="medication"
          promptText="Bitte nennen Sie mir den Namen des Medikaments, die Dosierung und die Einnahmehäufigkeit."
        />
      )}

      {/* Allergy & Interaction Check */}
      <AllergyMedicationCheck newMedicationName={lastAddedMed} />

      {/* Summary Card */}
      <Card className="bg-gradient-to-r from-orange-500 to-orange-600 text-white border-0">
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-orange-100 text-sm">Aktive Medikamente</p>
              <p className="text-4xl font-bold">{activeMeds.length}</p>
            </div>
            <Pill className="h-16 w-16 text-orange-200" />
          </div>
        </CardContent>
      </Card>

      {/* Add and Filter */}
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Switch
            checked={showInactive}
            onCheckedChange={setShowInactive}
          />
          <Label className="text-sm">Abgesetzte anzeigen</Label>
        </div>
        <div className="flex gap-2">
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
                  {editingMed ? "Medikament bearbeiten" : "Neues Medikament"}
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-4 py-4">
                <div>
                  <Label>Medikamentenname *</Label>
                  <Input
                    placeholder="z.B. Aspirin"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Dosierung *</Label>
                  <Input
                    placeholder="z.B. 10mg, 1 Tablette"
                    value={formData.dosage}
                    onChange={(e) => setFormData({ ...formData, dosage: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Häufigkeit *</Label>
                  <Select
                    value={formData.frequency}
                    onValueChange={(value) => setFormData({ ...formData, frequency: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {["1x täglich", "2x täglich", "3x täglich", "Bei Bedarf", "Wöchentlich", "Monatlich", "Sonstiges"].map(freq => (
                        <SelectItem key={freq} value={freq}>{freq}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Einnahmezeiten</Label>
                  <Input
                    placeholder="z.B. morgens, mittags, abends"
                    value={formData.schedule}
                    onChange={(e) => setFormData({ ...formData, schedule: e.target.value })}
                  />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label>Beginn</Label>
                    <Input
                      type="date"
                      value={formData.start_date}
                      onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
                    />
                  </div>
                  <div>
                    <Label>Ende (optional)</Label>
                    <Input
                      type="date"
                      value={formData.end_date}
                      onChange={(e) => setFormData({ ...formData, end_date: e.target.value })}
                    />
                  </div>
                </div>
                <div>
                  <Label>Verschrieben von</Label>
                  <Input
                    placeholder="Arztname"
                    value={formData.prescribed_by}
                    onChange={(e) => setFormData({ ...formData, prescribed_by: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Grund / Indikation</Label>
                  <Input
                    placeholder="Wofür wird es eingenommen?"
                    value={formData.reason}
                    onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                  />
                </div>
                <div className="flex items-center justify-between">
                  <Label>Erinnerungen aktivieren</Label>
                  <Switch
                    checked={formData.reminder_enabled}
                    onCheckedChange={(checked) => setFormData({ ...formData, reminder_enabled: checked })}
                  />
                </div>
                {formData.reminder_enabled && (
                  <div>
                    <Label>Erinnerungszeiten (HH:MM)</Label>
                    <div className="space-y-2 mt-2">
                      {formData.reminder_times?.map((time, index) => (
                        <div key={index} className="flex gap-2">
                          <Input
                            type="time"
                            value={time}
                            onChange={(e) => updateReminderTime(index, e.target.value)}
                          />
                          <Button
                            onClick={() => removeReminderTime(index)}
                            size="icon"
                            variant="ghost"
                          >
                            <Trash2 className="h-4 w-4 text-red-500" />
                          </Button>
                        </div>
                      ))}
                      <Button onClick={addReminderTime} variant="outline" size="sm" className="w-full">
                        <Plus className="h-4 w-4 mr-1" /> Zeit hinzufügen
                      </Button>
                    </div>
                  </div>
                )}
                <div>
                  <Label>Nachbestellung erinnern (Tage vorher)</Label>
                  <Input
                    type="number"
                    value={formData.refill_reminder_days}
                    onChange={(e) => setFormData({ ...formData, refill_reminder_days: parseInt(e.target.value) })}
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
                <div className="flex items-center justify-between">
                  <Label>Aktiv in Einnahme</Label>
                  <Switch
                    checked={formData.active}
                    onCheckedChange={(checked) => setFormData({ ...formData, active: checked })}
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

      {/* Medications List */}
      {isLoading ? (
        <p className="text-center text-gray-500 py-8">Lade Medikamente...</p>
      ) : filteredMeds.length === 0 ? (
        <Card className="border-2 border-dashed">
          <CardContent className="py-12 text-center">
            <Pill className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 mb-4">Noch keine Medikamente hinzugefügt</p>
            <Button onClick={() => handleOpenDialog()}>
              <Plus className="h-5 w-5 mr-2" />
              Erstes Medikament hinzufügen
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {activeMeds.length > 0 && (
            <>
              <h2 className="text-lg font-semibold text-gray-700 px-2">Aktive Medikation</h2>
              {activeMeds.map((med) => (
                <Card key={med.id} className="border-2 hover:shadow-lg transition-shadow">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start mb-3">
                      <div className="flex-1">
                        <div className="flex items-start gap-3">
                          <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center flex-shrink-0">
                            <Pill className="h-6 w-6 text-white" />
                          </div>
                          <div className="flex-1">
                            <h3 className="text-lg font-bold text-gray-900">{med.name}</h3>
                            <p className="text-sm text-gray-600">{med.dosage} • {med.frequency}</p>
                            {med.schedule && (
                              <div className="flex items-center gap-1 mt-1 text-sm text-gray-500">
                                <Clock className="h-3 w-3" />
                                <span>{med.schedule}</span>
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <Button
                          onClick={() => handleOpenDialog(med)}
                          size="sm"
                          variant="outline"
                        >
                          Bearbeiten
                        </Button>
                        <Button
                          onClick={() => handleDelete(med.id)}
                          size="sm"
                          variant="ghost"
                        >
                          <Trash2 className="h-4 w-4 text-red-500" />
                        </Button>
                      </div>
                    </div>

                    <div className="space-y-2 mt-3">
                      {med.reason && (
                        <p className="text-sm text-gray-700">
                          <span className="font-semibold">Grund:</span> {med.reason}
                        </p>
                      )}
                      {med.prescribed_by && (
                        <p className="text-sm text-gray-700">
                          <span className="font-semibold">Verschrieben von:</span> {med.prescribed_by}
                        </p>
                      )}
                      {med.start_date && (
                        <p className="text-sm text-gray-500">
                          Seit {new Date(med.start_date).toLocaleDateString('de-DE')}
                          {med.end_date && ` bis ${new Date(med.end_date).toLocaleDateString('de-DE')}`}
                        </p>
                      )}
                      {med.reminder_enabled && med.reminder_times?.length > 0 && (
                        <div className="flex items-center gap-2 mt-2">
                          <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
                            <Bell className="h-3 w-3 mr-1" />
                            Erinnerungen: {med.reminder_times.filter(t => t).join(", ")}
                          </Badge>
                        </div>
                      )}
                      {med.notes && (
                        <div className="mt-2 p-2 bg-yellow-50 rounded border border-yellow-200">
                          <p className="text-sm text-gray-700">{med.notes}</p>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </>
          )}

          {showInactive && inactiveMeds.length > 0 && (
            <>
              <h2 className="text-lg font-semibold text-gray-700 px-2 mt-6">Abgesetzte Medikamente</h2>
              {inactiveMeds.map((med) => (
                <Card key={med.id} className="border-2 opacity-60">
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start">
                      <div>
                        <h3 className="text-lg font-bold text-gray-900">{med.name}</h3>
                        <p className="text-sm text-gray-600">{med.dosage} • {med.frequency}</p>
                        <Badge variant="secondary" className="mt-2">Abgesetzt</Badge>
                      </div>
                      <Button
                        onClick={() => handleDelete(med.id)}
                        size="sm"
                        variant="ghost"
                      >
                        <Trash2 className="h-4 w-4 text-red-500" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </>
          )}
        </div>
      )}
    </div>
  );
}