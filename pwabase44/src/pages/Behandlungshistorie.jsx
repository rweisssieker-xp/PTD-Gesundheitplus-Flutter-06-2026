import React, { useState } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Plus, FileText, Calendar, User, Pill, Trash2, Filter } from "lucide-react";
import { toast } from "sonner";
import { format } from "date-fns";
import { de } from "date-fns/locale";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import VoiceNavigation from "../components/VoiceNavigation";

export default function BehandlungshistoriePage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingEntry, setEditingEntry] = useState(null);
  const [filterDoctor, setFilterDoctor] = useState("all");
  const [formData, setFormData] = useState({
    doctor_name: "",
    doctor_specialty: "",
    date: "",
    diagnosis: "",
    treatment: "",
    medications_prescribed: [],
    follow_up_date: "",
    notes: "",
    document_urls: []
  });

  const { data: treatments, isLoading } = useQuery({
    queryKey: ['treatment-history'],
    queryFn: () => entities.TreatmentHistory.list('-date'),
    initialData: [],
  });

  const { data: doctors } = useQuery({
    queryKey: ['healthcare-professionals'],
    queryFn: () => entities.HealthcareProfessional.list(),
    initialData: [],
  });

  const saveMutation = useMutation({
    mutationFn: (data) => {
      if (editingEntry) {
        return entities.TreatmentHistory.update(editingEntry.id, data);
      }
      return entities.TreatmentHistory.create(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['treatment-history'] });
      toast.success(editingEntry ? "Eintrag aktualisiert" : "Eintrag hinzugefügt");
      handleCloseDialog();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => entities.TreatmentHistory.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['treatment-history'] });
      toast.success("Eintrag entfernt");
    },
  });

  const handleOpenDialog = (entry = null) => {
    if (entry) {
      setEditingEntry(entry);
      setFormData(entry);
    } else {
      setEditingEntry(null);
      setFormData({
        doctor_name: "",
        doctor_specialty: "",
        date: "",
        diagnosis: "",
        treatment: "",
        medications_prescribed: [],
        follow_up_date: "",
        notes: "",
        document_urls: []
      });
    }
    setIsDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingEntry(null);
  };

  const handleSave = () => {
    if (!formData.doctor_name || !formData.date) {
      toast.error("Bitte Arzt und Datum eingeben");
      return;
    }
    saveMutation.mutate(formData);
  };

  const handleDelete = (id) => {
    if (confirm("Möchten Sie diesen Eintrag wirklich entfernen?")) {
      deleteMutation.mutate(id);
    }
  };

  const filteredTreatments = filterDoctor === "all" 
    ? treatments 
    : treatments.filter(t => t.doctor_name === filterDoctor);

  const groupedByDoctor = filteredTreatments.reduce((acc, treatment) => {
    const doctor = treatment.doctor_name;
    if (!acc[doctor]) acc[doctor] = [];
    acc[doctor].push(treatment);
    return acc;
  }, {});

  const generateVoiceContent = () => {
    return `Behandlungshistorie. ${treatments.length} Einträge gespeichert.`;
  };

  return (
    <div className="p-6 space-y-4 pb-24">
      <VoiceNavigation content={generateVoiceContent()} />
      
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Behandlungshistorie</h1>
          <p className="text-gray-600">Übersicht Ihrer Behandlungen</p>
        </div>
      </div>

      <Card className="bg-gradient-to-r from-teal-500 to-teal-600 text-white border-0">
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-teal-100 text-sm">Behandlungseinträge</p>
              <p className="text-4xl font-bold">{treatments.length}</p>
            </div>
            <FileText className="h-16 w-16 text-teal-200" />
          </div>
        </CardContent>
      </Card>

      <div className="flex gap-3">
        <div className="flex-1">
          <Select value={filterDoctor} onValueChange={setFilterDoctor}>
            <SelectTrigger>
              <SelectValue placeholder="Nach Arzt filtern" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Alle Ärzte</SelectItem>
              {doctors.map(doc => (
                <SelectItem key={doc.id} value={doc.name}>{doc.name}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => handleOpenDialog()} size="lg">
              <Plus className="h-5 w-5 mr-2" />
              Eintrag
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {editingEntry ? "Eintrag bearbeiten" : "Neuer Eintrag"}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div>
                <Label>Arzt *</Label>
                <Select
                  value={formData.doctor_name}
                  onValueChange={(value) => {
                    const doctor = doctors.find(d => d.name === value);
                    setFormData({ 
                      ...formData, 
                      doctor_name: value,
                      doctor_specialty: doctor?.specialty || ""
                    });
                  }}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Arzt auswählen" />
                  </SelectTrigger>
                  <SelectContent>
                    {doctors.map(doc => (
                      <SelectItem key={doc.id} value={doc.name}>
                        {doc.name} - {doc.specialty}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label>Datum *</Label>
                <Input
                  type="date"
                  value={formData.date}
                  onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                />
              </div>
              <div>
                <Label>Diagnose</Label>
                <Input
                  placeholder="Gestellte Diagnose"
                  value={formData.diagnosis}
                  onChange={(e) => setFormData({ ...formData, diagnosis: e.target.value })}
                />
              </div>
              <div>
                <Label>Behandlung</Label>
                <Textarea
                  placeholder="Durchgeführte Behandlung"
                  value={formData.treatment}
                  onChange={(e) => setFormData({ ...formData, treatment: e.target.value })}
                  rows={3}
                />
              </div>
              <div>
                <Label>Nachuntersuchung</Label>
                <Input
                  type="date"
                  value={formData.follow_up_date}
                  onChange={(e) => setFormData({ ...formData, follow_up_date: e.target.value })}
                />
              </div>
              <div>
                <Label>Notizen</Label>
                <Textarea
                  placeholder="Zusätzliche Informationen"
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

      {isLoading ? (
        <p className="text-center text-gray-500 py-8">Lade Behandlungshistorie...</p>
      ) : filteredTreatments.length === 0 ? (
        <Card className="border-2 border-dashed">
          <CardContent className="py-12 text-center">
            <FileText className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 mb-4">Noch keine Einträge vorhanden</p>
            <Button onClick={() => handleOpenDialog()}>
              <Plus className="h-5 w-5 mr-2" />
              Ersten Eintrag hinzufügen
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-6">
          {Object.entries(groupedByDoctor).map(([doctorName, entries]) => (
            <div key={doctorName}>
              <h2 className="text-lg font-semibold text-gray-700 mb-3 px-2 flex items-center gap-2">
                <User className="h-5 w-5" />
                {doctorName} ({entries.length} Behandlungen)
              </h2>
              <div className="space-y-3">
                {entries.map((entry) => (
                  <Card key={entry.id} className="border-2 hover:shadow-lg transition-shadow">
                    <CardContent className="p-4">
                      <div className="flex justify-between items-start mb-3">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-2">
                            <Calendar className="h-4 w-4 text-gray-400" />
                            <span className="text-sm font-semibold text-gray-900">
                              {format(new Date(entry.date), 'dd. MMMM yyyy', { locale: de })}
                            </span>
                            {entry.doctor_specialty && (
                              <Badge variant="outline">{entry.doctor_specialty}</Badge>
                            )}
                          </div>
                          {entry.diagnosis && (
                            <p className="text-gray-900 font-semibold mb-2">{entry.diagnosis}</p>
                          )}
                          {entry.treatment && (
                            <p className="text-sm text-gray-700 mb-2">{entry.treatment}</p>
                          )}
                          {entry.follow_up_date && (
                            <div className="flex items-center gap-2 text-sm text-blue-600 mb-2">
                              <Calendar className="h-3 w-3" />
                              Nachuntersuchung: {format(new Date(entry.follow_up_date), 'dd.MM.yyyy')}
                            </div>
                          )}
                          {entry.notes && (
                            <div className="mt-2 p-2 bg-gray-50 rounded">
                              <p className="text-sm text-gray-600">{entry.notes}</p>
                            </div>
                          )}
                        </div>
                        <div className="flex gap-2">
                          <Button
                            onClick={() => handleOpenDialog(entry)}
                            size="sm"
                            variant="outline"
                          >
                            Bearbeiten
                          </Button>
                          <Button
                            onClick={() => handleDelete(entry.id)}
                            size="sm"
                            variant="ghost"
                          >
                            <Trash2 className="h-4 w-4 text-red-500" />
                          </Button>
                        </div>
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