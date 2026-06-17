import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Calendar, Download, Link as LinkIcon, Settings } from "lucide-react";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";
import { format } from "date-fns";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

export default function CalendarSync({ appointments }) {
  const [syncPreference, setSyncPreference] = useState("upcoming");
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const generateICalContent = (appointmentsToSync) => {
    const icalEvents = appointmentsToSync.map(appt => {
      const startDate = new Date(`${appt.date}T${appt.time}`);
      const endDate = new Date(startDate.getTime() + 60 * 60 * 1000); // 1 hour duration
      
      const formatICalDate = (date) => {
        return date.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z';
      };

      const description = [
        appt.specialty ? `Fachrichtung: ${appt.specialty}` : '',
        appt.reason ? `Grund: ${appt.reason}` : '',
        appt.location ? `Ort: ${appt.location}` : '',
        appt.notes ? `Notizen: ${appt.notes}` : ''
      ].filter(Boolean).join('\\n');

      return `BEGIN:VEVENT
UID:${appt.id}@gesundheitplus.app
DTSTAMP:${formatICalDate(new Date())}
DTSTART:${formatICalDate(startDate)}
DTEND:${formatICalDate(endDate)}
SUMMARY:Arzttermin: ${appt.doctor_name}
DESCRIPTION:${description}
LOCATION:${appt.location || ''}
STATUS:${appt.status === 'Bestätigt' ? 'CONFIRMED' : 'TENTATIVE'}
BEGIN:VALARM
TRIGGER:-PT${appt.reminder_hours_before || 24}H
ACTION:DISPLAY
DESCRIPTION:Erinnerung: Termin bei ${appt.doctor_name}
END:VALARM
END:VEVENT`;
    }).join('\n');

    return `BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Gesundheit Plus//Terminkalender//DE
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:Gesundheit Plus Termine
X-WR-TIMEZONE:Europe/Berlin
X-WR-CALDESC:Ihre Arzttermine aus Gesundheit Plus
${icalEvents}
END:VCALENDAR`;
  };

  const getFilteredAppointments = () => {
    if (syncPreference === "all") {
      return appointments;
    } else if (syncPreference === "upcoming") {
      const now = new Date();
      return appointments.filter(appt => {
        const apptDate = new Date(`${appt.date}T${appt.time}`);
        return apptDate >= now;
      });
    }
    return [];
  };

  const handleDownloadICalFile = () => {
    const filteredAppointments = getFilteredAppointments();
    
    if (filteredAppointments.length === 0) {
      toast.error("Keine Termine zum Exportieren vorhanden");
      return;
    }

    const icalContent = generateICalContent(filteredAppointments);
    const blob = new Blob([icalContent], { type: 'text/calendar;charset=utf-8' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `gesundheit-plus-termine-${format(new Date(), 'yyyy-MM-dd')}.ics`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
    
    toast.success(`${filteredAppointments.length} Termin(e) exportiert`);
  };

  const handleSavePreference = async () => {
    setIsLoading(true);
    try {
      await base44.auth.updateMe({
        calendar_sync_preference: syncPreference
      });
      toast.success("Einstellungen gespeichert");
      setIsDialogOpen(false);
    } catch (error) {
      toast.error("Fehler beim Speichern der Einstellungen");
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredCount = getFilteredAppointments().length;

  return (
    <Card className="border-2 bg-gradient-to-br from-indigo-50 to-purple-50">
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          <Calendar className="h-5 w-5" />
          Kalender Synchronisation
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-gray-600">
          Exportieren Sie Ihre Termine und importieren Sie sie in Google Calendar, Outlook, Apple Calendar oder andere Kalender-Apps.
        </p>

        <div className="space-y-2">
          <Label>Welche Termine synchronisieren?</Label>
          <Select value={syncPreference} onValueChange={setSyncPreference}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">
                📅 Alle Termine ({appointments.length})
              </SelectItem>
              <SelectItem value="upcoming">
                ⏰ Nur anstehende Termine ({appointments.filter(a => new Date(`${a.date}T${a.time}`) >= new Date()).length})
              </SelectItem>
              <SelectItem value="none">
                🚫 Keine Synchronisation
              </SelectItem>
            </SelectContent>
          </Select>
        </div>

        {syncPreference !== "none" && (
          <div className="bg-white rounded-lg p-4 border-2 border-gray-200">
            <p className="text-sm font-semibold text-gray-700 mb-2">
              {filteredCount} Termin(e) bereit zum Export
            </p>
            <div className="flex flex-col gap-2">
              <Button
                onClick={handleDownloadICalFile}
                className="w-full bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700"
              >
                <Download className="h-4 w-4 mr-2" />
                .ics Datei herunterladen
              </Button>
            </div>
          </div>
        )}

        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button variant="outline" className="w-full">
              <Settings className="h-4 w-4 mr-2" />
              Einstellungen speichern
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Kalender-Sync Einstellungen</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <p className="text-sm text-gray-600">
                Ihre Sync-Präferenz wird gespeichert und beim nächsten Export automatisch verwendet.
              </p>
              <div className="space-y-2">
                <Label>Aktuelle Auswahl</Label>
                <div className="p-3 bg-blue-50 rounded-lg border border-blue-200">
                  <p className="text-sm font-semibold text-blue-900">
                    {syncPreference === "all" ? "Alle Termine" : 
                     syncPreference === "upcoming" ? "Nur anstehende Termine" : 
                     "Keine Synchronisation"}
                  </p>
                </div>
              </div>
              <Button 
                onClick={handleSavePreference} 
                className="w-full"
                disabled={isLoading}
              >
                {isLoading ? "Speichere..." : "Einstellung speichern"}
              </Button>
            </div>
          </DialogContent>
        </Dialog>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-xs text-blue-800 mb-2">
            <strong>So funktioniert's:</strong>
          </p>
          <ol className="text-xs text-blue-800 space-y-1 list-decimal list-inside">
            <li>Wählen Sie Ihre Sync-Option</li>
            <li>Laden Sie die .ics Datei herunter</li>
            <li>Öffnen Sie die Datei mit Ihrer Kalender-App</li>
            <li>Bestätigen Sie den Import</li>
          </ol>
        </div>

        <div className="grid grid-cols-4 gap-2">
          <div className="flex flex-col items-center p-2 bg-white rounded border">
            <Calendar className="h-5 w-5 text-blue-600 mb-1" />
            <span className="text-xs text-gray-600">Google</span>
          </div>
          <div className="flex flex-col items-center p-2 bg-white rounded border">
            <Calendar className="h-5 w-5 text-blue-500 mb-1" />
            <span className="text-xs text-gray-600">Outlook</span>
          </div>
          <div className="flex flex-col items-center p-2 bg-white rounded border">
            <Calendar className="h-5 w-5 text-gray-600 mb-1" />
            <span className="text-xs text-gray-600">Apple</span>
          </div>
          <div className="flex flex-col items-center p-2 bg-white rounded border">
            <Calendar className="h-5 w-5 text-purple-600 mb-1" />
            <span className="text-xs text-gray-600">Andere</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}