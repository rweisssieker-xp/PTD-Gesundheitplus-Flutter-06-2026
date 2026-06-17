import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import {
  ClipboardCheck,
  Plus,
  Calendar,
  AlertCircle,
  CheckCircle,
  Loader2,
  Syringe,
  Heart,
  Baby,
  Sparkles,
  RefreshCw,
  Info,
  Bell,
  BellOff
} from "lucide-react";
import { toast } from "sonner";
import { format, isBefore, addMonths } from "date-fns";
import { de } from "date-fns/locale";
import { generateAllRecommendations } from "@/components/PreventionEngine";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

export default function VorsorgePage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [user, setUser] = useState(null);
  const [recommendations, setRecommendations] = useState(null);
  const [isLoadingRecs, setIsLoadingRecs] = useState(false);
  const [showPregnancySetup, setShowPregnancySetup] = useState(false);
  const [showReminderSettings, setShowReminderSettings] = useState(false);

  // Lade Vorsorge-Daten
  const { data: preventiveCare = [] } = useQuery({
    queryKey: ['preventive-care'],
    queryFn: () => entities.PreventiveCare.list()
  });

  const updateCareMutation = useMutation({
    mutationFn: ({ id, data }) => entities.PreventiveCare.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['preventive-care'] });
      toast.success("Erinnerung aktualisiert");
    },
    onError: (error) => {
      console.error("Error updating reminder:", error);
      toast.error("Fehler beim Aktualisieren der Erinnerung");
    }
  });

  useEffect(() => {
    loadUserAndRecommendations();
  }, []);

  const loadUserAndRecommendations = async () => {
    try {
      const userData = await base44.auth.me();
      setUser(userData);
      
      if (userData.date_of_birth) {
        await loadRecommendations(userData);
      }
    } catch (error) {
      console.error("Error loading user:", error);
    }
  };

  const loadRecommendations = async (userData = user) => {
    if (!userData) return;
    
    setIsLoadingRecs(true);
    try {
      const recs = await generateAllRecommendations(userData);
      setRecommendations(recs);
      
      // Update last check
      await base44.auth.updateMe({
        last_prevention_check: new Date().toISOString()
      });
    } catch (error) {
      console.error("Error loading recommendations:", error);
      toast.error("Fehler beim Laden der Empfehlungen");
    } finally {
      setIsLoadingRecs(false);
    }
  };

  const toggleReminder = (care, enabled) => {
    updateCareMutation.mutate({
      id: care.id,
      data: { ...care, reminder_enabled: enabled }
    });
  };

  const urgencyColors = {
    high: "border-red-300 bg-red-50",
    medium: "border-orange-300 bg-orange-50",
    low: "border-blue-300 bg-blue-50"
  };

  const urgencyBadgeColors = {
    high: "bg-red-600",
    medium: "bg-orange-600",
    low: "bg-blue-600"
  };

  // Statistiken für Erinnerungen
  const reminderStats = {
    total: preventiveCare.length,
    active: preventiveCare.filter(c => c.reminder_enabled).length,
    upcoming: preventiveCare.filter(c => {
      if (!c.next_due_date) return false;
      const daysUntil = Math.floor((new Date(c.next_due_date).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24));
      return daysUntil >= 0 && daysUntil <= 30;
    }).length
  };

  if (!user?.date_of_birth) {
    return (
      <div className="p-6 space-y-4">
        <h1 className="text-2xl font-bold text-gray-900">Vorsorge & Prävention</h1>
        <Card className="border-2 border-orange-200 bg-orange-50">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <AlertCircle className="h-5 w-5 text-orange-600 flex-shrink-0" />
              <div>
                <p className="font-semibold text-orange-900 mb-2">
                  Geburtsdatum erforderlich
                </p>
                <p className="text-sm text-orange-800">
                  Um personalisierte Vorsorgeempfehlungen zu erhalten, hinterlegen Sie bitte Ihr Geburtsdatum in den Einstellungen.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 pb-24">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <ClipboardCheck className="h-7 w-7 text-indigo-600" />
            Vorsorge & Prävention
          </h1>
          <p className="text-gray-600">Personalisierte Gesundheitsempfehlungen</p>
        </div>
        <div className="flex gap-2">
          <Button
            onClick={() => setShowReminderSettings(true)}
            variant="outline"
            size="sm"
          >
            <Bell className="h-4 w-4" />
          </Button>
          <Button
            onClick={() => loadRecommendations()}
            disabled={isLoadingRecs}
            variant="outline"
            size="sm"
          >
            {isLoadingRecs ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4" />
            )}
          </Button>
        </div>
      </div>

      {/* Reminder Stats */}
      {preventiveCare.length > 0 && (
        <div className="grid grid-cols-3 gap-3">
          <Card className="border-2 border-blue-200 bg-blue-50">
            <CardContent className="pt-4">
              <div className="text-center">
                <Bell className="h-6 w-6 mx-auto text-blue-600 mb-1" />
                <p className="text-2xl font-bold text-blue-900">{reminderStats.active}</p>
                <p className="text-xs text-blue-700">Aktive Reminder</p>
              </div>
            </CardContent>
          </Card>
          <Card className="border-2 border-orange-200 bg-orange-50">
            <CardContent className="pt-4">
              <div className="text-center">
                <Calendar className="h-6 w-6 mx-auto text-orange-600 mb-1" />
                <p className="text-2xl font-bold text-orange-900">{reminderStats.upcoming}</p>
                <p className="text-xs text-orange-700">In 30 Tagen</p>
              </div>
            </CardContent>
          </Card>
          <Card className="border-2 border-green-200 bg-green-50">
            <CardContent className="pt-4">
              <div className="text-center">
                <CheckCircle className="h-6 w-6 mx-auto text-green-600 mb-1" />
                <p className="text-2xl font-bold text-green-900">{reminderStats.total}</p>
                <p className="text-xs text-green-700">Gesamt</p>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Reminder Settings Dialog */}
      <Dialog open={showReminderSettings} onOpenChange={setShowReminderSettings}>
        <DialogContent className="max-w-md max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Bell className="h-5 w-5 text-blue-600" />
              Erinnerungseinstellungen
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            {preventiveCare.length === 0 ? (
              <p className="text-center text-gray-500 py-8">
                Noch keine Vorsorgeuntersuchungen eingetragen
              </p>
            ) : (
              preventiveCare.map((care) => (
                <Card key={care.id} className="border-2">
                  <CardContent className="pt-4">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex-1">
                        <p className="font-semibold text-gray-900">{care.examination_type}</p>
                        {care.next_due_date && (
                          <p className="text-sm text-gray-600 mt-1">
                            Fällig: {new Date(care.next_due_date).toLocaleDateString('de-DE')}
                          </p>
                        )}
                        {care.frequency && (
                          <p className="text-xs text-gray-500">
                            Häufigkeit: {care.frequency}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        {care.reminder_enabled ? (
                          <Bell className="h-4 w-4 text-blue-600" />
                        ) : (
                          <BellOff className="h-4 w-4 text-gray-400" />
                        )}
                        <Switch
                          checked={care.reminder_enabled}
                          onCheckedChange={(checked) => toggleReminder(care, checked)}
                          disabled={updateCareMutation.isPending}
                        />
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
            <Card className="border-2 border-blue-200 bg-blue-50">
              <CardContent className="pt-4">
                <div className="flex gap-2">
                  <Info className="h-4 w-4 text-blue-600 flex-shrink-0 mt-0.5" />
                  <div className="text-xs text-blue-800">
                    <p className="font-semibold mb-1">Erinnerungen werden gesendet:</p>
                    <ul className="list-disc list-inside space-y-0.5">
                      <li>30 Tage vor Fälligkeit</li>
                      <li>14 Tage vor Fälligkeit</li>
                      <li>7 Tage vor Fälligkeit</li>
                      <li>3 Tage vor Fälligkeit</li>
                      <li>1 Tag vor Fälligkeit</li>
                    </ul>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </DialogContent>
      </Dialog>

      {/* AI Info Card */}
      <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-pink-50">
        <CardContent className="pt-6">
          <div className="flex gap-3">
            <Sparkles className="h-5 w-5 text-purple-600 flex-shrink-0 mt-0.5" />
            <div className="space-y-2 text-sm text-purple-900">
              <p className="font-semibold">KI-gestützte Präventionsempfehlungen</p>
              <ul className="space-y-1 ml-4 list-disc">
                <li>Basierend auf STIKO & medizinischen Leitlinien</li>
                <li>Personalisiert nach Alter, Geschlecht & Risikogruppen</li>
                <li>Automatische Erinnerungen vor Fälligkeit</li>
                <li>Schwangerschaftsbegleitung mit wöchentlichen Terminen</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Pregnancy Setup */}
      {user.gender === "Weiblich" && !user.is_pregnant && (
        <Card className="border-2 border-pink-200 bg-pink-50">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="flex gap-3">
                <Baby className="h-5 w-5 text-pink-600 flex-shrink-0" />
                <div>
                  <p className="font-semibold text-pink-900">Schwangerschaft</p>
                  <p className="text-sm text-pink-800">
                    Erwarten Sie ein Baby? Aktivieren Sie spezielle Vorsorgeempfehlungen.
                  </p>
                </div>
              </div>
              <Dialog open={showPregnancySetup} onOpenChange={setShowPregnancySetup}>
                <DialogTrigger asChild>
                  <Button size="sm" className="bg-pink-600 hover:bg-pink-700">
                    Aktivieren
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Schwangerschaft aktivieren</DialogTitle>
                  </DialogHeader>
                  <PregnancySetupForm 
                    onComplete={async (data) => {
                      await base44.auth.updateMe(data);
                      setShowPregnancySetup(false);
                      await loadUserAndRecommendations();
                      toast.success("Schwangerschaftsmodus aktiviert!");
                    }}
                  />
                </DialogContent>
              </Dialog>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Statistics */}
      {recommendations && (
        <div className="grid grid-cols-3 gap-3">
          <Card className="border-2">
            <CardContent className="pt-6">
              <div className="text-center">
                <Syringe className="h-8 w-8 mx-auto text-purple-600 mb-2" />
                <p className="text-2xl font-bold text-gray-900">
                  {recommendations.vaccinations.length}
                </p>
                <p className="text-sm text-gray-600">Impfungen</p>
              </div>
            </CardContent>
          </Card>

          <Card className="border-2">
            <CardContent className="pt-6">
              <div className="text-center">
                <Heart className="h-8 w-8 mx-auto text-red-600 mb-2" />
                <p className="text-2xl font-bold text-gray-900">
                  {recommendations.screenings.length}
                </p>
                <p className="text-sm text-gray-600">Vorsorge</p>
              </div>
            </CardContent>
          </Card>

          {user.is_pregnant && (
            <Card className="border-2">
              <CardContent className="pt-6">
                <div className="text-center">
                  <Baby className="h-8 w-8 mx-auto text-pink-600 mb-2" />
                  <p className="text-2xl font-bold text-gray-900">
                    {recommendations.pregnancy.length}
                  </p>
                  <p className="text-sm text-gray-600">SS-Termine</p>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {isLoadingRecs ? (
        <div className="text-center py-12">
          <Loader2 className="h-12 w-12 animate-spin text-indigo-600 mx-auto mb-4" />
          <p className="text-gray-600">Lade personalisierte Empfehlungen...</p>
        </div>
      ) : recommendations ? (
        <>
          {/* Vaccination Recommendations */}
          {recommendations.vaccinations.length > 0 && (
            <div className="space-y-3">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                <Syringe className="h-5 w-5 text-purple-600" />
                Impfempfehlungen ({recommendations.vaccinations.length})
              </h2>

              {recommendations.vaccinations.map((vacc, idx) => (
                <Card key={idx} className={`border-2 ${urgencyColors[vacc.urgency]}`}>
                  <CardContent className="pt-6">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="font-semibold text-gray-900">{vacc.vaccine}</h3>
                          <Badge className={urgencyBadgeColors[vacc.urgency]}>
                            {vacc.urgency === 'high' ? 'Dringend' : vacc.urgency === 'medium' ? 'Empfohlen' : 'Optional'}
                          </Badge>
                          {vacc.seasonal && (
                            <Badge variant="outline">Saisonal</Badge>
                          )}
                        </div>
                        <p className="text-sm text-gray-700 mb-1">{vacc.description}</p>
                        <p className="text-sm text-gray-600">{vacc.reason}</p>
                        {vacc.bestTime && (
                          <p className="text-xs text-gray-500 mt-1">
                            ⏰ Beste Zeit: {vacc.bestTime}
                          </p>
                        )}
                        {vacc.requiresDoses && (
                          <p className="text-xs text-gray-500 mt-1">
                            💉 Benötigt {vacc.requiresDoses} Dosen
                          </p>
                        )}
                        {vacc.note && (
                          <p className="text-xs text-blue-600 mt-2">
                            ℹ️ {vacc.note}
                          </p>
                        )}
                      </div>
                      <Button
                        onClick={() => {
                          window.location.href = "/Impfpass";
                        }}
                        size="sm"
                        className="bg-purple-600 hover:bg-purple-700"
                      >
                        Zum Impfpass
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Screening Recommendations */}
          {recommendations.screenings.length > 0 && (
            <div className="space-y-3">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                <Heart className="h-5 w-5 text-red-600" />
                Vorsorgeuntersuchungen ({recommendations.screenings.length})
              </h2>

              {recommendations.screenings.map((screening, idx) => (
                <Card key={idx} className={`border-2 ${urgencyColors[screening.urgency]}`}>
                  <CardContent className="pt-6">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="font-semibold text-gray-900">{screening.name}</h3>
                          <Badge className={urgencyBadgeColors[screening.urgency]}>
                            {screening.urgency === 'high' ? 'Wichtig' : 'Empfohlen'}
                          </Badge>
                        </div>
                        <p className="text-sm text-gray-700 mb-1">{screening.reason}</p>
                        <p className="text-sm text-gray-600">
                          📅 Häufigkeit: {screening.frequency}
                        </p>
                        {screening.specialty && (
                          <p className="text-xs text-gray-500 mt-1">
                            👨‍⚕️ Fachrichtung: {screening.specialty}
                          </p>
                        )}
                        {screening.includes && (
                          <p className="text-xs text-gray-500 mt-1">
                            Inkludiert: {screening.includes.join(', ')}
                          </p>
                        )}
                      </div>
                      <Button
                        onClick={() => {
                          window.location.href = "/Termine";
                        }}
                        size="sm"
                        className="bg-red-600 hover:bg-red-700"
                      >
                        Termin planen
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Pregnancy Recommendations */}
          {user.is_pregnant && recommendations.pregnancy.length > 0 && (
            <div className="space-y-3">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                <Baby className="h-5 w-5 text-pink-600" />
                Schwangerschaftsvorsorge (Woche {user.pregnancy_week || '?'})
              </h2>

              {recommendations.pregnancy.map((rec, idx) => (
                <Card key={idx} className={`border-2 ${urgencyColors[rec.urgency]}`}>
                  <CardContent className="pt-6">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="font-semibold text-gray-900">{rec.name}</h3>
                          <Badge className={urgencyBadgeColors[rec.urgency]}>
                            {rec.urgency === 'high' ? 'Dringend' : 'Empfohlen'}
                          </Badge>
                          {rec.week && (
                            <Badge variant="outline">SSW {rec.week}</Badge>
                          )}
                        </div>
                        <p className="text-sm text-gray-700">{rec.reason}</p>
                        {rec.note && (
                          <p className="text-xs text-pink-600 mt-2">
                            💡 {rec.note}
                          </p>
                        )}
                        {rec.trimester && (
                          <p className="text-xs text-gray-500 mt-1">
                            {rec.trimester}
                          </p>
                        )}
                      </div>
                      <Button
                        onClick={() => {
                          window.location.href = rec.type === 'vaccination' ? "/Impfpass" : "/Termine";
                        }}
                        size="sm"
                        className="bg-pink-600 hover:bg-pink-700"
                      >
                        {rec.type === 'vaccination' ? 'Impfung' : 'Termin'}
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {recommendations.total === 0 && (
            <Card className="border-2 border-green-200 bg-green-50">
              <CardContent className="pt-6 text-center">
                <CheckCircle className="h-12 w-12 text-green-600 mx-auto mb-4" />
                <p className="font-semibold text-green-900 mb-2">
                  Alles auf dem neuesten Stand!
                </p>
                <p className="text-sm text-green-800">
                  Sie haben derzeit alle empfohlenen Vorsorgeuntersuchungen und Impfungen absolviert.
                </p>
              </CardContent>
            </Card>
          )}
        </>
      ) : null}

      {/* Info Footer */}
      <Card className="border-2 border-blue-200 bg-blue-50">
        <CardContent className="pt-6">
          <div className="flex gap-3">
            <Info className="h-5 w-5 text-blue-600 flex-shrink-0" />
            <div className="text-sm text-blue-900">
              <p className="font-semibold mb-1">Hinweis</p>
              <p>
                Die Empfehlungen basieren auf den aktuellen Leitlinien der STIKO und medizinischen Fachgesellschaften. 
                Sie ersetzen nicht die persönliche Beratung durch Ihren Arzt. Bei Fragen wenden Sie sich bitte an Ihr medizinisches Fachpersonal.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Pregnancy Setup Form Component
function PregnancySetupForm({ onComplete }) {
  const [dueDate, setDueDate] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!dueDate) {
      toast.error("Bitte Entbindungstermin eingeben");
      return;
    }

    const dueDateObj = new Date(dueDate);
    // Assuming 40 weeks for a full-term pregnancy from LMP, which is roughly 9 months from conception
    // To calculate conception date from due date, subtract 9 months.
    // However, for SSW calculation, it's typically weeks from last menstrual period (LMP) or estimated conception.
    // If dueDate is known, SSW can be calculated by subtracting current date from dueDate and converting to weeks from 40 weeks.
    const today = new Date();
    const millisecondsInWeek = 1000 * 60 * 60 * 24 * 7;
    const totalWeeksPregnancy = 40; // Approx weeks for full term

    const diffInMilliseconds = dueDateObj.getTime() - today.getTime();
    const remainingWeeks = Math.round(diffInMilliseconds / millisecondsInWeek);
    const currentWeek = totalWeeksPregnancy - remainingWeeks;

    onComplete({
      is_pregnant: true,
      pregnancy_due_date: dueDate,
      pregnancy_week: currentWeek > 0 ? currentWeek : 1 // Ensure at least week 1 if due date is in the past or very near
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 p-4">
      <div>
        <label className="block text-sm font-semibold text-gray-900 mb-2">
          Voraussichtlicher Entbindungstermin
        </label>
        <input
          type="date"
          value={dueDate}
          onChange={(e) => setDueDate(e.target.value)}
          min={new Date().toISOString().split('T')[0]}
          max={addMonths(new Date(), 10).toISOString().split('T')[0]} // Allow up to 10 months from now
          className="w-full px-3 py-2 border-2 rounded-lg"
        />
      </div>
      <Button type="submit" className="w-full bg-pink-600 hover:bg-pink-700">
        Schwangerschaft aktivieren
      </Button>
    </form>
  );
}