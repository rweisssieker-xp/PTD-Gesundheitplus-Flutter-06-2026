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
import { Plus, Stethoscope, Phone, Mail, MapPin, Trash2, Search, Mic, Calendar, Clock, Award, User, Upload, X } from "lucide-react";
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
import DoctorSearch from "../components/DoctorSearch";

const specialties = [
  "Allgemeinmedizin", "Innere Medizin", "Kardiologie", "Dermatologie",
  "Orthopädie", "Gynäkologie", "Urologie", "Neurologie", "Psychiatrie",
  "Augenheilkunde", "HNO", "Zahnmedizin", "Kieferorthopädie",
  "Physiotherapie", "Ergotherapie", "Logopädie", "Psychotherapie",
  "Radiologie", "Chirurgie", "Andere"
];

const commonSpecializations = [
  "Sportmedizin", "Akupunktur", "Naturheilverfahren", "Homöopathie",
  "Ernährungsmedizin", "Palliativmedizin", "Notfallmedizin", 
  "Schmerztherapie", "Manuelle Therapie", "Osteopathie"
];

const weekDays = [
  { key: "monday", label: "Montag" },
  { key: "tuesday", label: "Dienstag" },
  { key: "wednesday", label: "Mittwoch" },
  { key: "thursday", label: "Donnerstag" },
  { key: "friday", label: "Freitag" },
  { key: "saturday", label: "Samstag" },
  { key: "sunday", label: "Sonntag" }
];

export default function HeilberufePage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingDoctor, setEditingDoctor] = useState(null);
  const [showVoiceInput, setShowVoiceInput] = useState(false);
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [uploadingImage, setUploadingImage] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    specialty: "",
    specializations: [],
    address: "",
    phone: "",
    email: "",
    opening_hours: {
      monday: "",
      tuesday: "",
      wednesday: "",
      thursday: "",
      friday: "",
      saturday: "",
      sunday: ""
    },
    biography: "",
    profile_image_url: "",
    notes: "",
    treating_since: ""
  });

  const { data: doctors, isLoading } = useQuery({
    queryKey: ['healthcare-professionals'],
    queryFn: () => entities.HealthcareProfessional.list(),
    initialData: [],
  });

  const saveMutation = useMutation({
    mutationFn: (data) => {
      if (editingDoctor) {
        return entities.HealthcareProfessional.update(editingDoctor.id, data);
      }
      return entities.HealthcareProfessional.create(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['healthcare-professionals'] });
      toast.success(editingDoctor ? "Arzt aktualisiert" : "Arzt hinzugefügt");
      handleCloseDialog();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => entities.HealthcareProfessional.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['healthcare-professionals'] });
      toast.success("Arzt entfernt");
    },
  });

  const handleOpenDialog = (doctor = null) => {
    if (doctor) {
      setEditingDoctor(doctor);
      setFormData({
        ...doctor,
        specializations: doctor.specializations || [],
        opening_hours: doctor.opening_hours || {
          monday: "", tuesday: "", wednesday: "", thursday: "",
          friday: "", saturday: "", sunday: ""
        }
      });
    } else {
      setEditingDoctor(null);
      setFormData({
        name: "",
        specialty: "",
        specializations: [],
        address: "",
        phone: "",
        email: "",
        opening_hours: {
          monday: "", tuesday: "", wednesday: "", thursday: "",
          friday: "", saturday: "", sunday: ""
        },
        biography: "",
        profile_image_url: "",
        notes: "",
        treating_since: ""
      });
    }
    setIsDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingDoctor(null);
  };

  const handleSave = () => {
    if (!formData.name || !formData.specialty) {
      toast.error("Bitte Name und Fachrichtung eingeben");
      return;
    }
    saveMutation.mutate(formData);
  };

  const handleDelete = (id) => {
    if (confirm("Möchten Sie diesen Arzt wirklich entfernen?")) {
      deleteMutation.mutate(id);
    }
  };

  const handleImageUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      toast.error("Bitte wählen Sie eine Bilddatei");
      return;
    }

    setUploadingImage(true);
    try {
      const { file_url } = await base44.integrations.Core.UploadFile({ file });
      setFormData({ ...formData, profile_image_url: file_url });
      toast.success("Bild hochgeladen");
    } catch (error) {
      toast.error("Fehler beim Hochladen");
      console.error(error);
    } finally {
      setUploadingImage(false);
    }
  };

  const handleVoiceDataExtracted = (data) => {
    setFormData({
      ...formData,
      name: data.name || formData.name,
      specialty: data.specialty || formData.specialty,
      address: data.address || formData.address,
      phone: data.phone || formData.phone
    });
    setShowVoiceInput(false);
    setIsDialogOpen(true);
    toast.success("Daten aus Spracheingabe übernommen");
  };

  const handleDoctorSelected = (doctor) => {
    setFormData({
      ...formData,
      name: doctor.name || formData.name,
      specialty: doctor.specialty || formData.specialty,
      address: doctor.address || formData.address,
      phone: doctor.phone || formData.phone,
      email: doctor.email || formData.email
    });
    setShowSearch(false);
    setIsDialogOpen(true);
    toast.success("Arzt-Daten übernommen");
  };

  const toggleSpecialization = (spec) => {
    const current = formData.specializations || [];
    if (current.includes(spec)) {
      setFormData({
        ...formData,
        specializations: current.filter(s => s !== spec)
      });
    } else {
      setFormData({
        ...formData,
        specializations: [...current, spec]
      });
    }
  };

  const filteredDoctors = doctors.filter(doctor =>
    doctor.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    doctor.specialty.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const groupedDoctors = filteredDoctors.reduce((acc, doctor) => {
    const specialty = doctor.specialty || "Andere";
    if (!acc[specialty]) {
      acc[specialty] = [];
    }
    acc[specialty].push(doctor);
    return acc;
  }, {});

  const generateVoiceContent = () => {
    return `Heilberufe. ${doctors.length} Ärzte und Behandler gespeichert.`;
  };

  return (
    <div className="p-6 space-y-4 pb-24">
      <VoiceNavigation content={generateVoiceContent()} />
      
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Heilberufe</h1>
          <p className="text-gray-600">Ihre Ärzte und Behandler</p>
        </div>
      </div>

      {/* Voice Input Card */}
      {showVoiceInput && (
        <VoiceDataInput
          onDataExtracted={handleVoiceDataExtracted}
          entityType="doctor"
          promptText="Bitte nennen Sie mir den Namen, die Fachrichtung und die Adresse des Arztes."
        />
      )}

      {/* Search Card */}
      {showSearch && (
        <DoctorSearch onDoctorSelected={handleDoctorSelected} />
      )}

      {/* Summary Card */}
      <Card className="bg-gradient-to-r from-green-500 to-green-600 text-white border-0">
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-100 text-sm">Gespeicherte Ärzte</p>
              <p className="text-4xl font-bold">{doctors.length}</p>
            </div>
            <Stethoscope className="h-16 w-16 text-green-200" />
          </div>
        </CardContent>
      </Card>

      {/* Search Bar */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
        <Input
          placeholder="Arzt oder Fachrichtung suchen..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="pl-10 h-12"
        />
      </div>

      {/* Action Buttons */}
      <div className="grid grid-cols-3 gap-2">
        <Button 
          onClick={() => {
            setShowVoiceInput(!showVoiceInput);
            setShowSearch(false);
          }}
          size="lg" 
          className="h-12 bg-purple-600 hover:bg-purple-700"
        >
          <Mic className="h-5 w-5 mr-2" />
          Sprache
        </Button>
        <Button 
          onClick={() => {
            setShowSearch(!showSearch);
            setShowVoiceInput(false);
          }}
          size="lg" 
          className="h-12 bg-blue-600 hover:bg-blue-700"
        >
          <Search className="h-5 w-5 mr-2" />
          Suchen
        </Button>
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => handleOpenDialog()} size="lg" className="h-12">
              <Plus className="h-5 w-5 mr-2" />
              Neu
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {editingDoctor ? "Arzt bearbeiten" : "Neuer Arzt"}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-6 py-4">
              {/* Profile Image Upload */}
              <div>
                <Label>Profilbild</Label>
                <div className="mt-2 flex items-center gap-4">
                  {formData.profile_image_url ? (
                    <div className="relative">
                      <img 
                        src={formData.profile_image_url} 
                        alt="Profil" 
                        className="w-24 h-24 rounded-full object-cover border-4 border-gray-200"
                      />
                      <Button
                        onClick={() => setFormData({ ...formData, profile_image_url: "" })}
                        size="icon"
                        variant="destructive"
                        className="absolute -top-2 -right-2 h-8 w-8 rounded-full"
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  ) : (
                    <div className="w-24 h-24 rounded-full bg-gray-200 flex items-center justify-center">
                      <User className="h-12 w-12 text-gray-400" />
                    </div>
                  )}
                  <div className="flex-1">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleImageUpload}
                      className="hidden"
                      id="profile-image-upload"
                      disabled={uploadingImage}
                    />
                    <label htmlFor="profile-image-upload">
                      <Button
                        type="button"
                        variant="outline"
                        disabled={uploadingImage}
                        onClick={() => document.getElementById('profile-image-upload')?.click()}
                      >
                        <Upload className="h-4 w-4 mr-2" />
                        {uploadingImage ? "Lädt..." : "Bild hochladen"}
                      </Button>
                    </label>
                    <p className="text-xs text-gray-500 mt-1">
                      JPG, PNG oder GIF (max. 5MB)
                    </p>
                  </div>
                </div>
              </div>

              {/* Basic Information */}
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <Label>Name *</Label>
                  <Input
                    placeholder="Dr. med. Max Mustermann"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Fachrichtung *</Label>
                  <Select
                    value={formData.specialty}
                    onValueChange={(value) => setFormData({ ...formData, specialty: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Fachrichtung wählen" />
                    </SelectTrigger>
                    <SelectContent>
                      {specialties.map(specialty => (
                        <SelectItem key={specialty} value={specialty}>{specialty}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Behandlung seit</Label>
                  <Input
                    type="date"
                    value={formData.treating_since}
                    onChange={(e) => setFormData({ ...formData, treating_since: e.target.value })}
                  />
                </div>
              </div>

              {/* Specializations */}
              <div>
                <Label>Zusätzliche Spezialisierungen</Label>
                <div className="mt-2 flex flex-wrap gap-2">
                  {commonSpecializations.map(spec => (
                    <Badge
                      key={spec}
                      onClick={() => toggleSpecialization(spec)}
                      className={`cursor-pointer ${
                        (formData.specializations || []).includes(spec)
                          ? 'bg-green-600 hover:bg-green-700'
                          : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                      }`}
                    >
                      {spec}
                    </Badge>
                  ))}
                </div>
              </div>

              {/* Biography */}
              <div>
                <Label>Kurzbiografie / Über den Arzt</Label>
                <Textarea
                  placeholder="Berufserfahrung, Ausbildung, Behandlungsschwerpunkte..."
                  value={formData.biography}
                  onChange={(e) => setFormData({ ...formData, biography: e.target.value })}
                  rows={4}
                />
              </div>

              {/* Contact Information */}
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <Label>Adresse</Label>
                  <Input
                    placeholder="Musterstraße 123, 12345 Stadt"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Telefon</Label>
                  <Input
                    placeholder="+49 123 456789"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  />
                </div>
                <div>
                  <Label>E-Mail</Label>
                  <Input
                    type="email"
                    placeholder="praxis@beispiel.de"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>
              </div>

              {/* Opening Hours */}
              <div>
                <Label className="text-base font-semibold mb-3 block">Sprechzeiten</Label>
                <div className="space-y-2">
                  {weekDays.map(day => (
                    <div key={day.key} className="grid grid-cols-3 gap-3 items-center">
                      <Label className="text-sm">{day.label}</Label>
                      <Input
                        placeholder="z.B. 09:00-13:00, 14:00-18:00"
                        value={formData.opening_hours[day.key] || ""}
                        onChange={(e) => setFormData({
                          ...formData,
                          opening_hours: {
                            ...formData.opening_hours,
                            [day.key]: e.target.value
                          }
                        })}
                        className="col-span-2"
                      />
                    </div>
                  ))}
                </div>
                <p className="text-xs text-gray-500 mt-2">
                  Leer lassen für geschlossen
                </p>
              </div>

              {/* Notes */}
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

      {/* Doctors List */}
      {isLoading ? (
        <p className="text-center text-gray-500 py-8">Lade Ärzte...</p>
      ) : doctors.length === 0 ? (
        <Card className="border-2 border-dashed">
          <CardContent className="py-12 text-center">
            <Stethoscope className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 mb-4">Noch keine Ärzte eingetragen</p>
            <Button onClick={() => handleOpenDialog()}>
              <Plus className="h-5 w-5 mr-2" />
              Ersten Arzt hinzufügen
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-6">
          {Object.entries(groupedDoctors).map(([specialty, doctorsList]) => (
            <div key={specialty}>
              <h2 className="text-lg font-semibold text-gray-700 px-2 mb-3">{specialty}</h2>
              <div className="space-y-3">
                {doctorsList.map((doctor) => (
                  <Card key={doctor.id} className="border-2 hover:shadow-lg transition-shadow">
                    <CardContent className="p-4">
                      <div className="flex gap-4">
                        {/* Profile Image */}
                        {doctor.profile_image_url ? (
                          <img 
                            src={doctor.profile_image_url} 
                            alt={doctor.name}
                            className="w-20 h-20 rounded-full object-cover border-4 border-gray-200 flex-shrink-0"
                          />
                        ) : (
                          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center flex-shrink-0">
                            <Stethoscope className="h-10 w-10 text-white" />
                          </div>
                        )}

                        {/* Doctor Information */}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2 mb-2">
                            <div className="flex-1">
                              <h3 className="text-lg font-bold text-gray-900">{doctor.name}</h3>
                              <div className="flex flex-wrap gap-2 mt-1">
                                <Badge className="bg-green-600">{doctor.specialty}</Badge>
                                {(doctor.specializations || []).map((spec, idx) => (
                                  <Badge key={idx} variant="outline" className="text-xs">
                                    <Award className="h-3 w-3 mr-1" />
                                    {spec}
                                  </Badge>
                                ))}
                              </div>
                            </div>
                            <div className="flex gap-2">
                              <Button
                                onClick={() => handleOpenDialog(doctor)}
                                size="sm"
                                variant="outline"
                              >
                                Bearbeiten
                              </Button>
                              <Button
                                onClick={() => handleDelete(doctor.id)}
                                size="sm"
                                variant="ghost"
                              >
                                <Trash2 className="h-4 w-4 text-red-500" />
                              </Button>
                            </div>
                          </div>

                          {/* Biography */}
                          {doctor.biography && (
                            <p className="text-sm text-gray-600 mb-3 line-clamp-2">
                              {doctor.biography}
                            </p>
                          )}

                          {/* Contact Information */}
                          <div className="space-y-1 text-sm">
                            {doctor.address && (
                              <div className="flex items-start gap-2">
                                <MapPin className="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0" />
                                <span className="text-gray-700">{doctor.address}</span>
                              </div>
                            )}
                            {doctor.phone && (
                              <div className="flex items-center gap-2">
                                <Phone className="h-4 w-4 text-gray-400 flex-shrink-0" />
                                <a href={`tel:${doctor.phone}`} className="text-blue-600 hover:underline">
                                  {doctor.phone}
                                </a>
                              </div>
                            )}
                            {doctor.email && (
                              <div className="flex items-center gap-2">
                                <Mail className="h-4 w-4 text-gray-400 flex-shrink-0" />
                                <a href={`mailto:${doctor.email}`} className="text-blue-600 hover:underline">
                                  {doctor.email}
                                </a>
                              </div>
                            )}
                          </div>

                          {/* Opening Hours */}
                          {doctor.opening_hours && Object.values(doctor.opening_hours).some(hours => hours) && (
                            <div className="mt-3 p-3 bg-blue-50 rounded-lg border border-blue-200">
                              <div className="flex items-center gap-2 mb-2">
                                <Clock className="h-4 w-4 text-blue-600" />
                                <span className="text-sm font-semibold text-blue-900">Sprechzeiten</span>
                              </div>
                              <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
                                {weekDays.map(day => {
                                  const hours = doctor.opening_hours[day.key];
                                  if (!hours) return null;
                                  return (
                                    <div key={day.key} className="flex justify-between">
                                      <span className="text-gray-600">{day.label}:</span>
                                      <span className="text-gray-900 font-medium">{hours}</span>
                                    </div>
                                  );
                                })}
                              </div>
                            </div>
                          )}

                          {/* Treating Since */}
                          {doctor.treating_since && (
                            <div className="mt-2 flex items-center gap-2 text-xs text-gray-500">
                              <Calendar className="h-3 w-3" />
                              <span>Behandlung seit {new Date(doctor.treating_since).toLocaleDateString('de-DE', { month: 'long', year: 'numeric' })}</span>
                            </div>
                          )}

                          {/* Notes */}
                          {doctor.notes && (
                            <div className="mt-3 p-2 bg-yellow-50 rounded border border-yellow-200">
                              <p className="text-sm text-gray-700">{doctor.notes}</p>
                            </div>
                          )}
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