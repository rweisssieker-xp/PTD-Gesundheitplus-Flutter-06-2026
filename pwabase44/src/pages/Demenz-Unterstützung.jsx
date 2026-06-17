import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import {
  Heart,
  Droplets,
  UtensilsCrossed,
  Plus,
  CheckCircle,
  Clock,
  Settings,
  TrendingUp,
  Info,
  Users,
  Bell,
  AlertCircle
} from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { toast } from "sonner";
import { format, startOfDay, endOfDay } from "date-fns";
import { de } from "date-fns/locale";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

export default function DemenzUnterstützungPage() {
  const queryClient = useQueryClient();
  const [user, setUser] = useState(null);
  const [showSettings, setShowSettings] = useState(false);
  const [showHydrationLog, setShowHydrationLog] = useState(false);
  const [showMealLog, setShowMealLog] = useState(false);

  const [hydrationForm, setHydrationForm] = useState({
    amount_ml: 250,
    beverage_type: "Wasser"
  });

  const [mealForm, setMealForm] = useState({
    meal_type: "Frühstück",
    portion_size: "Normal"
  });

  const [settings, setSettings] = useState({
    dementia_support_enabled: false,
    hydration_reminders_enabled: false,
    hydration_interval_minutes: 120,
    hydration_start_time: "08:00",
    hydration_end_time: "20:00",
    meal_reminders_enabled: false,
    meal_times: ["08:00", "13:00", "19:00"]
  });

  useEffect(() => {
    loadUser();
  }, []);

  const loadUser = async () => {
    try {
      const userData = await base44.auth.me();
      setUser(userData);
      setSettings({
        dementia_support_enabled: userData.dementia_support_enabled || false,
        hydration_reminders_enabled: userData.hydration_reminders_enabled || false,
        hydration_interval_minutes: userData.hydration_interval_minutes || 120,
        hydration_start_time: userData.hydration_start_time || "08:00",
        hydration_end_time: userData.hydration_end_time || "20:00",
        meal_reminders_enabled: userData.meal_reminders_enabled || false,
        meal_times: userData.meal_times || ["08:00", "13:00", "19:00"]
      });
    } catch (error) {
      console.error("Error loading user:", error);
    }
  };

  // Fetch today's hydration logs
  const { data: hydrationLogs = [] } = useQuery({
    queryKey: ['hydration-logs', new Date().toDateString()],
    queryFn: async () => {
      const logs = await base44.entities.HydrationLog.list();
      // Filter for today
      const today = new Date().toDateString();
      return logs.filter(log => new Date(log.timestamp).toDateString() === today);
    },
  });

  // Fetch today's meal logs
  const { data: mealLogs = [] } = useQuery({
    queryKey: ['meal-logs', new Date().toDateString()],
    queryFn: async () => {
      const logs = await base44.entities.MealLog.list();
      const today = new Date().toDateString();
      return logs.filter(log => new Date(log.timestamp).toDateString() === today);
    },
  });

  const saveSettingsMutation = useMutation({
    mutationFn: (data) => base44.auth.updateMe(data),
    onSuccess: () => {
      toast.success("Einstellungen gespeichert");
      setShowSettings(false);
      loadUser();
    },
  });

  const logHydrationMutation = useMutation({
    mutationFn: (data) => base44.entities.HydrationLog.create({
      ...data,
      timestamp: new Date().toISOString()
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['hydration-logs'] });
      toast.success("Trinken protokolliert! 💧");
      setShowHydrationLog(false);
    },
  });

  const logMealMutation = useMutation({
    mutationFn: (data) => base44.entities.MealLog.create({
      ...data,
      timestamp: new Date().toISOString()
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['meal-logs'] });
      toast.success("Mahlzeit protokolliert! 🍽️");
      setShowMealLog(false);
    },
  });

  const handleSaveSettings = () => {
    saveSettingsMutation.mutate(settings);
  };

  const handleQuickHydration = () => {
    logHydrationMutation.mutate({
      amount_ml: 250,
      beverage_type: "Wasser"
    });
  };

  // Calculate statistics
  const totalHydrationToday = hydrationLogs.reduce((sum, log) => sum + (log.amount_ml || 0), 0);
  const hydrationGoal = 2000; // 2 liters
  const hydrationPercentage = Math.min((totalHydrationToday / hydrationGoal) * 100, 100);

  const mealsToday = mealLogs.length;
  const mealsGoal = 3;

  return (
    <div className="p-6 space-y-6 pb-24">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Heart className="h-7 w-7 text-pink-600" />
            Demenz-Unterstützung
          </h1>
          <p className="text-gray-600">Erinnerungen & Protokolle</p>
        </div>
        <Dialog open={showSettings} onOpenChange={setShowSettings}>
          <DialogTrigger asChild>
            <Button variant="outline" size="icon">
              <Settings className="h-5 w-5" />
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>Einstellungen</DialogTitle>
            </DialogHeader>
            <div className="space-y-6 py-4">
              {/* Main Toggle */}
              <div className="flex items-center justify-between p-4 bg-pink-50 rounded-lg border-2 border-pink-200">
                <div className="flex-1">
                  <Label className="font-semibold text-gray-900">Demenz-Unterstützung</Label>
                  <p className="text-xs text-gray-600 mt-1">Aktiviert Erinnerungen für Trinken und Essen</p>
                </div>
                <Switch
                  checked={settings.dementia_support_enabled}
                  onCheckedChange={(checked) => setSettings({...settings, dementia_support_enabled: checked})}
                />
              </div>

              {settings.dementia_support_enabled && (
                <>
                  {/* Hydration Settings */}
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <Label className="font-semibold">💧 Trinkerinnerungen</Label>
                      <Switch
                        checked={settings.hydration_reminders_enabled}
                        onCheckedChange={(checked) => setSettings({...settings, hydration_reminders_enabled: checked})}
                      />
                    </div>

                    {settings.hydration_reminders_enabled && (
                      <>
                        <div>
                          <Label>Erinnerung alle (Minuten)</Label>
                          <Select
                            value={settings.hydration_interval_minutes.toString()}
                            onValueChange={(value) => setSettings({...settings, hydration_interval_minutes: parseInt(value)})}
                          >
                            <SelectTrigger className="mt-1">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="60">60 Min (jede Stunde)</SelectItem>
                              <SelectItem value="90">90 Min (1,5 Stunden)</SelectItem>
                              <SelectItem value="120">120 Min (2 Stunden)</SelectItem>
                              <SelectItem value="180">180 Min (3 Stunden)</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>

                        <div className="grid grid-cols-2 gap-3">
                          <div>
                            <Label>Start</Label>
                            <Input
                              type="time"
                              value={settings.hydration_start_time}
                              onChange={(e) => setSettings({...settings, hydration_start_time: e.target.value})}
                              className="mt-1"
                            />
                          </div>
                          <div>
                            <Label>Ende</Label>
                            <Input
                              type="time"
                              value={settings.hydration_end_time}
                              onChange={(e) => setSettings({...settings, hydration_end_time: e.target.value})}
                              className="mt-1"
                            />
                          </div>
                        </div>
                      </>
                    )}
                  </div>

                  {/* Meal Settings */}
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <Label className="font-semibold">🍽️ Essenserinnerungen</Label>
                      <Switch
                        checked={settings.meal_reminders_enabled}
                        onCheckedChange={(checked) => setSettings({...settings, meal_reminders_enabled: checked})}
                      />
                    </div>

                    {settings.meal_reminders_enabled && (
                      <div className="space-y-3">
                        <Label>Essenszeiten</Label>
                        {settings.meal_times.map((time, idx) => (
                          <div key={idx} className="flex items-center gap-2">
                            <Input
                              type="time"
                              value={time}
                              onChange={(e) => {
                                const newTimes = [...settings.meal_times];
                                newTimes[idx] = e.target.value;
                                setSettings({...settings, meal_times: newTimes});
                              }}
                            />
                            <span className="text-sm text-gray-600">
                              {idx === 0 ? "Frühstück" : idx === 1 ? "Mittagessen" : "Abendessen"}
                            </span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </>
              )}

              <Button onClick={handleSaveSettings} className="w-full bg-pink-600 hover:bg-pink-700">
                Einstellungen speichern
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Setup Info */}
      {!user?.dementia_support_enabled && (
        <Card className="border-2 border-blue-200 bg-blue-50">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <Info className="h-5 w-5 text-blue-600 flex-shrink-0" />
              <div>
                <p className="font-semibold text-blue-900 mb-2">
                  Demenz-Unterstützung aktivieren
                </p>
                <p className="text-sm text-blue-800 mb-4">
                  Diese Funktion hilft bei beginnender Demenz durch regelmäßige Erinnerungen an Trinken und Essen.
                  Ideal für häusliche Pflege mit Unterstützung durch Familie und ambulante Pflegekräfte.
                </p>
                <Button
                  onClick={() => setShowSettings(true)}
                  className="bg-blue-600 hover:bg-blue-700"
                >
                  Jetzt einrichten
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {user?.dementia_support_enabled && (
        <>
          {/* Status Cards */}
          <div className="grid grid-cols-2 gap-4">
            <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-cyan-50">
              <CardContent className="pt-6">
                <div className="text-center">
                  <Droplets className="h-10 w-10 mx-auto text-blue-600 mb-2" />
                  <p className="text-3xl font-bold text-gray-900">{totalHydrationToday}</p>
                  <p className="text-sm text-gray-600">ml getrunken</p>
                  <div className="mt-3 w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-blue-600 h-2 rounded-full transition-all"
                      style={{ width: `${hydrationPercentage}%` }}
                    ></div>
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    Ziel: {hydrationGoal} ml
                  </p>
                </div>
              </CardContent>
            </Card>

            <Card className="border-2 border-orange-200 bg-gradient-to-br from-orange-50 to-yellow-50">
              <CardContent className="pt-6">
                <div className="text-center">
                  <UtensilsCrossed className="h-10 w-10 mx-auto text-orange-600 mb-2" />
                  <p className="text-3xl font-bold text-gray-900">{mealsToday}</p>
                  <p className="text-sm text-gray-600">Mahlzeiten</p>
                  <div className="mt-3 flex justify-center gap-2">
                    {[...Array(mealsGoal)].map((_, i) => (
                      <div
                        key={i}
                        className={`h-8 w-8 rounded-full flex items-center justify-center ${
                          i < mealsToday ? 'bg-orange-600 text-white' : 'bg-gray-200 text-gray-400'
                        }`}
                      >
                        {i < mealsToday ? <CheckCircle className="h-5 w-5" /> : <Clock className="h-5 w-5" />}
                      </div>
                    ))}
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Quick Actions */}
          <div className="grid grid-cols-2 gap-3">
            <Button
              onClick={handleQuickHydration}
              className="h-20 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700"
            >
              <div className="flex flex-col items-center gap-2">
                <Droplets className="h-6 w-6" />
                <span className="text-sm font-semibold">Getrunken (250ml)</span>
              </div>
            </Button>

            <Dialog open={showHydrationLog} onOpenChange={setShowHydrationLog}>
              <DialogTrigger asChild>
                <Button variant="outline" className="h-20 border-2">
                  <div className="flex flex-col items-center gap-2">
                    <Plus className="h-6 w-6" />
                    <span className="text-sm font-semibold">Trinken detailliert</span>
                  </div>
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Trinken protokollieren</DialogTitle>
                </DialogHeader>
                <div className="space-y-4 py-4">
                  <div>
                    <Label>Getränk</Label>
                    <Select
                      value={hydrationForm.beverage_type}
                      onValueChange={(value) => setHydrationForm({...hydrationForm, beverage_type: value})}
                    >
                      <SelectTrigger className="mt-1">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Wasser">Wasser</SelectItem>
                        <SelectItem value="Tee">Tee</SelectItem>
                        <SelectItem value="Kaffee">Kaffee</SelectItem>
                        <SelectItem value="Saft">Saft</SelectItem>
                        <SelectItem value="Milch">Milch</SelectItem>
                        <SelectItem value="Suppe">Suppe</SelectItem>
                        <SelectItem value="Sonstiges">Sonstiges</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label>Menge (ml)</Label>
                    <Select
                      value={hydrationForm.amount_ml.toString()}
                      onValueChange={(value) => setHydrationForm({...hydrationForm, amount_ml: parseInt(value)})}
                    >
                      <SelectTrigger className="mt-1">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="100">100 ml (klein)</SelectItem>
                        <SelectItem value="200">200 ml (mittel)</SelectItem>
                        <SelectItem value="250">250 ml (Glas)</SelectItem>
                        <SelectItem value="300">300 ml (Tasse)</SelectItem>
                        <SelectItem value="500">500 ml (groß)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <Button
                    onClick={() => logHydrationMutation.mutate(hydrationForm)}
                    className="w-full bg-blue-600 hover:bg-blue-700"
                  >
                    Protokollieren
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Dialog open={showMealLog} onOpenChange={setShowMealLog}>
              <DialogTrigger asChild>
                <Button className="h-20 bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700">
                  <div className="flex flex-col items-center gap-2">
                    <UtensilsCrossed className="h-6 w-6" />
                    <span className="text-sm font-semibold">Mahlzeit gegessen</span>
                  </div>
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Mahlzeit protokollieren</DialogTitle>
                </DialogHeader>
                <div className="space-y-4 py-4">
                  <div>
                    <Label>Mahlzeit</Label>
                    <Select
                      value={mealForm.meal_type}
                      onValueChange={(value) => setMealForm({...mealForm, meal_type: value})}
                    >
                      <SelectTrigger className="mt-1">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Frühstück">Frühstück</SelectItem>
                        <SelectItem value="Mittagessen">Mittagessen</SelectItem>
                        <SelectItem value="Abendessen">Abendessen</SelectItem>
                        <SelectItem value="Snack">Snack</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label>Portionsgröße</Label>
                    <Select
                      value={mealForm.portion_size}
                      onValueChange={(value) => setMealForm({...mealForm, portion_size: value})}
                    >
                      <SelectTrigger className="mt-1">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Keine">Keine - nichts gegessen</SelectItem>
                        <SelectItem value="Klein">Klein - wenig gegessen</SelectItem>
                        <SelectItem value="Normal">Normal - ausreichend</SelectItem>
                        <SelectItem value="Groß">Groß - viel gegessen</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <Button
                    onClick={() => logMealMutation.mutate(mealForm)}
                    className="w-full bg-orange-600 hover:bg-orange-700"
                  >
                    Protokollieren
                  </Button>
                </div>
              </DialogContent>
            </Dialog>

            <Button
              onClick={() => window.location.href = "/Demenz-Statistiken"}
              variant="outline"
              className="h-20 border-2"
            >
              <div className="flex flex-col items-center gap-2">
                <TrendingUp className="h-6 w-6" />
                <span className="text-sm font-semibold">Statistiken</span>
              </div>
            </Button>
          </div>

          {/* Today's Logs */}
          <Card className="border-2">
            <CardHeader>
              <CardTitle className="text-lg">Heute protokolliert</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Hydration Logs */}
              {hydrationLogs.length > 0 && (
                <div>
                  <p className="text-sm font-semibold text-gray-900 mb-2">💧 Getrunken:</p>
                  <div className="space-y-2">
                    {hydrationLogs.slice(-5).reverse().map((log, idx) => (
                      <div key={idx} className="flex items-center justify-between p-2 bg-blue-50 rounded-lg border border-blue-200">
                        <div className="flex items-center gap-2">
                          <Droplets className="h-4 w-4 text-blue-600" />
                          <span className="text-sm text-gray-900">{log.beverage_type}</span>
                        </div>
                        <div className="flex items-center gap-3">
                          <Badge variant="outline">{log.amount_ml} ml</Badge>
                          <span className="text-xs text-gray-500">
                            {format(new Date(log.timestamp), 'HH:mm', { locale: de })}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Meal Logs */}
              {mealLogs.length > 0 && (
                <div>
                  <p className="text-sm font-semibold text-gray-900 mb-2">🍽️ Gegessen:</p>
                  <div className="space-y-2">
                    {mealLogs.slice(-5).reverse().map((log, idx) => (
                      <div key={idx} className="flex items-center justify-between p-2 bg-orange-50 rounded-lg border border-orange-200">
                        <div className="flex items-center gap-2">
                          <UtensilsCrossed className="h-4 w-4 text-orange-600" />
                          <span className="text-sm text-gray-900">{log.meal_type}</span>
                        </div>
                        <div className="flex items-center gap-3">
                          <Badge variant="outline">{log.portion_size}</Badge>
                          <span className="text-xs text-gray-500">
                            {format(new Date(log.timestamp), 'HH:mm', { locale: de })}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {hydrationLogs.length === 0 && mealLogs.length === 0 && (
                <p className="text-center text-gray-500 py-4">
                  Noch keine Einträge heute
                </p>
              )}
            </CardContent>
          </Card>

          {/* Info Box */}
          <Card className="border-2 border-green-200 bg-green-50">
            <CardContent className="pt-6">
              <div className="flex gap-3">
                <Users className="h-5 w-5 text-green-600 flex-shrink-0" />
                <div className="text-sm text-green-900">
                  <p className="font-semibold mb-2">Für Betreuer & Familie</p>
                  <ul className="space-y-1 text-xs">
                    <li>✓ Regelmäßige Erinnerungen helfen bei der Routine</li>
                    <li>✓ Protokolle zeigen das Trink- und Essverhalten</li>
                    <li>✓ Kann Krankenhauseinweisungen durch Dehydration vorbeugen</li>
                    <li>✓ Unterstützt häusliche Pflege mit ambulanten Diensten</li>
                  </ul>
                </div>
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}