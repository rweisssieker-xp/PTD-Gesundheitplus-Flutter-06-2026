import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import {
  Syringe,
  Plus,
  Calendar,
  AlertCircle,
  FileText,
  Trash2,
  CheckCircle,
  Clock,
  Bell,
  Sparkles,
  Info
} from "lucide-react";
import { toast } from "sonner";
import { format, addYears, isBefore, differenceInMonths } from "date-fns";
import { de } from "date-fns/locale";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import VoiceNavigation from "../components/VoiceNavigation";
import { getVaccinationRecommendations } from "@/components/PreventionEngine";

export default function ImpfpassPage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [activeTab, setActiveTab] = useState("vaccinations");
  const [showVaccDialog, setShowVaccDialog] = useState(false);
  const [showPassDialog, setShowPassDialog] = useState(false);
  const [editingVacc, setEditingVacc] = useState(null);
  const [editingPass, setEditingPass] = useState(null);
  const [user, setUser] = useState(null);
  const [recommendations, setRecommendations] = useState([]);
  const [isLoadingRecs, setIsLoadingRecs] = useState(false);

  const [vaccFormData, setVaccFormData] = useState({
    vaccine_name: "",
    date_given: "",
    batch_number: "",
    administered_by: "",
    next_due_date: "",
    reminder_enabled: true,
    notes: ""
  });

  const [passFormData, setPassFormData] = useState({
    pass_type: "",
    title: "",
    date_implanted: "",
    manufacturer: "",
    model: "",
    material: "",
    serial_number: "",
    document_url: "",
    notes: ""
  });

  useEffect(() => {
    loadUserAndRecommendations();
  }, []);

  const loadUserAndRecommendations = async () => {
    try {
      const userData = await base44.auth.me();
      setUser(userData);
      
      if (userData.date_of_birth) {
        setIsLoadingRecs(true);
        const vaccinations = await entities.Vaccination.list();
        const recs = await getVaccinationRecommendations(userData, vaccinations);
        setRecommendations(recs);
        setIsLoadingRecs(false);
      }
    } catch (error) {
      console.error("Error loading user:", error);
      setIsLoadingRecs(false);
    }
  };

  const { data: vaccinations = [], isLoading: isLoadingVacc } = useQuery({
    queryKey: ['vaccinations'],
    queryFn: () => entities.Vaccination.list(),
  });

  const { data: healthPasses = [], isLoading: isLoadingPasses } = useQuery({
    queryKey: ['health-passes'],
    queryFn: () => entities.HealthPass.list(),
  });

  const saveVaccMutation = useMutation({
    mutationFn: (data) => {
      if (editingVacc) {
        return entities.Vaccination.update(editingVacc.id, data);
      }
      return entities.Vaccination.create(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vaccinations'] });
      toast.success(editingVacc ? "Impfung aktualisiert" : "Impfung hinzugefügt");
      resetVaccForm();
      loadUserAndRecommendations();
    },
  });

  const savePassMutation = useMutation({
    mutationFn: (data) => {
      if (editingPass) {
        return entities.HealthPass.update(editingPass.id, data);
      }
      return entities.HealthPass.create(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['health-passes'] });
      toast.success(editingPass ? "Pass aktualisiert" : "Pass hinzugefügt");
      resetPassForm();
    },
  });

  const deleteVaccMutation = useMutation({
    mutationFn: (id) => entities.Vaccination.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['vaccinations'] });
      toast.success("Impfung gelöscht");
      loadUserAndRecommendations();
    },
  });

  const deletePassMutation = useMutation({
    mutationFn: (id) => entities.HealthPass.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['health-passes'] });
      toast.success("Pass gelöscht");
    },
  });

  const resetVaccForm = () => {
    setVaccFormData({
      vaccine_name: "",
      date_given: "",
      batch_number: "",
      administered_by: "",
      next_due_date: "",
      reminder_enabled: true,
      notes: ""
    });
    setEditingVacc(null);
    setShowVaccDialog(false);
  };

  const resetPassForm = () => {
    setPassFormData({
      pass_type: "",
      title: "",
      date_implanted: "",
      manufacturer: "",
      model: "",
      material: "",
      serial_number: "",
      document_url: "",
      notes: ""
    });
    setEditingPass(null);
    setShowPassDialog(false);
  };

  const handleEditVacc = (vacc) => {
    setVaccFormData(vacc);
    setEditingVacc(vacc);
    setShowVaccDialog(true);
  };

  const handleSaveVacc = () => {
    if (!vaccFormData.vaccine_name || !vaccFormData.date_given) {
      toast.error("Impfstoff und Datum sind erforderlich");
      return;
    }
    saveVaccMutation.mutate(vaccFormData);
  };

  const handleEditPass = (pass) => {
    setPassFormData(pass);
    setEditingPass(pass);
    setShowPassDialog(true);
  };

  const handleSavePass = () => {
    if (!passFormData.pass_type || !passFormData.title) {
      toast.error("Art und Bezeichnung sind erforderlich");
      return;
    }
    savePassMutation.mutate(passFormData);
  };

  // Calculate upcoming boosters
  const upcomingBoosters = vaccinations
    .filter(v => {
      if (!v.next_due_date) return false;
      const dueDate = new Date(v.next_due_date);
      const today = new Date();
      const monthsUntil = differenceInMonths(dueDate, today);
      return monthsUntil <= 3 && monthsUntil >= 0;
    })
    .sort((a, b) => new Date(a.next_due_date) - new Date(b.next_due_date));

  return (
    <div className="p-6 space-y-6 pb-24">
      <VoiceNavigation content={`Impfpass. ${vaccinations.length} Impfungen erfasst.`} />

      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Impfpass & Gesundheitspässe</h1>
        <p className="text-gray-600">Ihre Impfungen und wichtigen Gesundheitsdokumente</p>
      </div>

      {/* AI Recommendations Card */}
      {recommendations.length > 0 && (
        <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-pink-50">
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Sparkles className="h-5 w-5 text-purple-600" />
              KI-Impfempfehlungen ({recommendations.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {recommendations.slice(0, 3).map((rec, idx) => {
              const urgencyColors = {
                high: "border-red-300 bg-red-50",
                medium: "border-orange-300 bg-orange-50",
                low: "border-blue-300 bg-blue-50"
              };
              
              return (
                <div key={idx} className={`p-3 rounded-lg border-2 ${urgencyColors[rec.urgency]}`}>
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="font-semibold text-gray-900">{rec.vaccine}</p>
                        {rec.urgency === 'high' && (
                          <Badge className="bg-red-600">Dringend</Badge>
                        )}
                        {rec.seasonal && (
                          <Badge variant="outline">Saisonal</Badge>
                        )}
                      </div>
                      <p className="text-sm text-gray-700">{rec.reason}</p>
                      {rec.bestTime && (
                        <p className="text-xs text-gray-600 mt-1">
                          ⏰ {rec.bestTime}
                        </p>
                      )}
                    </div>
                    <Button
                      onClick={() => {
                        setVaccFormData({
                          ...vaccFormData,
                          vaccine_name: rec.vaccine
                        });
                        setShowVaccDialog(true);
                      }}
                      size="sm"
                      className="bg-purple-600 hover:bg-purple-700"
                    >
                      Hinzufügen
                    </Button>
                  </div>
                </div>
              );
            })}
            {recommendations.length > 3 && (
              <Button
                onClick={() => window.location.href = "/Vorsorge"}
                variant="outline"
                className="w-full"
                size="sm"
              >
                Alle {recommendations.length} Empfehlungen anzeigen
              </Button>
            )}
          </CardContent>
        </Card>
      )}

      {/* Statistics */}
      <div className="grid grid-cols-3 gap-4">
        <Card className="border-2">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center">
                <Syringe className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{vaccinations.length}</p>
                <p className="text-sm text-gray-600">Impfungen</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-2">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="h-12 w-12 rounded-full bg-orange-100 flex items-center justify-center">
                <Bell className="h-6 w-6 text-orange-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{upcomingBoosters.length}</p>
                <p className="text-sm text-gray-600">Fällig</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-2">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
                <FileText className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{healthPasses.length}</p>
                <p className="text-sm text-gray-600">Pässe</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Upcoming Boosters Warning */}
      {upcomingBoosters.length > 0 && (
        <Card className="border-2 border-orange-200 bg-orange-50">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <AlertCircle className="h-5 w-5 text-orange-600 flex-shrink-0" />
              <div>
                <p className="font-semibold text-orange-900 mb-2">
                  {upcomingBoosters.length} Auffrischung(en) in den nächsten 3 Monaten fällig
                </p>
                <div className="space-y-1">
                  {upcomingBoosters.map((vacc, idx) => (
                    <p key={idx} className="text-sm text-orange-800">
                      • {vacc.vaccine_name} - Fällig: {format(new Date(vacc.next_due_date), 'dd.MM.yyyy')}
                    </p>
                  ))}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Tabs */}
      <div className="flex gap-2 border-b-2">
        <button
          onClick={() => setActiveTab("vaccinations")}
          className={`px-4 py-2 font-semibold ${
            activeTab === "vaccinations"
              ? "border-b-2 border-indigo-600 text-indigo-600"
              : "text-gray-600"
          }`}
        >
          <Syringe className="h-4 w-4 inline mr-2" />
          Impfungen
        </button>
        <button
          onClick={() => setActiveTab("passes")}
          className={`px-4 py-2 font-semibold ${
            activeTab === "passes"
              ? "border-b-2 border-indigo-600 text-indigo-600"
              : "text-gray-600"
          }`}
        >
          <FileText className="h-4 w-4 inline mr-2" />
          Gesundheitspässe
        </button>
      </div>

      {activeTab === "vaccinations" && (
        <div className="space-y-4">
          <Dialog open={showVaccDialog} onOpenChange={setShowVaccDialog}>
            <DialogTrigger asChild>
              <Button className="w-full h-14 bg-gradient-to-r from-purple-500 to-purple-600">
                <Plus className="h-5 w-5 mr-2" />
                Impfung hinzufügen
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>
                  {editingVacc ? "Impfung bearbeiten" : "Neue Impfung"}
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-4 py-4">
                <div>
                  <Label>Impfstoff *</Label>
                  <Select
                    value={vaccFormData.vaccine_name}
                    onValueChange={(value) => setVaccFormData({...vaccFormData, vaccine_name: value})}
                  >
                    <SelectTrigger className="mt-1">
                      <SelectValue placeholder="Impfstoff auswählen" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Tetanus">Tetanus</SelectItem>
                      <SelectItem value="Diphtherie">Diphtherie</SelectItem>
                      <SelectItem value="Pertussis (Keuchhusten)">Pertussis (Keuchhusten)</SelectItem>
                      <SelectItem value="Polio">Polio</SelectItem>
                      <SelectItem value="Hepatitis A">Hepatitis A</SelectItem>
                      <SelectItem value="Hepatitis B">Hepatitis B</SelectItem>
                      <SelectItem value="MMR (Masern, Mumps, Röteln)">MMR (Masern, Mumps, Röteln)</SelectItem>
                      <SelectItem value="Varizellen (Windpocken)">Varizellen (Windpocken)</SelectItem>
                      <SelectItem value="Pneumokokken">Pneumokokken</SelectItem>
                      <SelectItem value="Meningokokken">Meningokokken</SelectItem>
                      <SelectItem value="HPV">HPV</SelectItem>
                      <SelectItem value="Influenza (Grippe)">Influenza (Grippe)</SelectItem>
                      <SelectItem value="COVID-19">COVID-19</SelectItem>
                      <SelectItem value="FSME (Zecken)">FSME (Zecken)</SelectItem>
                      <SelectItem value="Gelbfieber">Gelbfieber</SelectItem>
                      <SelectItem value="Tollwut">Tollwut</SelectItem>
                      <SelectItem value="Gürtelrose">Gürtelrose</SelectItem>
                      <SelectItem value="Sonstige">Sonstige</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Impfdatum *</Label>
                  <Input
                    type="date"
                    value={vaccFormData.date_given}
                    onChange={(e) => setVaccFormData({...vaccFormData, date_given: e.target.value})}
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Chargennummer</Label>
                  <Input
                    value={vaccFormData.batch_number}
                    onChange={(e) => setVaccFormData({...vaccFormData, batch_number: e.target.value})}
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Verabreicht von</Label>
                  <Input
                    value={vaccFormData.administered_by}
                    onChange={(e) => setVaccFormData({...vaccFormData, administered_by: e.target.value})}
                    placeholder="Arzt/Praxis"
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Nächste Auffrischung</Label>
                  <Input
                    type="date"
                    value={vaccFormData.next_due_date}
                    onChange={(e) => setVaccFormData({...vaccFormData, next_due_date: e.target.value})}
                    className="mt-1"
                  />
                </div>
                <div className="flex items-center justify-between">
                  <Label>Erinnerung aktivieren</Label>
                  <Switch
                    checked={vaccFormData.reminder_enabled}
                    onCheckedChange={(checked) => setVaccFormData({...vaccFormData, reminder_enabled: checked})}
                  />
                </div>
                <div>
                  <Label>Notizen</Label>
                  <Textarea
                    value={vaccFormData.notes}
                    onChange={(e) => setVaccFormData({...vaccFormData, notes: e.target.value})}
                    rows={2}
                    className="mt-1"
                  />
                </div>
                <div className="flex gap-3">
                  <Button onClick={resetVaccForm} variant="outline" className="flex-1">
                    Abbrechen
                  </Button>
                  <Button onClick={handleSaveVacc} className="flex-1 bg-purple-600">
                    Speichern
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>

          {vaccinations.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <Syringe className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">Noch keine Impfungen erfasst</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {vaccinations.map((vacc) => {
                const needsBooster = vacc.next_due_date && isBefore(new Date(vacc.next_due_date), new Date());
                return (
                  <Card key={vacc.id} className={`border-2 ${needsBooster ? 'border-orange-300' : ''}`}>
                    <CardContent className="pt-6">
                      <div className="flex justify-between items-start gap-4">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-2">
                            <h3 className="text-lg font-bold text-gray-900">{vacc.vaccine_name}</h3>
                            {needsBooster && (
                              <Badge className="bg-orange-600">Auffrischung fällig</Badge>
                            )}
                          </div>
                          <div className="space-y-1 text-sm">
                            <p className="text-gray-700">
                              <Calendar className="h-4 w-4 inline mr-1" />
                              {format(new Date(vacc.date_given), 'dd. MMMM yyyy', { locale: de })}
                            </p>
                            {vacc.administered_by && (
                              <p className="text-gray-600">Von: {vacc.administered_by}</p>
                            )}
                            {vacc.batch_number && (
                              <p className="text-gray-600 text-xs">Charge: {vacc.batch_number}</p>
                            )}
                            {vacc.next_due_date && (
                              <p className={`${needsBooster ? 'text-orange-600 font-semibold' : 'text-gray-600'}`}>
                                <Clock className="h-4 w-4 inline mr-1" />
                                Nächste Auffrischung: {format(new Date(vacc.next_due_date), 'dd.MM.yyyy')}
                              </p>
                            )}
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <Button onClick={() => handleEditVacc(vacc)} variant="outline" size="sm">
                            Bearbeiten
                          </Button>
                          <Button
                            onClick={() => {
                              if (confirm("Impfung wirklich löschen?")) {
                                deleteVaccMutation.mutate(vacc.id);
                              }
                            }}
                            variant="ghost"
                            size="sm"
                          >
                            <Trash2 className="h-4 w-4 text-red-500" />
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {activeTab === "passes" && (
        <div className="space-y-4">
          <Dialog open={showPassDialog} onOpenChange={setShowPassDialog}>
            <DialogTrigger asChild>
              <Button className="w-full h-14 bg-gradient-to-r from-indigo-500 to-indigo-600">
                <Plus className="h-5 w-5 mr-2" />
                Gesundheitspass hinzufügen
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>
                  {editingPass ? "Pass bearbeiten" : "Neuer Pass"}
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-4 py-4">
                <div>
                  <Label>Pass-Typ *</Label>
                  <Select
                    value={passFormData.pass_type}
                    onValueChange={(value) => setPassFormData({...passFormData, pass_type: value})}
                  >
                    <SelectTrigger className="mt-1">
                      <SelectValue placeholder="Pass-Typ wählen" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Implantatpass">Implantatpass</SelectItem>
                      <SelectItem value="Endoprothese">Endoprothese</SelectItem>
                      <SelectItem value="Herzschrittmacher">Herzschrittmacher</SelectItem>
                      <SelectItem value="Insulinpumpe">Insulinpumpe</SelectItem>
                      <SelectItem value="ICD">ICD</SelectItem>
                      <SelectItem value="Stent">Stent</SelectItem>
                      <SelectItem value="Sonstiges Implantat">Sonstiges Implantat</SelectItem>
                      <SelectItem value="Allergiepass">Allergiepass</SelectItem>
                      <SelectItem value="Diabetikerausweis">Diabetikerausweis</SelectItem>
                      <SelectItem value="Marcumar-Pass">Marcumar-Pass</SelectItem>
                      <SelectItem value="Mutterpass">Mutterpass</SelectItem>
                      <SelectItem value="Sonstiger Pass">Sonstiger Pass</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Bezeichnung *</Label>
                  <Input
                    value={passFormData.title}
                    onChange={(e) => setPassFormData({...passFormData, title: e.target.value})}
                    placeholder="z.B. Herzschrittmacher Modell XY"
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Implantationsdatum</Label>
                  <Input
                    type="date"
                    value={passFormData.date_implanted}
                    onChange={(e) => setPassFormData({...passFormData, date_implanted: e.target.value})}
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Hersteller</Label>
                  <Input
                    value={passFormData.manufacturer}
                    onChange={(e) => setPassFormData({...passFormData, manufacturer: e.target.value})}
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Modell</Label>
                  <Input
                    value={passFormData.model}
                    onChange={(e) => setPassFormData({...passFormData, model: e.target.value})}
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Material</Label>
                  <Input
                    value={passFormData.material}
                    onChange={(e) => setPassFormData({...passFormData, material: e.target.value})}
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Seriennummer</Label>
                  <Input
                    value={passFormData.serial_number}
                    onChange={(e) => setPassFormData({...passFormData, serial_number: e.target.value})}
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label>Notizen</Label>
                  <Textarea
                    value={passFormData.notes}
                    onChange={(e) => setPassFormData({...passFormData, notes: e.target.value})}
                    rows={2}
                    className="mt-1"
                  />
                </div>
                <div className="flex gap-3">
                  <Button onClick={resetPassForm} variant="outline" className="flex-1">
                    Abbrechen
                  </Button>
                  <Button onClick={handleSavePass} className="flex-1 bg-indigo-600">
                    Speichern
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>

          {healthPasses.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <FileText className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">Noch keine Gesundheitspässe erfasst</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {healthPasses.map((pass) => (
                <Card key={pass.id} className="border-2">
                  <CardContent className="pt-6">
                    <div className="flex justify-between items-start gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <Badge className="bg-indigo-600">{pass.pass_type}</Badge>
                        </div>
                        <h3 className="text-lg font-bold text-gray-900 mb-2">{pass.title}</h3>
                        {pass.date_implanted && (
                          <p className="text-sm text-gray-600">
                            <Calendar className="h-4 w-4 inline mr-1" />
                            {format(new Date(pass.date_implanted), 'dd.MM.yyyy', { locale: de })}
                          </p>
                        )}
                        {pass.manufacturer && (
                          <p className="text-sm text-gray-600">Hersteller: {pass.manufacturer}</p>
                        )}
                        {pass.model && (
                          <p className="text-sm text-gray-600">Modell: {pass.model}</p>
                        )}
                        {pass.serial_number && (
                          <p className="text-sm text-gray-600">Seriennummer: {pass.serial_number}</p>
                        )}
                      </div>
                      <div className="flex gap-2">
                        <Button onClick={() => handleEditPass(pass)} variant="outline" size="sm">
                          Bearbeiten
                        </Button>
                        <Button
                          onClick={() => {
                            if (confirm("Pass wirklich löschen?")) {
                              deletePassMutation.mutate(pass.id);
                            }
                          }}
                          variant="ghost"
                          size="sm"
                        >
                          <Trash2 className="h-4 w-4 text-red-500" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Info Card */}
      <Card className="border-2 border-blue-200 bg-blue-50">
        <CardContent className="pt-6">
          <div className="flex gap-3">
            <Info className="h-5 w-5 text-blue-600 flex-shrink-0" />
            <div className="text-sm text-blue-900">
              <p className="font-semibold mb-1">Hinweis</p>
              <p>
                Die KI-Impfempfehlungen basieren auf den STIKO-Richtlinien und werden automatisch aktualisiert, 
                wenn sich Empfehlungen ändern. Sie werden rechtzeitig über fällige Auffrischungen informiert.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}