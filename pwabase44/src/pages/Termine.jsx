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
import { Plus, Calendar as CalendarIcon, Clock, MapPin, Trash2, Bell, Check, Mic, Mail } from "lucide-react";
import { toast } from "sonner";
import { format, isFuture, isPast, isToday } from "date-fns";
import { de } from "date-fns/locale";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import VoiceNavigation from "../components/VoiceNavigation";
import VoiceDataInput from "../components/VoiceDataInput";
import VoiceAppointmentAssistant from "../components/VoiceAppointmentAssistant";
import CalendarSync from "../components/CalendarSync";

export default function TerminePage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingAppt, setEditingAppt] = useState(null);
  const [showVoiceInput, setShowVoiceInput] = useState(false);
  const [showAIAssistant, setShowAIAssistant] = useState(false);
  const [showCalendarSync, setShowCalendarSync] = useState(false);
  const [formData, setFormData] = useState({
    doctor_name: "",
    specialty: "",
    date: "",
    time: "",
    location: "",
    reason: "",
    reminder_enabled: true,
    reminder_hours_before: 24,
    notes: "",
    status: "Geplant"
  });

  const { data: appointments, isLoading } = useQuery({
    queryKey: ['appointments'],
    queryFn: () => entities.Appointment.list('date'),
    initialData: [],
  });

  const { data: doctors } = useQuery({
    queryKey: ['healthcare-professionals'],
    queryFn: () => entities.HealthcareProfessional.list(),
    initialData: [],
  });

  const createNotification = async (appointment, type) => {
    const notificationMessages = {
      appointment_confirmation: {
        title: "Termin bestätigt",
        message: `Ihr Termin bei ${appointment.doctor_name} am ${format(new Date(appointment.date), 'dd.MM.yyyy', { locale: de })} um ${appointment.time} Uhr wurde bestätigt.`,
        priority: "medium"
      },
      appointment_change: {
        title: "Termin geändert",
        message: `Ihr Termin bei ${appointment.doctor_name} wurde auf den ${format(new Date(appointment.date), 'dd.MM.yyyy', { locale: de })} um ${appointment.time} Uhr verschoben.`,
        priority: "high"
      },
      appointment_cancellation: {
        title: "Termin storniert",
        message: `Ihr Termin bei ${appointment.doctor_name} am ${format(new Date(appointment.date), 'dd.MM.yyyy', { locale: de })} wurde storniert.`,
        priority: "high"
      }
    };

    const notificationData = notificationMessages[type];
    if (!notificationData) return;

    try {
      await entities.Notification.create({
        ...notificationData,
        type: type,
        action_url: "/Termine",
        related_appointment_id: appointment.id || null
      });
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    } catch (error) {
      console.error("Failed to create notification:", error);
    }
  };

  const sendAppointmentEmail = async (appointment, isUpdate = false) => {
    try {
      const user = await base44.auth.me();
      const doctor = doctors.find(d => d.name === appointment.doctor_name);
      
      const emailSubject = isUpdate 
        ? `Terminänderung: ${appointment.doctor_name}` 
        : `Terminbestätigung: ${appointment.doctor_name}`;
      
      const emailBody = `
Hallo ${user.full_name || 'Patient'},

${isUpdate ? 'Ihr Termin wurde geändert' : 'Ihr Termin wurde erfolgreich gebucht'}:

📅 Datum: ${format(new Date(appointment.date), 'EEEE, dd. MMMM yyyy', { locale: de })}
🕐 Uhrzeit: ${appointment.time} Uhr
👨‍⚕️ Arzt/Behandler: ${appointment.doctor_name}
${appointment.specialty ? `🏥 Fachrichtung: ${appointment.specialty}` : ''}
${appointment.location ? `📍 Ort: ${appointment.location}` : ''}
${appointment.reason ? `📋 Grund: ${appointment.reason}` : ''}
${appointment.reminder_enabled ? `🔔 Erinnerung: ${appointment.reminder_hours_before} Stunden vorher` : ''}
${appointment.notes ? `\n📝 Notizen: ${appointment.notes}` : ''}

Status: ${appointment.status}

Bitte erscheinen Sie pünktlich zu Ihrem Termin.

Mit freundlichen Grüßen,
Ihr Gesundheit Plus Team
      `.trim();

      await base44.integrations.Core.SendEmail({
        from_name: "Gesundheit Plus - Terminservice",
        to: user.email,
        subject: emailSubject,
        body: emailBody
      });

      if (doctor && doctor.email) {
        const doctorEmailBody = `
Neue Terminbuchung:

Patient: ${user.full_name || 'Unbekannt'} (${user.email})
Datum: ${format(new Date(appointment.date), 'EEEE, dd. MMMM yyyy', { locale: de })}
Uhrzeit: ${appointment.time} Uhr
${appointment.reason ? `Grund: ${appointment.reason}` : ''}
${appointment.notes ? `Notizen: ${appointment.notes}` : ''}

Status: ${appointment.status}
        `.trim();

        await base44.integrations.Core.SendEmail({
          from_name: "Gesundheit Plus - Patiententermine",
          to: doctor.email,
          subject: `Neue Terminbuchung: ${user.full_name || 'Patient'} - ${format(new Date(appointment.date), 'dd.MM.yyyy')}`,
          body: doctorEmailBody
        });
      }

      toast.success("✉️ Bestätigungs-E-Mail versendet");
    } catch (error) {
      console.error("Email sending failed:", error);
      toast.error("E-Mail konnte nicht versendet werden");
    }
  };

  const sendCancellationEmail = async (appointment) => {
    try {
      const user = await base44.auth.me();
      const doctor = doctors.find(d => d.name === appointment.doctor_name);
      
      const emailBody = `
Hallo ${user.full_name || 'Patient'},

Ihr Termin wurde storniert:

📅 Datum: ${format(new Date(appointment.date), 'EEEE, dd. MMMM yyyy', { locale: de })}
🕐 Uhrzeit: ${appointment.time} Uhr
👨‍⚕️ Arzt/Behandler: ${appointment.doctor_name}

Bei Fragen wenden Sie sich bitte an Ihren Arzt oder die Praxis.

Mit freundlichen Grüßen,
Ihr Gesundheit Plus Team
      `.trim();

      await base44.integrations.Core.SendEmail({
        from_name: "Gesundheit Plus - Terminservice",
        to: user.email,
        subject: `Terminstornierung: ${appointment.doctor_name}`,
        body: emailBody
      });

      if (doctor && doctor.email) {
        await base44.integrations.Core.SendEmail({
          from_name: "Gesundheit Plus - Patiententermine",
          to: doctor.email,
          subject: `Terminstornierung: ${user.full_name || 'Patient'} - ${format(new Date(appointment.date), 'dd.MM.yyyy')}`,
          body: `Patient ${user.full_name || 'Unbekannt'} (${user.email}) hat den Termin am ${format(new Date(appointment.date), 'dd.MM.yyyy')} um ${appointment.time} Uhr storniert.`
        });
      }

      toast.success("✉️ Stornierungsbestätigung versendet");
    } catch (error) {
      console.error("Email sending failed:", error);
    }
  };

  const saveMutation = useMutation({
    mutationFn: (data) => {
      if (editingAppt) {
        return entities.Appointment.update(editingAppt.id, data);
      }
      return entities.Appointment.create(data);
    },
    onSuccess: async (result, variables) => {
      queryClient.invalidateQueries({ queryKey: ['appointments'] });
      const isUpdate = !!editingAppt;
      toast.success(isUpdate ? "Termin aktualisiert" : "Termin hinzugefügt");
      
      // Create notification
      await createNotification(
        { ...variables, id: result.id || editingAppt?.id },
        isUpdate ? 'appointment_change' : 'appointment_confirmation'
      );
      
      // Send email notification
      await sendAppointmentEmail(variables, isUpdate);
      
      handleCloseDialog();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => entities.Appointment.delete(id),
    onSuccess: async (result, id) => {
      const deletedAppt = appointments.find(a => a.id === id);
      if (deletedAppt) {
        await createNotification(deletedAppt, 'appointment_cancellation');
        await sendCancellationEmail(deletedAppt);
      }
      queryClient.invalidateQueries({ queryKey: ['appointments'] });
      toast.success("Termin entfernt");
    },
  });

  const handleOpenDialog = (appt = null) => {
    if (appt) {
      setEditingAppt(appt);
      setFormData(appt);
    } else {
      setEditingAppt(null);
      setFormData({
        doctor_name: "",
        specialty: "",
        date: "",
        time: "",
        location: "",
        reason: "",
        reminder_enabled: true,
        reminder_hours_before: 24,
        notes: "",
        status: "Geplant"
      });
    }
    setIsDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingAppt(null);
  };

  const handleSave = () => {
    if (!formData.doctor_name || !formData.date || !formData.time) {
      toast.error("Bitte Arzt, Datum und Uhrzeit eingeben");
      return;
    }
    saveMutation.mutate(formData);
  };

  const handleDelete = (id) => {
    if (confirm("Möchten Sie diesen Termin wirklich entfernen?")) {
      deleteMutation.mutate(id);
    }
  };

  const markAsCompleted = (appt) => {
    saveMutation.mutate({ ...appt, status: "Abgeschlossen" });
  };

  const handleVoiceDataExtracted = (data) => {
    setFormData({
      ...formData,
      doctor_name: data.doctor_name || formData.doctor_name,
      date: data.date || formData.date,
      time: data.time || formData.time,
      reason: data.reason || formData.reason
    });
    setShowVoiceInput(false);
    setIsDialogOpen(true);
    toast.success("Daten aus Spracheingabe übernommen");
  };

  const handleAIAppointmentChanged = () => {
    queryClient.invalidateQueries({ queryKey: ['appointments'] });
  };

  const upcomingAppointments = appointments.filter(a => 
    isFuture(new Date(`${a.date}T${a.time}`)) || isToday(new Date(a.date))
  );
  const pastAppointments = appointments.filter(a => 
    isPast(new Date(`${a.date}T${a.time}`)) && !isToday(new Date(a.date))
  );

  const generateVoiceContent = () => {
    const upcomingCount = upcomingAppointments.length;
    let content = `Termine. ${upcomingCount} anstehende Termine. `;
    if (upcomingCount > 0) {
      const nextAppt = upcomingAppointments[0];
      content += `Nächster Termin: ${nextAppt.doctor_name} am ${format(new Date(nextAppt.date), 'dd. MMMM', { locale: de })} um ${nextAppt.time} Uhr. `;
    }
    return content;
  };

  return (
    <div className="p-6 space-y-4 pb-24">
      <VoiceNavigation content={generateVoiceContent()} />
      
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Termine</h1>
          <p className="text-gray-600">Ihre Arzttermine im Überblick</p>
        </div>
      </div>

      {showCalendarSync && (
        <CalendarSync appointments={appointments} />
      )}

      <Card className="bg-gradient-to-r from-blue-500 to-blue-600 text-white border-0">
        <CardContent className="pt-6">
          <div className="flex items-start gap-3">
            <Mail className="h-6 w-6 flex-shrink-0 mt-1" />
            <div>
              <p className="font-semibold mb-1">Automatische E-Mail-Bestätigungen</p>
              <p className="text-sm text-blue-100">
                Sie erhalten eine Bestätigung per E-Mail bei jedem neuen, geänderten oder stornierten Termin. 
                Ihr Arzt wird ebenfalls automatisch benachrichtigt.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {showAIAssistant && !showCalendarSync && (
        <VoiceAppointmentAssistant onAppointmentChanged={handleAIAppointmentChanged} />
      )}

      {showVoiceInput && !showAIAssistant && !showCalendarSync && (
        <VoiceDataInput
          onDataExtracted={handleVoiceDataExtracted}
          entityType="appointment"
          promptText="Bitte nennen Sie mir den Arzt, das Datum, die Uhrzeit und den Grund des Termins."
        />
      )}

      <Card className="bg-gradient-to-r from-red-500 to-red-600 text-white border-0">
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-red-100 text-sm">Anstehende Termine</p>
              <p className="text-4xl font-bold">{upcomingAppointments.length}</p>
            </div>
            <CalendarIcon className="h-16 w-16 text-red-200" />
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-4 gap-2">
        <Button 
          onClick={() => {
            setShowAIAssistant(!showAIAssistant);
            setShowVoiceInput(false);
            setShowCalendarSync(false);
          }} 
          size="lg" 
          className={`h-12 ${showAIAssistant ? 'bg-indigo-700' : 'bg-indigo-600'} hover:bg-indigo-700`}
        >
          <CalendarIcon className="h-5 w-5 mr-1" />
          <span className="text-xs">KI</span>
        </Button>
        <Button 
          onClick={() => {
            setShowVoiceInput(!showVoiceInput);
            setShowAIAssistant(false);
            setShowCalendarSync(false);
          }} 
          size="lg" 
          className="h-12 bg-purple-600 hover:bg-purple-700"
        >
          <Mic className="h-5 w-5 mr-1" />
          <span className="text-xs">Sprache</span>
        </Button>
        <Button 
          onClick={() => {
            setShowCalendarSync(!showCalendarSync);
            setShowAIAssistant(false);
            setShowVoiceInput(false);
          }} 
          size="lg" 
          className={`h-12 ${showCalendarSync ? 'bg-green-700' : 'bg-green-600'} hover:bg-green-700`}
        >
          <CalendarIcon className="h-5 w-5 mr-1" />
          <span className="text-xs">Sync</span>
        </Button>
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => handleOpenDialog()} size="lg" className="h-12">
              <Plus className="h-5 w-5 mr-1" />
              <span className="text-xs">Neu</span>
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {editingAppt ? "Termin bearbeiten" : "Neuer Termin"}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div>
                <Label>Arzt / Behandler *</Label>
                <Input
                  placeholder="Dr. Mustermann"
                  value={formData.doctor_name}
                  onChange={(e) => setFormData({ ...formData, doctor_name: e.target.value })}
                />
              </div>
              <div>
                <Label>Fachrichtung</Label>
                <Input
                  placeholder="z.B. Allgemeinmedizin"
                  value={formData.specialty}
                  onChange={(e) => setFormData({ ...formData, specialty: e.target.value })}
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label>Datum *</Label>
                  <Input
                    type="date"
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                  />
                </div>
                <div>
                  <Label>Uhrzeit *</Label>
                  <Input
                    type="time"
                    value={formData.time}
                    onChange={(e) => setFormData({ ...formData, time: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <Label>Ort / Adresse</Label>
                <Input
                  placeholder="Praxisadresse"
                  value={formData.location}
                  onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                />
              </div>
              <div>
                <Label>Grund</Label>
                <Input
                  placeholder="z.B. Vorsorgeuntersuchung"
                  value={formData.reason}
                  onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                />
              </div>
              <div>
                <Label>Status</Label>
                <Select
                  value={formData.status}
                  onValueChange={(value) => setFormData({ ...formData, status: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {["Geplant", "Bestätigt", "Abgeschlossen", "Abgesagt"].map(status => (
                      <SelectItem key={status} value={status}>{status}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label>Erinnerung (Stunden vorher)</Label>
                <Input
                  type="number"
                  value={formData.reminder_hours_before}
                  onChange={(e) => setFormData({ ...formData, reminder_hours_before: parseInt(e.target.value) })}
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

      {isLoading ? (
        <p className="text-center text-gray-500 py-8">Lade Termine...</p>
      ) : appointments.length === 0 ? (
        <Card className="border-2 border-dashed">
          <CardContent className="py-12 text-center">
            <CalendarIcon className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 mb-4">Noch keine Termine eingetragen</p>
            <Button onClick={() => handleOpenDialog()}>
              <Plus className="h-5 w-5 mr-2" />
              Ersten Termin hinzufügen
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-6">
          {upcomingAppointments.length > 0 && (
            <>
              <h2 className="text-lg font-semibold text-gray-700 px-2">Anstehende Termine</h2>
              <div className="space-y-3">
                {upcomingAppointments.map((appt) => {
                  const apptDate = new Date(`${appt.date}T${appt.time}`);
                  const isTodayAppointment = isToday(new Date(appt.date));
                  
                  return (
                    <Card key={appt.id} className={`border-2 hover:shadow-lg transition-shadow ${isTodayAppointment ? 'border-red-300 bg-red-50' : ''}`}>
                      <CardContent className="p-4">
                        <div className="flex justify-between items-start mb-3">
                          <div className="flex-1">
                            <div className="flex items-start gap-3">
                              <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${isTodayAppointment ? 'from-red-500 to-red-600' : 'from-blue-500 to-blue-600'} flex items-center justify-center flex-shrink-0`}>
                                <CalendarIcon className="h-6 w-6 text-white" />
                              </div>
                              <div className="flex-1">
                                <h3 className="text-lg font-bold text-gray-900">{appt.doctor_name}</h3>
                                {appt.specialty && (
                                  <p className="text-sm text-gray-600">{appt.specialty}</p>
                                )}
                                <div className="flex flex-wrap items-center gap-3 mt-2 text-sm">
                                  <div className="flex items-center gap-1 text-gray-700">
                                    <CalendarIcon className="h-4 w-4" />
                                    <span>{format(new Date(appt.date), 'EEEE, dd. MMMM yyyy', { locale: de })}</span>
                                  </div>
                                  <div className="flex items-center gap-1 text-gray-700">
                                    <Clock className="h-4 w-4" />
                                    <span>{appt.time} Uhr</span>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                          <div className="flex gap-2">
                            <Button
                              onClick={() => handleOpenDialog(appt)}
                              size="sm"
                              variant="outline"
                            >
                              Bearbeiten
                            </Button>
                            <Button
                              onClick={() => handleDelete(appt.id)}
                              size="sm"
                              variant="ghost"
                            >
                              <Trash2 className="h-4 w-4 text-red-500" />
                            </Button>
                          </div>
                        </div>

                        <div className="space-y-2">
                          {appt.location && (
                            <div className="flex items-start gap-2 text-sm">
                              <MapPin className="h-4 w-4 text-gray-400 mt-0.5" />
                              <span className="text-gray-700">{appt.location}</span>
                            </div>
                          )}
                          {appt.reason && (
                            <p className="text-sm text-gray-700">
                              <span className="font-semibold">Grund:</span> {appt.reason}
                            </p>
                          )}
                          <div className="flex flex-wrap gap-2 mt-2">
                            <Badge variant={
                              appt.status === "Bestätigt" ? "default" : 
                              appt.status === "Abgeschlossen" ? "secondary" : 
                              appt.status === "Abgesagt" ? "destructive" : "outline"
                            }>
                              {appt.status}
                            </Badge>
                            {appt.reminder_enabled && (
                              <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
                                <Bell className="h-3 w-3 mr-1" />
                                {appt.reminder_hours_before}h vorher
                              </Badge>
                            )}
                            {isTodayAppointment && (
                              <Badge className="bg-red-100 text-red-700 border-red-200">
                                Heute!
                              </Badge>
                            )}
                          </div>
                          {appt.notes && (
                            <div className="mt-2 p-2 bg-yellow-50 rounded border border-yellow-200">
                              <p className="text-sm text-gray-700">{appt.notes}</p>
                            </div>
                          )}
                          {appt.status !== "Abgeschlossen" && isPast(apptDate) && (
                            <Button
                              onClick={() => markAsCompleted(appt)}
                              size="sm"
                              variant="outline"
                              className="w-full mt-2"
                            >
                              <Check className="h-4 w-4 mr-1" />
                              Als abgeschlossen markieren
                            </Button>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
              </div>
            </>
          )}

          {pastAppointments.length > 0 && (
            <>
              <h2 className="text-lg font-semibold text-gray-700 px-2 mt-6">Vergangene Termine</h2>
              <div className="space-y-3">
                {pastAppointments.slice(0, 5).map((appt) => (
                  <Card key={appt.id} className="border-2 opacity-75">
                    <CardContent className="p-4">
                      <div className="flex justify-between items-start">
                        <div>
                          <h3 className="text-lg font-bold text-gray-900">{appt.doctor_name}</h3>
                          <p className="text-sm text-gray-600">
                            {format(new Date(appt.date), 'dd.MM.yyyy', { locale: de })} • {appt.time} Uhr
                          </p>
                          {appt.reason && (
                            <p className="text-sm text-gray-600 mt-1">{appt.reason}</p>
                          )}
                        </div>
                        <Badge variant="secondary">{appt.status}</Badge>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}