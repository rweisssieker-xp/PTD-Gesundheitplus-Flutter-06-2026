import React, { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import {
  CheckCircle,
  Circle,
  XCircle,
  Clock,
  Pill,
  Calendar,
  Mic,
  ChevronLeft,
  ChevronRight,
  Bell,
  TrendingUp
} from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import VoiceInput from "@/components/VoiceInput";

export default function MedikamentenTagesplanPage() {
  const queryClient = useQueryClient();
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedLog, setSelectedLog] = useState(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [notes, setNotes] = useState("");
  const [showVoiceConfirm, setShowVoiceConfirm] = useState(false);
  const [pendingConfirmation, setPendingConfirmation] = useState(null);

  const dateStr = selectedDate.toISOString().split('T')[0];
  const isToday = dateStr === new Date().toISOString().split('T')[0];

  // Lade aktive Medikamente
  const { data: medications = [] } = useQuery({
    queryKey: ['medications-active'],
    queryFn: () => base44.entities.Medication.filter({ active: true })
  });

  // Lade Einnahme-Logs für den Tag
  const { data: logs = [], isLoading } = useQuery({
    queryKey: ['medication-logs', dateStr],
    queryFn: () => base44.entities.MedicationLog.filter({ date: dateStr })
  });

  // Erstelle Logs für neue Tage
  useEffect(() => {
    if (medications.length > 0 && isToday && logs.length === 0) {
      initializeTodayLogs();
    }
  }, [medications, logs, isToday]);

  const initializeTodayLogs = async () => {
    const logsToCreate = [];
    
    medications.forEach(med => {
      if (!med.reminder_enabled || !med.reminder_times) return;
      
      med.reminder_times.forEach(time => {
        if (!time) return;
        
        logsToCreate.push({
          medication_id: med.id,
          medication_name: med.name,
          scheduled_time: time,
          dosage_taken: med.dosage,
          status: "pending",
          date: dateStr
        });
      });
    });

    if (logsToCreate.length > 0) {
      await Promise.all(
        logsToCreate.map(log => base44.entities.MedicationLog.create(log))
      );
      queryClient.invalidateQueries({ queryKey: ['medication-logs', dateStr] });
    }
  };

  const updateLogMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.MedicationLog.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['medication-logs'] });
      toast.success("Status aktualisiert");
      setIsDialogOpen(false);
    }
  });

  const handleMarkAsTaken = (log) => {
    updateLogMutation.mutate({
      id: log.id,
      data: {
        ...log,
        status: "taken",
        taken_at: new Date().toISOString(),
        notes: notes || log.notes
      }
    });
  };

  const handleMarkAsSkipped = (log) => {
    updateLogMutation.mutate({
      id: log.id,
      data: {
        ...log,
        status: "skipped"
      }
    });
  };

  const handleOpenDialog = (log) => {
    setSelectedLog(log);
    setNotes(log.notes || "");
    setIsDialogOpen(true);
  };

  const handleVoiceConfirm = (log) => {
    setPendingConfirmation(log);
    setShowVoiceConfirm(true);
  };

  const handleVoiceResult = (transcript) => {
    const text = transcript.toLowerCase();
    
    if (text.includes("eingenommen") || text.includes("genommen") || text.includes("ja")) {
      updateLogMutation.mutate({
        id: pendingConfirmation.id,
        data: {
          ...pendingConfirmation,
          status: "taken",
          taken_at: new Date().toISOString(),
          confirmed_by_voice: true,
          notes: transcript
        }
      });
      setShowVoiceConfirm(false);
      setPendingConfirmation(null);
    } else if (text.includes("nicht") || text.includes("nein") || text.includes("vergessen")) {
      toast.info("Einnahme wurde nicht bestätigt");
      setShowVoiceConfirm(false);
      setPendingConfirmation(null);
    } else {
      toast.error("Bitte sagen Sie 'eingenommen' oder 'nicht eingenommen'");
    }
  };

  const changeDate = (days) => {
    const newDate = new Date(selectedDate);
    newDate.setDate(newDate.getDate() + days);
    setSelectedDate(newDate);
  };

  // Gruppiere Logs nach Uhrzeit
  const sortedLogs = [...logs].sort((a, b) => 
    a.scheduled_time.localeCompare(b.scheduled_time)
  );

  // Statistiken
  const stats = {
    total: logs.length,
    taken: logs.filter(l => l.status === "taken").length,
    pending: logs.filter(l => l.status === "pending").length,
    missed: logs.filter(l => l.status === "missed").length,
    skipped: logs.filter(l => l.status === "skipped").length
  };

  const adherenceRate = stats.total > 0 
    ? Math.round((stats.taken / stats.total) * 100) 
    : 0;

  return (
    <div className="p-6 space-y-6 pb-24">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Medikamenten-Tagesplan
        </h1>
        <p className="text-gray-600">Verfolgen Sie Ihre Einnahmen</p>
      </div>

      {/* Datum-Navigation */}
      <Card className="border-2">
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <Button
              onClick={() => changeDate(-1)}
              variant="outline"
              size="icon"
            >
              <ChevronLeft className="h-5 w-5" />
            </Button>
            
            <div className="text-center">
              <div className="flex items-center gap-2 justify-center">
                <Calendar className="h-5 w-5 text-blue-600" />
                <h2 className="text-xl font-bold">
                  {selectedDate.toLocaleDateString('de-DE', { 
                    weekday: 'long',
                    day: 'numeric',
                    month: 'long'
                  })}
                </h2>
              </div>
              {isToday && (
                <Badge className="mt-1 bg-green-600">Heute</Badge>
              )}
            </div>

            <Button
              onClick={() => changeDate(1)}
              variant="outline"
              size="icon"
              disabled={isToday}
            >
              <ChevronRight className="h-5 w-5" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Statistiken */}
      {stats.total > 0 && (
        <div className="grid grid-cols-2 gap-3">
          <Card className="border-2 border-green-200 bg-green-50">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-green-700">Eingenommen</p>
                  <p className="text-3xl font-bold text-green-900">
                    {stats.taken}/{stats.total}
                  </p>
                </div>
                <CheckCircle className="h-10 w-10 text-green-600" />
              </div>
            </CardContent>
          </Card>

          <Card className="border-2 border-blue-200 bg-blue-50">
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-blue-700">Treue-Rate</p>
                  <p className="text-3xl font-bold text-blue-900">
                    {adherenceRate}%
                  </p>
                </div>
                <TrendingUp className="h-10 w-10 text-blue-600" />
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Voice Confirm Dialog */}
      {showVoiceConfirm && pendingConfirmation && (
        <Card className="border-2 border-purple-300 bg-purple-50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-purple-900">
              <Mic className="h-5 w-5" />
              Sprachbestätigung
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="bg-white p-4 rounded-lg">
              <p className="font-semibold text-gray-900">
                {pendingConfirmation.medication_name}
              </p>
              <p className="text-sm text-gray-600">
                um {pendingConfirmation.scheduled_time}
              </p>
            </div>
            <VoiceInput
              onTranscriptComplete={handleVoiceResult}
              promptText="Haben Sie das Medikament eingenommen?"
            />
            <Button
              onClick={() => {
                setShowVoiceConfirm(false);
                setPendingConfirmation(null);
              }}
              variant="outline"
              className="w-full"
            >
              Abbrechen
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Medikamenten-Liste */}
      {isLoading ? (
        <p className="text-center text-gray-500 py-8">Lade Plan...</p>
      ) : sortedLogs.length === 0 ? (
        <Card className="border-2 border-dashed">
          <CardContent className="py-12 text-center">
            <Bell className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 mb-2">
              {isToday 
                ? "Keine Erinnerungen für heute"
                : "Keine Daten für diesen Tag"}
            </p>
            {!isToday && (
              <Button onClick={() => setSelectedDate(new Date())} size="sm">
                Zu heute springen
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {sortedLogs.map((log) => {
            const statusConfig = {
              taken: {
                icon: CheckCircle,
                color: "text-green-600",
                bgColor: "bg-green-50",
                borderColor: "border-green-300",
                label: "Eingenommen"
              },
              pending: {
                icon: Circle,
                color: "text-gray-400",
                bgColor: "bg-white",
                borderColor: "border-gray-200",
                label: "Ausstehend"
              },
              skipped: {
                icon: XCircle,
                color: "text-orange-600",
                bgColor: "bg-orange-50",
                borderColor: "border-orange-300",
                label: "Übersprungen"
              },
              missed: {
                icon: XCircle,
                color: "text-red-600",
                bgColor: "bg-red-50",
                borderColor: "border-red-300",
                label: "Verpasst"
              }
            };

            const config = statusConfig[log.status] || statusConfig.pending;
            const Icon = config.icon;

            return (
              <Card 
                key={log.id} 
                className={`border-2 ${config.borderColor} ${config.bgColor}`}
              >
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    <div className={`w-12 h-12 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center flex-shrink-0`}>
                      <Pill className="h-6 w-6 text-white" />
                    </div>

                    <div className="flex-1">
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <h3 className="font-bold text-gray-900">
                            {log.medication_name}
                          </h3>
                          <div className="flex items-center gap-2 text-sm text-gray-600">
                            <Clock className="h-3 w-3" />
                            <span>{log.scheduled_time} Uhr</span>
                            {log.dosage_taken && (
                              <span>• {log.dosage_taken}</span>
                            )}
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <Icon className={`h-6 w-6 ${config.color}`} />
                        </div>
                      </div>

                      <div className="flex items-center gap-1 mb-3">
                        <Badge className={config.color + " bg-white"}>
                          {config.label}
                        </Badge>
                        {log.confirmed_by_voice && (
                          <Badge variant="outline" className="text-purple-700">
                            <Mic className="h-3 w-3 mr-1" />
                            Per Sprache
                          </Badge>
                        )}
                      </div>

                      {log.taken_at && (
                        <p className="text-xs text-gray-500 mb-2">
                          Eingenommen um {new Date(log.taken_at).toLocaleTimeString('de-DE', { 
                            hour: '2-digit', 
                            minute: '2-digit' 
                          })}
                        </p>
                      )}

                      {log.notes && (
                        <div className="bg-white/50 rounded p-2 mb-3 text-sm text-gray-700">
                          {log.notes}
                        </div>
                      )}

                      {log.status === "pending" && isToday && (
                        <div className="flex gap-2">
                          <Button
                            onClick={() => handleOpenDialog(log)}
                            size="sm"
                            className="flex-1 bg-green-600 hover:bg-green-700"
                          >
                            <CheckCircle className="h-4 w-4 mr-1" />
                            Eingenommen
                          </Button>
                          <Button
                            onClick={() => handleVoiceConfirm(log)}
                            size="sm"
                            variant="outline"
                            className="flex-1"
                          >
                            <Mic className="h-4 w-4 mr-1" />
                            Sprache
                          </Button>
                          <Button
                            onClick={() => handleMarkAsSkipped(log)}
                            size="sm"
                            variant="ghost"
                          >
                            <XCircle className="h-4 w-4" />
                          </Button>
                        </div>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Confirmation Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Einnahme bestätigen</DialogTitle>
          </DialogHeader>
          {selectedLog && (
            <div className="space-y-4 py-4">
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="font-semibold text-gray-900">{selectedLog.medication_name}</p>
                <p className="text-sm text-gray-600">{selectedLog.dosage_taken}</p>
                <p className="text-sm text-gray-600">um {selectedLog.scheduled_time} Uhr</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-2 block">
                  Notizen (optional)
                </label>
                <Textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="z.B. Mit Essen eingenommen..."
                  rows={3}
                />
              </div>
              <div className="flex gap-3">
                <Button
                  onClick={() => setIsDialogOpen(false)}
                  variant="outline"
                  className="flex-1"
                >
                  Abbrechen
                </Button>
                <Button
                  onClick={() => handleMarkAsTaken(selectedLog)}
                  className="flex-1 bg-green-600 hover:bg-green-700"
                >
                  Bestätigen
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}