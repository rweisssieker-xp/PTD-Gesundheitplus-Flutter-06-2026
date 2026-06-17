import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Scale, Ruler, TrendingUp, Plus, Trash2, Info } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts';
import { format } from "date-fns";
import { de } from "date-fns/locale";

export default function WeightPage() {
  const entities = useEntities();
  const [showForm, setShowForm] = useState(false);
  const [userHeight, setUserHeight] = useState("");
  const [newEntry, setNewEntry] = useState({
    weight: "",
    measured_at: format(new Date(), "yyyy-MM-dd'T'HH:mm")
  });

  const queryClient = useQueryClient();

  // Load User Data
  const { data: user } = useQuery({
    queryKey: ['user-height'],
    queryFn: () => base44.auth.me()
  });

  useEffect(() => {
    if (user?.height) {
      setUserHeight(user.height);
    }
  }, [user]);

  // Load Weight Logs
  const { data: logs = [] } = useQuery({
    queryKey: ['weight-logs'],
    queryFn: async () => {
      const data = await entities.WeightLog.list('-measured_at', 50);
      return data.sort((a, b) => new Date(a.measured_at) - new Date(b.measured_at));
    }
  });

  // Mutations
  const updateUserMutation = useMutation({
    mutationFn: (height) => base44.auth.updateMe({ height: Number(height) }),
    onSuccess: () => queryClient.invalidateQueries(['user-height'])
  });

  const createLogMutation = useMutation({
    mutationFn: (data) => entities.WeightLog.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries(['weight-logs']);
      setShowForm(false);
      setNewEntry({
        weight: "",
        measured_at: format(new Date(), "yyyy-MM-dd'T'HH:mm")
      });
    }
  });

  const deleteLogMutation = useMutation({
    mutationFn: (id) => entities.WeightLog.delete(id),
    onSuccess: () => queryClient.invalidateQueries(['weight-logs'])
  });

  const calculateBMI = (weight, heightCm) => {
    if (!weight || !heightCm) return 0;
    const heightM = heightCm / 100;
    return (weight / (heightM * heightM)).toFixed(1);
  };

  const getBMICategory = (bmi) => {
    if (!bmi) return { label: "-", color: "text-gray-500" };
    if (bmi < 18.5) return { label: "Untergewicht", color: "text-blue-500" };
    if (bmi < 25) return { label: "Normalgewicht", color: "text-green-600" };
    if (bmi < 30) return { label: "Übergewicht", color: "text-orange-500" };
    return { label: "Adipositas", color: "text-red-600" };
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const bmi = userHeight ? Number(calculateBMI(newEntry.weight, userHeight)) : undefined;
    
    createLogMutation.mutate({
      weight: Number(newEntry.weight),
      measured_at: new Date(newEntry.measured_at).toISOString(),
      bmi: bmi
    });
  };

  const latest = logs.length > 0 ? logs[logs.length - 1] : null;
  const currentBMI = latest && userHeight ? calculateBMI(latest.weight, userHeight) : null;
  const bmiInfo = getBMICategory(currentBMI);

  return (
    <div className="min-h-screen bg-gray-50 p-4 pb-20">
      <div className="max-w-md mx-auto space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <Scale className="h-6 w-6 text-indigo-600" />
            Gewicht & BMI
          </h1>
          <Button onClick={() => setShowForm(!showForm)} size="sm" className="bg-indigo-600 hover:bg-indigo-700">
            <Plus className="h-4 w-4 mr-1" /> Messung
          </Button>
        </div>

        {/* Height Input if missing */}
        {(!userHeight || userHeight === 0) && (
          <Card className="bg-yellow-50 border-yellow-200">
            <CardContent className="pt-6">
              <div className="space-y-3">
                <div className="flex items-center gap-2 text-yellow-800">
                  <Ruler className="h-5 w-5" />
                  <p className="font-semibold text-sm">Bitte geben Sie Ihre Größe ein</p>
                </div>
                <div className="flex gap-2">
                  <Input 
                    type="number" 
                    placeholder="Größe in cm (z.B. 175)" 
                    onChange={(e) => {
                      if(e.target.value.length >= 2) updateUserMutation.mutate(e.target.value)
                    }}
                    className="bg-white"
                  />
                </div>
                <p className="text-xs text-yellow-700">Notwendig für die BMI-Berechnung</p>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Dashboard Cards */}
        <div className="grid grid-cols-2 gap-4">
          <Card>
            <CardContent className="pt-6">
              <p className="text-xs text-gray-500 mb-1">Aktuelles Gewicht</p>
              <div className="flex items-baseline gap-1">
                <span className="text-3xl font-bold text-gray-900">{latest ? latest.weight : "-"}</span>
                <span className="text-sm text-gray-500">kg</span>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <p className="text-xs text-gray-500 mb-1">Ihr BMI</p>
              <div className="flex items-baseline gap-1">
                <span className={`text-3xl font-bold ${bmiInfo.color}`}>{currentBMI || "-"}</span>
              </div>
              <p className={`text-xs mt-1 ${bmiInfo.color} font-medium`}>{bmiInfo.label}</p>
            </CardContent>
          </Card>
        </div>

        {/* Chart */}
        {logs.length > 1 && (
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-500">Verlauf</CardTitle>
            </CardHeader>
            <CardContent className="h-[200px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={logs}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis 
                    dataKey="measured_at" 
                    tickFormatter={(t) => format(new Date(t), "dd.MM")}
                    tick={{fontSize: 10}}
                  />
                  <YAxis domain={['dataMin - 2', 'dataMax + 2']} hide />
                  <Tooltip 
                    labelFormatter={(t) => format(new Date(t), "dd.MM.yyyy")}
                    formatter={(value) => [`${value} kg`]}
                  />
                  <Line type="monotone" dataKey="weight" stroke="#4f46e5" strokeWidth={3} dot={{r: 4}} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        )}

        {/* Form */}
        {showForm && (
          <Card className="animate-in slide-in-from-top-4 border-indigo-100 shadow-lg">
            <CardHeader>
              <CardTitle>Gewicht eintragen</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label>Gewicht (kg)</Label>
                  <Input 
                    type="number" 
                    step="0.1"
                    placeholder="z.B. 75.5"
                    required
                    value={newEntry.weight}
                    onChange={e => setNewEntry({...newEntry, weight: e.target.value})}
                    autoFocus
                    className="text-lg"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Datum</Label>
                  <Input 
                    type="datetime-local" 
                    required
                    value={newEntry.measured_at}
                    onChange={e => setNewEntry({...newEntry, measured_at: e.target.value})}
                  />
                </div>
                <Button type="submit" className="w-full bg-indigo-600 hover:bg-indigo-700">Speichern</Button>
              </form>
            </CardContent>
          </Card>
        )}

        {/* History List */}
        <div className="space-y-2">
          <h3 className="text-sm font-medium text-gray-500 px-1">Historie</h3>
          {logs.slice().reverse().map((log) => (
            <div key={log.id} className="bg-white p-4 rounded-lg border border-gray-100 shadow-sm flex justify-between items-center">
              <div>
                <span className="text-lg font-bold text-gray-900">{log.weight} kg</span>
                <p className="text-xs text-gray-500">{format(new Date(log.measured_at), "dd.MM.yyyy, HH:mm")}</p>
              </div>
              <div className="flex items-center gap-4">
                {log.bmi && (
                   <span className="text-sm font-medium text-gray-600 bg-gray-100 px-2 py-1 rounded">
                     BMI {log.bmi.toFixed(1)}
                   </span>
                )}
                <Button 
                  variant="ghost" 
                  size="icon"
                  className="text-gray-300 hover:text-red-500 h-8 w-8"
                  onClick={() => deleteLogMutation.mutate(log.id)}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}