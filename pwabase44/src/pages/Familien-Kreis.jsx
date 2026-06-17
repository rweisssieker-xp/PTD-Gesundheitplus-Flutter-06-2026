import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import {
  Users,
  CheckCircle,
  AlertCircle,
  Clock,
  Heart,
  MapPin,
  Bell,
  Plus,
  Send,
  RefreshCw,
  Loader2,
  ShieldCheck,
  HelpCircle
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { formatDistanceToNow } from "date-fns";
import { de } from "date-fns/locale";

const STATUS_CONFIG = {
  safe: {
    label: "Bin sicher",
    icon: CheckCircle,
    color: "bg-green-100 text-green-800 border-green-200",
    btnColor: "bg-green-600 hover:bg-green-700",
    cardBorder: "border-green-200",
    bg: "bg-green-50"
  },
  help_needed: {
    label: "Brauche Hilfe",
    icon: AlertCircle,
    color: "bg-red-100 text-red-800 border-red-200",
    btnColor: "bg-red-600 hover:bg-red-700",
    cardBorder: "border-red-200",
    bg: "bg-red-50"
  },
  unknown: {
    label: "Unbekannt",
    icon: HelpCircle,
    color: "bg-gray-100 text-gray-800 border-gray-200",
    btnColor: "bg-gray-500 hover:bg-gray-600",
    cardBorder: "border-gray-200",
    bg: "bg-gray-50"
  }
};

export default function FamilienKreisPage() {
  const queryClient = useQueryClient();
  const [user, setUser] = useState(null);
  const [checkInMessage, setCheckInMessage] = useState("");
  const [locationText, setLocationText] = useState("");
  const [showCheckInForm, setShowCheckInForm] = useState(false);
  const [pendingStatus, setPendingStatus] = useState(null);
  const [isGettingLocation, setIsGettingLocation] = useState(false);

  const { data: checkIns = [], isLoading } = useQuery({
    queryKey: ["family-checkins"],
    queryFn: () => base44.entities.FamilyCheckIn.list("-checked_in_at", 50),
    refetchInterval: 30000 // Refresh every 30s
  });

  useEffect(() => {
    base44.auth.me().then(setUser).catch(() => {});
  }, []);

  const checkInMutation = useMutation({
    mutationFn: (data) => base44.entities.FamilyCheckIn.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["family-checkins"] });
      setCheckInMessage("");
      setLocationText("");
      setShowCheckInForm(false);
      setPendingStatus(null);
      toast.success("Check-in gesendet!");
    },
    onError: () => toast.error("Fehler beim Check-in")
  });

  const handleGetLocation = () => {
    if (!navigator.geolocation) {
      toast.error("Standort nicht verfügbar");
      return;
    }
    setIsGettingLocation(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLocationText(`${pos.coords.latitude.toFixed(4)}, ${pos.coords.longitude.toFixed(4)}`);
        setIsGettingLocation(false);
        toast.success("Standort erfasst");
      },
      () => {
        setIsGettingLocation(false);
        toast.error("Standort konnte nicht ermittelt werden");
      }
    );
  };

  const handleStatusClick = (status) => {
    setPendingStatus(status);
    setShowCheckInForm(true);
  };

  const handleSubmitCheckIn = () => {
    if (!pendingStatus) return;
    checkInMutation.mutate({
      user_name: user?.full_name || "Unbekannt",
      user_email: user?.email || "",
      status: pendingStatus,
      message: checkInMessage,
      location_text: locationText,
      checked_in_at: new Date().toISOString(),
      next_checkin_due: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
    });
  };

  // Get latest check-in per person
  const latestByPerson = checkIns.reduce((acc, c) => {
    const key = c.user_email || c.user_name;
    if (!acc[key] || new Date(c.checked_in_at) > new Date(acc[key].checked_in_at)) {
      acc[key] = c;
    }
    return acc;
  }, {});
  const memberStatuses = Object.values(latestByPerson);

  const safeCount = memberStatuses.filter(m => m.status === "safe").length;
  const helpCount = memberStatuses.filter(m => m.status === "help_needed").length;
  const unknownCount = memberStatuses.filter(m => m.status === "unknown").length;

  return (
    <div className="p-6 space-y-6 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-1 flex items-center gap-2">
          <Users className="h-7 w-7 text-blue-600" />
          Familien-Sicherheitskreis
        </h1>
        <p className="text-gray-600">Status-Updates und "Bin sicher"-Check-ins für Ihre Familie</p>
      </div>

      {/* Summary Card */}
      <div className="grid grid-cols-3 gap-3">
        <Card className="border-2 border-green-200 bg-green-50 text-center">
          <CardContent className="pt-4 pb-4">
            <p className="text-3xl font-bold text-green-700">{safeCount}</p>
            <p className="text-xs text-green-600 font-semibold mt-1">Sicher</p>
          </CardContent>
        </Card>
        <Card className="border-2 border-red-200 bg-red-50 text-center">
          <CardContent className="pt-4 pb-4">
            <p className="text-3xl font-bold text-red-700">{helpCount}</p>
            <p className="text-xs text-red-600 font-semibold mt-1">Hilfe benötigt</p>
          </CardContent>
        </Card>
        <Card className="border-2 border-gray-200 bg-gray-50 text-center">
          <CardContent className="pt-4 pb-4">
            <p className="text-3xl font-bold text-gray-700">{unknownCount}</p>
            <p className="text-xs text-gray-600 font-semibold mt-1">Unbekannt</p>
          </CardContent>
        </Card>
      </div>

      {/* My Check-In */}
      <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-indigo-50">
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <Heart className="h-5 w-5 text-blue-600" />
            Mein Status senden
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <Button
              onClick={() => handleStatusClick("safe")}
              className="h-14 bg-green-600 hover:bg-green-700 text-white"
            >
              <CheckCircle className="h-5 w-5 mr-2" />
              <div className="text-left">
                <div className="font-bold text-sm">Bin sicher</div>
                <div className="text-xs opacity-80">Alles OK</div>
              </div>
            </Button>
            <Button
              onClick={() => handleStatusClick("help_needed")}
              className="h-14 bg-red-600 hover:bg-red-700 text-white"
            >
              <AlertCircle className="h-5 w-5 mr-2" />
              <div className="text-left">
                <div className="font-bold text-sm">Brauche Hilfe</div>
                <div className="text-xs opacity-80">Sofort kontaktieren</div>
              </div>
            </Button>
          </div>

          {showCheckInForm && (
            <div className="space-y-3 p-4 bg-white rounded-xl border-2 border-blue-200">
              <p className="font-semibold text-gray-900">
                Status: <span className={`px-2 py-0.5 rounded text-sm ${pendingStatus === 'safe' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                  {STATUS_CONFIG[pendingStatus]?.label}
                </span>
              </p>
              <Textarea
                placeholder="Optionale Nachricht (z.B. 'Bin beim Arzt')"
                value={checkInMessage}
                onChange={(e) => setCheckInMessage(e.target.value)}
                rows={2}
                className="text-sm"
              />
              <div className="flex gap-2">
                <Input
                  placeholder="Standort (optional)"
                  value={locationText}
                  onChange={(e) => setLocationText(e.target.value)}
                  className="text-sm"
                />
                <Button
                  onClick={handleGetLocation}
                  variant="outline"
                  size="sm"
                  disabled={isGettingLocation}
                >
                  {isGettingLocation ? <Loader2 className="h-4 w-4 animate-spin" /> : <MapPin className="h-4 w-4" />}
                </Button>
              </div>
              <div className="flex gap-2">
                <Button
                  onClick={handleSubmitCheckIn}
                  disabled={checkInMutation.isPending}
                  className={`flex-1 ${STATUS_CONFIG[pendingStatus]?.btnColor}`}
                >
                  {checkInMutation.isPending ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <Send className="h-4 w-4 mr-2" />}
                  Senden
                </Button>
                <Button variant="outline" onClick={() => setShowCheckInForm(false)}>Abbrechen</Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Family Members Status */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold text-gray-900">Familienmitglieder</h2>
          <Button
            variant="outline"
            size="sm"
            onClick={() => queryClient.invalidateQueries({ queryKey: ["family-checkins"] })}
          >
            <RefreshCw className="h-4 w-4 mr-1" />
            Aktualisieren
          </Button>
        </div>

        {isLoading ? (
          <div className="text-center py-8">
            <Loader2 className="h-8 w-8 animate-spin text-blue-600 mx-auto" />
          </div>
        ) : memberStatuses.length === 0 ? (
          <Card className="border-2 border-dashed border-gray-300">
            <CardContent className="py-12 text-center">
              <Users className="h-12 w-12 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500 font-medium">Noch keine Check-ins</p>
              <p className="text-sm text-gray-400 mt-1">Senden Sie Ihren ersten Status-Check-in</p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-3">
            {memberStatuses
              .sort((a, b) => {
                const order = { help_needed: 0, unknown: 1, safe: 2 };
                return (order[a.status] ?? 3) - (order[b.status] ?? 3);
              })
              .map((member) => {
                const cfg = STATUS_CONFIG[member.status] || STATUS_CONFIG.unknown;
                const StatusIcon = cfg.icon;
                const isOverdue = member.next_checkin_due && new Date(member.next_checkin_due) < new Date();
                return (
                  <Card key={member.id} className={`border-2 ${cfg.cardBorder} ${cfg.bg}`}>
                    <CardContent className="pt-4 pb-4">
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex items-start gap-3 flex-1">
                          <div className={`h-12 w-12 rounded-full flex items-center justify-center border-2 ${cfg.color}`}>
                            <StatusIcon className="h-6 w-6" />
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center gap-2 flex-wrap">
                              <p className="font-bold text-gray-900">{member.user_name}</p>
                              <Badge className={`text-xs ${cfg.color}`}>{cfg.label}</Badge>
                              {isOverdue && (
                                <Badge className="text-xs bg-orange-100 text-orange-800 border border-orange-200">
                                  <Clock className="h-3 w-3 mr-1" />
                                  Überfällig
                                </Badge>
                              )}
                            </div>
                            {member.message && (
                              <p className="text-sm text-gray-700 mt-1 italic">"{member.message}"</p>
                            )}
                            {member.location_text && (
                              <p className="text-xs text-gray-600 mt-1 flex items-center gap-1">
                                <MapPin className="h-3 w-3" />
                                {member.location_text}
                              </p>
                            )}
                            <p className="text-xs text-gray-500 mt-1 flex items-center gap-1">
                              <Clock className="h-3 w-3" />
                              {member.checked_in_at
                                ? formatDistanceToNow(new Date(member.checked_in_at), { addSuffix: true, locale: de })
                                : "Unbekannt"}
                            </p>
                          </div>
                        </div>
                        {member.status === "help_needed" && member.user_email && (
                          <a href={`mailto:${member.user_email}`}>
                            <Button size="sm" className="bg-red-600 hover:bg-red-700 text-white">
                              Kontaktieren
                            </Button>
                          </a>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
          </div>
        )}
      </div>

      {/* How it works */}
      <Card className="border-2 border-purple-200 bg-purple-50">
        <CardContent className="pt-5 pb-5">
          <div className="flex gap-3">
            <ShieldCheck className="h-5 w-5 text-purple-600 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-purple-900 space-y-1">
              <p className="font-semibold">So funktioniert der Sicherheitskreis</p>
              <ul className="text-xs space-y-1 mt-2 text-purple-800">
                <li>• Jedes Familienmitglied öffnet die App und sendet einen Status</li>
                <li>• Alle sehen den Status aller Mitglieder in Echtzeit</li>
                <li>• Bei "Brauche Hilfe" wird der Kontakt direkt angezeigt</li>
                <li>• Überfällige Check-ins werden automatisch markiert</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}