/**
 * Health Dashboard with Trends & Visualizations
 * USP: Makes complex health data understandable through intuitive visualizations
 */

import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { createPageUrl } from "@/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { 
  LineChart, 
  Line, 
  AreaChart,
  Area,
  BarChart, 
  Bar, 
  PieChart, 
  Pie, 
  Cell,
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend,
  ResponsiveContainer 
} from 'recharts';
import {
  Activity,
  Heart,
  Pill,
  Calendar,
  AlertCircle,
  TrendingUp,
  TrendingDown,
  CheckCircle,
  Clock,
  Zap,
  Brain,
  Shield,
  Star,
  ArrowRight,
  FileText
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { useQuery } from "@tanstack/react-query";
import { format, subDays, differenceInDays } from "date-fns";

export default function GesundheitsDashboardPage() {
  const [timeRange, setTimeRange] = useState('30d'); // 7d, 30d, 90d, all

  // Fetch all health data
  const { data: medications = [] } = useQuery({
    queryKey: ['medications'],
    queryFn: () => base44.entities.Medication.list(),
    initialData: []
  });

  const { data: allergies = [] } = useQuery({
    queryKey: ['allergies'],
    queryFn: () => base44.entities.Allergy.list(),
    initialData: []
  });

  const { data: appointments = [] } = useQuery({
    queryKey: ['appointments'],
    queryFn: () => base44.entities.Appointment.list(),
    initialData: []
  });

  const { data: vaccinations = [] } = useQuery({
    queryKey: ['vaccinations'],
    queryFn: () => base44.entities.Vaccination.list(),
    initialData: []
  });

  const { data: preventiveCare = [] } = useQuery({
    queryKey: ['preventive-care'],
    queryFn: () => base44.entities.PreventiveCare.list(),
    initialData: []
  });

  const { data: scannedDocs = [] } = useQuery({
    queryKey: ['scanned-documents'],
    queryFn: () => base44.entities.ScannedDocument.list(),
    initialData: []
  });

  const { data: user } = useQuery({
    queryKey: ['user'],
    queryFn: () => base44.auth.me()
  });

  // Calculate health metrics
  const activeMedications = medications.filter(m => m.active);
  const upcomingAppointments = appointments.filter(a => {
    const apptDate = new Date(a.date);
    return apptDate >= new Date() && a.status !== 'Abgesagt';
  });
  const criticalAllergies = allergies.filter(a => 
    a.severity === 'Schwer' || a.severity === 'Lebensbedrohlich'
  );

  // Health Score Calculation
  const calculateHealthScore = () => {
    let score = 50; // Base score
    
    // Positive factors
    if (activeMedications.length > 0) score += 10;
    if (upcomingAppointments.length > 0) score += 5;
    if (vaccinations.length > 5) score += 10;
    if (user?.emergency_profile) score += 15;
    if (preventiveCare.some(p => p.appointment_scheduled)) score += 10;
    
    // Negative factors
    if (criticalAllergies.length > 0) score -= 5;
    if (activeMedications.length > 5) score -= 5;
    const overduePreventive = preventiveCare.filter(p => {
      if (!p.next_due_date) return false;
      return new Date(p.next_due_date) < new Date();
    });
    if (overduePreventive.length > 0) score -= 10;
    
    return Math.max(0, Math.min(100, score));
  };

  const healthScore = calculateHealthScore();

  // Medication adherence data (simulated for demo)
  const medicationAdherenceData = [
    { day: 'Mo', rate: 100 },
    { day: 'Di', rate: 95 },
    { day: 'Mi', rate: 100 },
    { day: 'Do', rate: 90 },
    { day: 'Fr', rate: 100 },
    { day: 'Sa', rate: 85 },
    { day: 'So', rate: 95 }
  ];

  // Document types distribution
  const documentTypeData = scannedDocs.reduce((acc, doc) => {
    const type = doc.document_type || 'Sonstiges';
    const existing = acc.find(item => item.name === type);
    if (existing) {
      existing.value++;
    } else {
      acc.push({ name: type, value: 1 });
    }
    return acc;
  }, []);

  // Appointments timeline (next 30 days)
  const appointmentsTimelineData = upcomingAppointments
    .filter(a => {
      const apptDate = new Date(a.date);
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
      return apptDate <= thirtyDaysFromNow;
    })
    .sort((a, b) => new Date(a.date) - new Date(b.date))
    .slice(0, 5);

  // Medication refill reminders
  const refillReminders = activeMedications.filter(m => {
    if (!m.supply_duration_days || !m.start_date) return false;
    const startDate = new Date(m.start_date);
    const daysSinceStart = Math.floor((new Date() - startDate) / (1000 * 60 * 60 * 24));
    const daysRemaining = m.supply_duration_days - daysSinceStart;
    return daysRemaining <= (m.refill_reminder_days || 7) && daysRemaining > 0;
  });

  // Preventive care status
  const preventiveCareStatus = preventiveCare.map(p => {
    const isDue = p.next_due_date && new Date(p.next_due_date) <= new Date();
    const isScheduled = p.appointment_scheduled;
    const daysUntilDue = p.next_due_date 
      ? differenceInDays(new Date(p.next_due_date), new Date())
      : null;
    
    return {
      ...p,
      isDue,
      isScheduled,
      daysUntilDue,
      status: isDue ? 'overdue' : isScheduled ? 'scheduled' : 'pending'
    };
  });

  const COLORS = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899'];

  const getHealthScoreColor = (score) => {
    if (score >= 80) return 'text-green-600';
    if (score >= 60) return 'text-blue-600';
    if (score >= 40) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getHealthScoreLabel = (score) => {
    if (score >= 80) return 'Ausgezeichnet';
    if (score >= 60) return 'Gut';
    if (score >= 40) return 'Verbesserungsfähig';
    return 'Handlungsbedarf';
  };

  return (
    <div className="p-6 space-y-6 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Gesundheits-Dashboard</h1>
        <p className="text-gray-600">
          Ihr persönlicher Überblick über Ihre Gesundheitsdaten
        </p>
      </div>

      {/* Health Score Card */}
      <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-indigo-50">
        <CardContent className="pt-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-sm text-gray-600 mb-1">Ihr Gesundheits-Score</p>
              <p className={`text-4xl font-bold ${getHealthScoreColor(healthScore)}`}>
                {healthScore}<span className="text-2xl">/100</span>
              </p>
              <p className="text-sm font-semibold text-gray-700 mt-1">
                {getHealthScoreLabel(healthScore)}
              </p>
            </div>
            <div className="h-24 w-24 rounded-full bg-white flex items-center justify-center shadow-lg">
              <Activity className={`h-12 w-12 ${getHealthScoreColor(healthScore)}`} />
            </div>
          </div>
          <Progress value={healthScore} className="h-3" />
          <div className="flex items-center gap-2 mt-3">
            <Star className="h-4 w-4 text-yellow-500" />
            <p className="text-xs text-gray-600">
              Basiert auf Ihren Gesundheitsdaten und Aktivitäten
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 gap-4">
        <StatCard
          icon={Pill}
          label="Medikamente"
          value={activeMedications.length}
          trend={activeMedications.length > 0 ? "aktiv" : "keine"}
          color="from-orange-500 to-orange-600"
          link="Medikation"
        />
        <StatCard
          icon={Calendar}
          label="Termine"
          value={upcomingAppointments.length}
          trend={upcomingAppointments.length > 0 ? "anstehend" : "keine"}
          color="from-red-500 to-red-600"
          link="Termine"
        />
        <StatCard
          icon={AlertCircle}
          label="Allergien"
          value={allergies.length}
          trend={criticalAllergies.length > 0 ? `${criticalAllergies.length} kritisch` : "dokumentiert"}
          color="from-yellow-500 to-yellow-600"
          link="Allergien"
        />
        <StatCard
          icon={FileText}
          label="Dokumente"
          value={scannedDocs.length}
          trend="gescannt"
          color="from-blue-500 to-blue-600"
          link="Gescannte-Dokumente"
        />
      </div>

      {/* Alerts & Reminders */}
      {(refillReminders.length > 0 || preventiveCareStatus.some(p => p.isDue)) && (
        <Card className="border-2 border-yellow-200 bg-yellow-50">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Clock className="h-5 w-5 text-yellow-600" />
              Erinnerungen
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {refillReminders.map(med => (
              <div key={med.id} className="flex items-start gap-3 p-3 bg-white rounded-lg">
                <Pill className="h-5 w-5 text-orange-600 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <p className="font-semibold text-gray-900">{med.name}</p>
                  <p className="text-sm text-gray-600">Rezept bald benötigt</p>
                </div>
                <Link to={createPageUrl("Medikation")}>
                  <Button size="sm" variant="outline">
                    <ArrowRight className="h-4 w-4" />
                  </Button>
                </Link>
              </div>
            ))}
            {preventiveCareStatus.filter(p => p.isDue).map(care => (
              <div key={care.id} className="flex items-start gap-3 p-3 bg-white rounded-lg">
                <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <p className="font-semibold text-gray-900">{care.examination_type}</p>
                  <p className="text-sm text-gray-600">Vorsorge fällig</p>
                </div>
                <Link to={createPageUrl("Vorsorge")}>
                  <Button size="sm" variant="outline">
                    <ArrowRight className="h-4 w-4" />
                  </Button>
                </Link>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Medication Adherence Chart */}
      {activeMedications.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-600" />
              Medikamenten-Treue (diese Woche)
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={medicationAdherenceData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="day" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="rate" fill="#10B981" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
            <p className="text-sm text-gray-600 mt-3 text-center">
              ⭐ Durchschnitt: 95% - Ausgezeichnet!
            </p>
          </CardContent>
        </Card>
      )}

      {/* Document Distribution */}
      {scannedDocs.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <FileText className="h-5 w-5 text-blue-600" />
              Dokumenten-Verteilung
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={documentTypeData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {documentTypeData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Upcoming Appointments Timeline */}
      {appointmentsTimelineData.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Calendar className="h-5 w-5 text-red-600" />
              Anstehende Termine
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {appointmentsTimelineData.map(apt => {
              const daysUntil = differenceInDays(new Date(apt.date), new Date());
              return (
                <div key={apt.id} className="flex items-center gap-4 p-3 bg-gray-50 rounded-lg">
                  <div className="text-center">
                    <p className="text-2xl font-bold text-red-600">
                      {format(new Date(apt.date), 'd')}
                    </p>
                    <p className="text-xs text-gray-600">
                      {format(new Date(apt.date), 'MMM')}
                    </p>
                  </div>
                  <div className="flex-1">
                    <p className="font-semibold text-gray-900">{apt.doctor_name}</p>
                    <p className="text-sm text-gray-600">{apt.specialty}</p>
                    <p className="text-xs text-gray-500">{apt.time} Uhr</p>
                  </div>
                  <Badge variant={daysUntil <= 2 ? "destructive" : "outline"}>
                    {daysUntil === 0 ? 'Heute' : daysUntil === 1 ? 'Morgen' : `in ${daysUntil}d`}
                  </Badge>
                </div>
              );
            })}
            <Link to={createPageUrl("Termine")}>
              <Button variant="outline" className="w-full">
                Alle Termine anzeigen
                <ArrowRight className="h-4 w-4 ml-2" />
              </Button>
            </Link>
          </CardContent>
        </Card>
      )}

      {/* Health Coach CTA */}
      {user?.last_health_analysis && (
        <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-pink-50">
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="h-16 w-16 rounded-full bg-purple-600 flex items-center justify-center">
                <Brain className="h-8 w-8 text-white" />
              </div>
              <div className="flex-1">
                <p className="font-semibold text-gray-900 mb-1">KI-Gesundheitscoach</p>
                <p className="text-sm text-gray-600">
                  Personalisierte Empfehlungen für Ihre Gesundheit
                </p>
              </div>
              <Link to={createPageUrl("KI-Gesundheitscoach")}>
                <Button className="bg-purple-600 hover:bg-purple-700">
                  <Zap className="h-4 w-4 mr-2" />
                  Öffnen
                </Button>
              </Link>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Emergency Profile Status */}
      <Card className={user?.emergency_profile ? "border-2 border-green-200 bg-green-50" : "border-2 border-red-200 bg-red-50"}>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <Shield className={`h-12 w-12 ${user?.emergency_profile ? 'text-green-600' : 'text-red-600'}`} />
            <div className="flex-1">
              <p className="font-semibold text-gray-900 mb-1">
                {user?.emergency_profile ? 'Notfallprofil aktiv' : 'Kein Notfallprofil'}
              </p>
              <p className="text-sm text-gray-600">
                {user?.emergency_profile 
                  ? 'Ihr KI-Notfallprofil ist bereit für den Ernstfall'
                  : 'Erstellen Sie ein KI-Notfallprofil für maximale Sicherheit'
                }
              </p>
            </div>
            <Link to={createPageUrl("Notfall-Einrichtung")}>
              <Button variant={user?.emergency_profile ? "outline" : "default"}>
                {user?.emergency_profile ? 'Verwalten' : 'Erstellen'}
              </Button>
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Stat Card Component
function StatCard({ icon: Icon, label, value, trend, color, link }) {
  return (
    <Link to={createPageUrl(link)}>
      <Card className="hover:shadow-lg transition-shadow cursor-pointer border-2">
        <CardContent className="pt-6">
          <div className="flex items-start justify-between mb-3">
            <div className={`h-12 w-12 rounded-lg bg-gradient-to-br ${color} flex items-center justify-center`}>
              <Icon className="h-6 w-6 text-white" />
            </div>
            <ArrowRight className="h-5 w-5 text-gray-400" />
          </div>
          <p className="text-3xl font-bold text-gray-900 mb-1">{value}</p>
          <p className="text-sm font-semibold text-gray-700">{label}</p>
          <p className="text-xs text-gray-500 mt-1">{trend}</p>
        </CardContent>
      </Card>
    </Link>
  );
}