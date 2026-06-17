import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Activity, Heart, Clock, Plus, Trash2, AlertCircle, TrendingUp, TrendingDown, Minus } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine, ReferenceArea, Legend } from 'recharts';
import { format, subDays, subWeeks } from "date-fns";
import { de } from "date-fns/locale";

const RANGE_OPTIONS = [
  { label: "7 Tage", days: 7 },
  { label: "14 Tage", days: 14 },
  { label: "30 Tage", days: 30 },
  { label: "Alle", days: null },
];

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-white rounded-xl shadow-xl border border-gray-100 p-3 text-xs">
      <p className="font-semibold text-gray-700 mb-2">
        {format(new Date(label), "dd.MM.yyyy HH:mm", { locale: de })}
      </p>
      {payload.map((p) => (
        <div key={p.name} className="flex items-center gap-2 mb-1">
          <span className="w-2 h-2 rounded-full inline-block" style={{ background: p.color }} />
          <span className="text-gray-600">{p.name}:</span>
          <span className="font-bold" style={{ color: p.color }}>{p.value} {p.name === "Puls" ? "bpm" : "mmHg"}</span>
        </div>
      ))}
    </div>
  );
};

export default function BloodPressurePage() {
  const entities = useEntities();
  const [showForm, setShowForm] = useState(false);
  const [range, setRange] = useState(14);
  const [newEntry, setNewEntry] = useState({
    systolic: "",
    diastolic: "",
    pulse: "",
    context: "Ruhe",
    measured_at: format(new Date(), "yyyy-MM-dd'T'HH:mm")
  });

  const queryClient = useQueryClient();

  // Load logs
  const { data: logs = [], isLoading } = useQuery({
    queryKey: ['blood-pressure'],
    queryFn: async () => {
      const data = await entities.BloodPressureLog.list('-measured_at', 50);
      return data.sort((a, b) => new Date(a.measured_at) - new Date(b.measured_at));
    }
  });

  // Create mutation
  const createMutation = useMutation({
    mutationFn: (data) => entities.BloodPressureLog.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries(['blood-pressure']);
      setShowForm(false);
      setNewEntry({
        systolic: "",
        diastolic: "",
        pulse: "",
        context: "Ruhe",
        measured_at: format(new Date(), "yyyy-MM-dd'T'HH:mm")
      });
    }
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: (id) => entities.BloodPressureLog.delete(id),
    onSuccess: () => queryClient.invalidateQueries(['blood-pressure'])
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    createMutation.mutate({
      ...newEntry,
      systolic: Number(newEntry.systolic),
      diastolic: Number(newEntry.diastolic),
      pulse: newEntry.pulse ? Number(newEntry.pulse) : undefined,
      measured_at: new Date(newEntry.measured_at).toISOString()
    });
  };

  const getStatusColor = (sys, dia) => {
    if (sys > 140 || dia > 90) return "text-red-600";
    if (sys > 130 || dia > 85) return "text-yellow-600";
    if (sys < 100 || dia < 60) return "text-blue-600";
    return "text-green-600";
  };

  const latest = logs.length > 0 ? logs[logs.length - 1] : null;

  const filteredLogs = range
    ? logs.filter(l => new Date(l.measured_at) >= subDays(new Date(), range))
    : logs;

  const avgSys = filteredLogs.length
    ? Math.round(filteredLogs.reduce((s, l) => s + l.systolic, 0) / filteredLogs.length)
    : null;
  const avgDia = filteredLogs.length
    ? Math.round(filteredLogs.reduce((s, l) => s + l.diastolic, 0) / filteredLogs.length)
    : null;
  const maxSys = filteredLogs.length ? Math.max(...filteredLogs.map(l => l.systolic)) : null;
  const minSys = filteredLogs.length ? Math.min(...filteredLogs.map(l => l.systolic)) : null;

  const getTrend = () => {
    if (filteredLogs.length < 3) return null;
    const half = Math.floor(filteredLogs.length / 2);
    const firstHalf = filteredLogs.slice(0, half);
    const secondHalf = filteredLogs.slice(-half);
    const avgFirst = firstHalf.reduce((s, l) => s + l.systolic, 0) / firstHalf.length;
    const avgSecond = secondHalf.reduce((s, l) => s + l.systolic, 0) / secondHalf.length;
    const diff = avgSecond - avgFirst;
    if (diff > 3) return "up";
    if (diff < -3) return "down";
    return "stable";
  };
  const trend = getTrend();

  return (
    <div className="min-h-screen bg-gray-50 p-4 pb-20">
      <div className="max-w-md mx-auto space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <Activity className="h-6 w-6 text-red-600" />
            Blutdruck
          </h1>
          <Button onClick={() => setShowForm(!showForm)} size="sm" className="bg-red-600 hover:bg-red-700">
            <Plus className="h-4 w-4 mr-1" /> Messung
          </Button>
        </div>

        {/* Latest Reading Card */}
        {latest && (
          <Card className="border-l-4 border-l-red-600 shadow-md">
            <CardContent className="pt-6">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-sm text-gray-500 mb-1">Letzte Messung</p>
                  <div className="flex items-baseline gap-2">
                    <span className={`text-4xl font-bold ${getStatusColor(latest.systolic, latest.diastolic)}`}>
                      {latest.systolic}/{latest.diastolic}
                    </span>
                    <span className="text-gray-500">mmHg</span>
                  </div>
                  <p className="text-sm text-gray-500 mt-2 flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    {format(new Date(latest.measured_at), "dd.MM.yyyy HH:mm", { locale: de })}
                  </p>
                </div>
                {latest.pulse && (
                  <div className="text-right">
                    <div className="flex items-center justify-end gap-1 text-red-500 mb-1">
                      <Heart className="h-4 w-4 fill-current" />
                      <span className="text-sm font-medium">Puls</span>
                    </div>
                    <span className="text-2xl font-bold text-gray-800">{latest.pulse}</span>
                    <span className="text-xs text-gray-500 block">bpm</span>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Input Form */}
        {showForm && (
          <Card className="animate-in slide-in-from-top-4">
            <CardHeader>
              <CardTitle>Neue Messung</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Systole (mmHg)</Label>
                    <Input 
                      type="number" 
                      placeholder="120"
                      required
                      value={newEntry.systolic}
                      onChange={e => setNewEntry({...newEntry, systolic: e.target.value})}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Diastole (mmHg)</Label>
                    <Input 
                      type="number" 
                      placeholder="80"
                      required
                      value={newEntry.diastolic}
                      onChange={e => setNewEntry({...newEntry, diastolic: e.target.value})}
                    />
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Puls (bpm)</Label>
                    <Input 
                      type="number" 
                      placeholder="70"
                      value={newEntry.pulse}
                      onChange={e => setNewEntry({...newEntry, pulse: e.target.value})}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Zeitpunkt</Label>
                    <Input 
                      type="datetime-local" 
                      required
                      value={newEntry.measured_at}
                      onChange={e => setNewEntry({...newEntry, measured_at: e.target.value})}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Kontext</Label>
                  <Select 
                    value={newEntry.context} 
                    onValueChange={v => setNewEntry({...newEntry, context: v})}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Ruhe">Ruhe</SelectItem>
                      <SelectItem value="Morgens">Morgens</SelectItem>
                      <SelectItem value="Abends">Abends</SelectItem>
                      <SelectItem value="Nach Belastung">Nach Belastung</SelectItem>
                      <SelectItem value="Unwohlsein">Bei Unwohlsein</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <Button type="submit" className="w-full bg-red-600 hover:bg-red-700">Speichern</Button>
              </form>
            </CardContent>
          </Card>
        )}

        {/* Tabs for Chart/History */}
        <Tabs defaultValue="chart">
          <TabsList className="w-full grid grid-cols-2">
            <TabsTrigger value="chart">Verlauf</TabsTrigger>
            <TabsTrigger value="history">Historie</TabsTrigger>
          </TabsList>
          
          <TabsContent value="chart" className="space-y-3">
            {/* Zeitraum-Auswahl */}
            <div className="flex gap-2">
              {RANGE_OPTIONS.map(opt => (
                <button
                  key={opt.label}
                  onClick={() => setRange(opt.days)}
                  className={`flex-1 py-1.5 text-xs font-semibold rounded-lg border transition-all ${
                    range === opt.days
                      ? "bg-red-600 text-white border-red-600"
                      : "bg-white text-gray-600 border-gray-200 hover:border-red-300"
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>

            {/* Stats-Kacheln */}
            {filteredLogs.length > 0 && (
              <div className="grid grid-cols-4 gap-2">
                <Card className="text-center border-0 bg-red-50">
                  <CardContent className="p-2">
                    <p className="text-[10px] text-gray-500 leading-tight">Ø Systole</p>
                    <p className="text-lg font-bold text-red-600">{avgSys}</p>
                  </CardContent>
                </Card>
                <Card className="text-center border-0 bg-blue-50">
                  <CardContent className="p-2">
                    <p className="text-[10px] text-gray-500 leading-tight">Ø Diastole</p>
                    <p className="text-lg font-bold text-blue-600">{avgDia}</p>
                  </CardContent>
                </Card>
                <Card className="text-center border-0 bg-orange-50">
                  <CardContent className="p-2">
                    <p className="text-[10px] text-gray-500 leading-tight">Max</p>
                    <p className="text-lg font-bold text-orange-600">{maxSys}</p>
                  </CardContent>
                </Card>
                <Card className="text-center border-0 bg-green-50">
                  <CardContent className="p-2">
                    <p className="text-[10px] text-gray-500 leading-tight">Min</p>
                    <p className="text-lg font-bold text-green-600">{minSys}</p>
                  </CardContent>
                </Card>
              </div>
            )}

            {/* Trend Badge */}
            {trend && (
              <div className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                trend === "up" ? "bg-red-50 text-red-700" :
                trend === "down" ? "bg-green-50 text-green-700" :
                "bg-gray-50 text-gray-700"
              }`}>
                {trend === "up" && <TrendingUp className="h-4 w-4" />}
                {trend === "down" && <TrendingDown className="h-4 w-4" />}
                {trend === "stable" && <Minus className="h-4 w-4" />}
                Trend: {trend === "up" ? "Steigend" : trend === "down" ? "Sinkend" : "Stabil"}
              </div>
            )}

            {/* Hauptchart */}
            <Card>
              <CardContent className="pt-4 pb-2">
                {filteredLogs.length > 1 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={filteredLogs} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
                      {/* Farbzonen */}
                      <ReferenceArea y1={130} y2={180} fill="#fee2e2" fillOpacity={0.35} />
                      <ReferenceArea y1={100} y2={130} fill="#fef9c3" fillOpacity={0.35} />
                      <ReferenceArea y1={60} y2={100} fill="#dcfce7" fillOpacity={0.35} />
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                      <XAxis
                        dataKey="measured_at"
                        tickFormatter={(t) => format(new Date(t), "dd.MM")}
                        tick={{ fontSize: 10, fill: "#9ca3af" }}
                        minTickGap={28}
                        axisLine={false}
                        tickLine={false}
                      />
                      <YAxis
                        domain={[50, 180]}
                        tick={{ fontSize: 10, fill: "#9ca3af" }}
                        axisLine={false}
                        tickLine={false}
                        ticks={[60, 80, 100, 120, 140, 160, 180]}
                      />
                      <Tooltip content={<CustomTooltip />} />
                      <Legend
                        wrapperStyle={{ fontSize: "11px", paddingTop: "8px" }}
                        iconType="circle"
                        iconSize={8}
                      />
                      <ReferenceLine y={140} stroke="#ef4444" strokeDasharray="5 3" strokeWidth={1.5} label={{ value: "140", position: "right", fill: "#ef4444", fontSize: 9 }} />
                      <ReferenceLine y={90} stroke="#3b82f6" strokeDasharray="5 3" strokeWidth={1} label={{ value: "90", position: "right", fill: "#3b82f6", fontSize: 9 }} />
                      <Line
                        type="monotone"
                        dataKey="systolic"
                        stroke="#ef4444"
                        strokeWidth={2.5}
                        dot={{ r: 4, fill: "#ef4444", strokeWidth: 2, stroke: "#fff" }}
                        activeDot={{ r: 6 }}
                        name="Systole"
                        connectNulls
                      />
                      <Line
                        type="monotone"
                        dataKey="diastolic"
                        stroke="#3b82f6"
                        strokeWidth={2.5}
                        dot={{ r: 4, fill: "#3b82f6", strokeWidth: 2, stroke: "#fff" }}
                        activeDot={{ r: 6 }}
                        name="Diastole"
                        connectNulls
                      />
                      <Line
                        type="monotone"
                        dataKey="pulse"
                        stroke="#a855f7"
                        strokeWidth={1.5}
                        strokeDasharray="4 3"
                        dot={{ r: 3, fill: "#a855f7", strokeWidth: 0 }}
                        name="Puls"
                        connectNulls
                      />
                    </LineChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="flex flex-col items-center justify-center h-[250px] text-gray-400">
                    <Activity className="h-12 w-12 mb-2 opacity-20" />
                    <p className="text-sm">Nicht genügend Daten für Grafik</p>
                    <p className="text-xs mt-1">Bitte mindestens 2 Messungen erfassen</p>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Legende Zonen */}
            <div className="grid grid-cols-3 gap-2 text-xs">
              <div className="flex items-center gap-1.5 bg-red-50 rounded-lg px-2 py-1.5">
                <div className="w-3 h-3 rounded bg-red-200 shrink-0" />
                <span className="text-red-700">Hoch (&gt;130)</span>
              </div>
              <div className="flex items-center gap-1.5 bg-yellow-50 rounded-lg px-2 py-1.5">
                <div className="w-3 h-3 rounded bg-yellow-200 shrink-0" />
                <span className="text-yellow-700">Grenzwertig</span>
              </div>
              <div className="flex items-center gap-1.5 bg-green-50 rounded-lg px-2 py-1.5">
                <div className="w-3 h-3 rounded bg-green-200 shrink-0" />
                <span className="text-green-700">Normal</span>
              </div>
            </div>
          </TabsContent>
          
          <TabsContent value="history">
            <div className="space-y-3">
              {logs.slice().reverse().map((log) => (
                <Card key={log.id} className="overflow-hidden">
                  <div className="flex justify-between items-center p-4">
                    <div>
                      <div className="flex items-baseline gap-2">
                        <span className={`font-bold text-lg ${getStatusColor(log.systolic, log.diastolic)}`}>
                          {log.systolic}/{log.diastolic}
                        </span>
                        {log.pulse && (
                          <span className="text-xs text-gray-500 flex items-center gap-0.5">
                            <Heart className="h-3 w-3" /> {log.pulse}
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-2 text-xs text-gray-500 mt-1">
                        <span>{format(new Date(log.measured_at), "dd.MM.yyyy HH:mm")}</span>
                        <span className="bg-gray-100 px-1.5 py-0.5 rounded text-gray-600">{log.context}</span>
                      </div>
                    </div>
                    <Button 
                      variant="ghost" 
                      size="icon"
                      className="text-gray-400 hover:text-red-600 h-8 w-8"
                      onClick={() => deleteMutation.mutate(log.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </Card>
              ))}
            </div>
          </TabsContent>
        </Tabs>

        {/* Info Card */}
        <Card className="bg-blue-50 border-blue-100">
          <CardContent className="p-4 flex gap-3">
            <AlertCircle className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-blue-800">
              <p className="font-semibold mb-1">Empfehlung bei Bluthochdruck:</p>
              <p>Messen Sie täglich, idealerweise morgens direkt nach dem Aufstehen und abends in Ruhe. Dokumentieren Sie Auffälligkeiten.</p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}