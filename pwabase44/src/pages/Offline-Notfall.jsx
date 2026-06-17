import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  AlertCircle,
  WifiOff,
  User,
  Phone,
  Pill,
  AlertTriangle,
  Heart,
  Calendar,
  Mail,
  Clock,
  Shield,
  Info,
  Smartphone,
  Download,
  Loader2
} from "lucide-react";
import { getCachedEmergencyData, checkOnlineStatus } from "@/components/OfflineManager";
import EmergencyQRCode from "@/components/EmergencyQRCode";
import html2canvas from "html2canvas";
import { toast } from "sonner";
import { format } from "date-fns";
import { de } from "date-fns/locale";

/**
 * Offline Emergency Page
 * Displays cached emergency information when offline
 * Always accessible, even without internet connection
 */
export default function OfflineNotfallPage() {
  const [isOnline, setIsOnline] = useState(checkOnlineStatus());
  const [cachedData, setCachedData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [generatingWallpaper, setGeneratingWallpaper] = useState(false);
  const wallpaperRef = React.useRef(null);

  useEffect(() => {
    loadCachedData();

    // Monitor connection status
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const loadCachedData = () => {
    try {
      const data = getCachedEmergencyData();
      setCachedData(data);
      setLoading(false);
    } catch (error) {
      console.error("Failed to load cached data:", error);
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-600"></div>
      </div>
    );
  }

  const hasData = cachedData?.hasCachedData;
  const user = cachedData?.user;
  const profile = cachedData?.emergencyProfile;
  const contacts = cachedData?.contacts || [];
  const medications = cachedData?.medications || [];
  const allergies = cachedData?.allergies || [];

  // Prepare data for QR code
  const qrData = hasData ? {
    name: user?.full_name,
    date_of_birth: user?.date_of_birth,
    blood_type: user?.blood_type,
    allergies: allergies,
    medications: medications,
    contacts: contacts,
    emergency_profile: profile
  } : null;

  const generateLockscreenWallpaper = async () => {
    if (!wallpaperRef.current) return;
    
    setGeneratingWallpaper(true);
    toast.info("Erstelle Sperrbildschirm-Hintergrund...");

    try {
      // Wait for rendering
      await new Promise(resolve => setTimeout(resolve, 100));

      const canvas = await html2canvas(wallpaperRef.current, {
        scale: 2, // High resolution
        useCORS: true,
        backgroundColor: "#111111", // Dark background for battery saving/OLED
      });

      const image = canvas.toDataURL("image/png");
      
      // Download
      const link = document.createElement("a");
      link.href = image;
      link.download = `notfall-sperrbildschirm-${user?.full_name || 'patient'}.png`;
      link.click();
      
      toast.success("Hintergrundbild heruntergeladen! In Fotos öffnen und als Hintergrund setzen.");
    } catch (error) {
      console.error("Wallpaper generation failed:", error);
      toast.error("Fehler beim Erstellen des Bildes");
    } finally {
      setGeneratingWallpaper(false);
    }
  };

  return (
    <div className="p-6 space-y-6 pb-24">
      {/* Header with Status */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Shield className="h-7 w-7 text-red-600" />
            Offline-Notfalldaten
          </h1>
          <p className="text-gray-600">Immer verfügbar, auch ohne Internet</p>
        </div>
        <Badge className={isOnline ? "bg-green-600" : "bg-orange-600"}>
          {isOnline ? "Online" : "Offline"}
        </Badge>
      </div>

      {/* Offline Status Banner */}
      {!isOnline && (
        <Card className="border-2 border-orange-200 bg-orange-50">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <WifiOff className="h-5 w-5 text-orange-600 flex-shrink-0" />
              <div>
                <p className="font-semibold text-orange-900 mb-1">
                  Offline-Modus aktiv
                </p>
                <p className="text-sm text-orange-800">
                  Die angezeigten Daten wurden zuletzt am {cachedData?.lastSync ? format(new Date(cachedData.lastSync), 'dd.MM.yyyy HH:mm', { locale: de }) : 'unbekannt'} Uhr synchronisiert.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* No Data Warning */}
      {!hasData && (
        <Card className="border-2 border-red-200 bg-red-50">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <AlertTriangle className="h-5 w-5 text-red-600 flex-shrink-0" />
              <div>
                <p className="font-semibold text-red-900 mb-1">
                  Keine Offline-Daten verfügbar
                </p>
                <p className="text-sm text-red-800">
                  Bitte stellen Sie eine Internetverbindung her, um Ihre Notfalldaten zu synchronisieren.
                  Die Daten werden dann automatisch für den Offline-Zugriff gespeichert.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {hasData && (
        <>
          {/* User Information */}
          {user && (
            <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-indigo-50">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <User className="h-5 w-5 text-blue-600" />
                  Persönliche Daten
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-gray-600">Name</p>
                    <p className="font-semibold text-gray-900">{user.full_name || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-600">Geburtsdatum</p>
                    <p className="font-semibold text-gray-900">
                      {user.date_of_birth ? format(new Date(user.date_of_birth), 'dd.MM.yyyy', { locale: de }) : 'N/A'}
                    </p>
                  </div>
                  {user.blood_type && (
                    <div>
                      <p className="text-xs text-gray-600">Blutgruppe</p>
                      <p className="font-semibold text-red-600">{user.blood_type}</p>
                    </div>
                  )}
                  <div>
                    <p className="text-xs text-gray-600">Geschlecht</p>
                    <p className="font-semibold text-gray-900">{user.gender || 'N/A'}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* AI Emergency Profile */}
          {profile && (
            <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-pink-50">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <AlertCircle className="h-5 w-5 text-purple-600" />
                  KI-Notfallprofil
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {profile.summary && (
                  <div>
                    <p className="text-sm font-semibold text-gray-900 mb-2">Zusammenfassung:</p>
                    <p className="text-sm text-gray-700">{profile.summary}</p>
                  </div>
                )}

                {profile.critical_warnings?.length > 0 && (
                  <div className="p-3 bg-red-100 border-2 border-red-300 rounded-lg">
                    <p className="text-sm font-semibold text-red-900 mb-2 flex items-center gap-2">
                      <AlertTriangle className="h-4 w-4" />
                      Kritische Warnungen:
                    </p>
                    <ul className="space-y-1">
                      {profile.critical_warnings.map((warning, idx) => (
                        <li key={idx} className="text-sm text-red-800">• {warning}</li>
                      ))}
                    </ul>
                  </div>
                )}

                {profile.immediate_actions?.length > 0 && (
                  <div>
                    <p className="text-sm font-semibold text-gray-900 mb-2">Sofortmaßnahmen:</p>
                    <ul className="space-y-1">
                      {profile.immediate_actions.map((action, idx) => (
                        <li key={idx} className="text-sm text-gray-700">✓ {action}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Allergies */}
          {allergies.length > 0 && (
            <Card className="border-2 border-yellow-200 bg-yellow-50">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <AlertCircle className="h-5 w-5 text-yellow-600" />
                  Allergien ({allergies.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {allergies.map((allergy, idx) => (
                    <div key={idx} className="p-3 bg-white rounded-lg border-2 border-yellow-300">
                      <div className="flex items-center justify-between">
                        <p className="font-semibold text-gray-900">{allergy.allergen}</p>
                        <Badge className={
                          allergy.severity === 'Lebensbedrohlich' ? 'bg-red-600' :
                          allergy.severity === 'Schwer' ? 'bg-orange-600' :
                          'bg-yellow-600'
                        }>
                          {allergy.severity}
                        </Badge>
                      </div>
                      {allergy.symptoms && (
                        <p className="text-sm text-gray-600 mt-1">{allergy.symptoms}</p>
                      )}
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Medications */}
          {medications.length > 0 && (
            <Card className="border-2 border-green-200 bg-green-50">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Pill className="h-5 w-5 text-green-600" />
                  Aktuelle Medikamente ({medications.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {medications.map((med, idx) => (
                    <div key={idx} className="p-3 bg-white rounded-lg border-2 border-green-300">
                      <p className="font-semibold text-gray-900">{med.name}</p>
                      <p className="text-sm text-gray-600">
                        {med.dosage} - {med.frequency}
                      </p>
                      {med.reason && (
                        <p className="text-xs text-gray-500 mt-1">Grund: {med.reason}</p>
                      )}
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Emergency Contacts */}
          {contacts.length > 0 && (
            <Card className="border-2 border-red-200 bg-red-50">
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Phone className="h-5 w-5 text-red-600" />
                  Notfallkontakte ({contacts.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {contacts.sort((a, b) => a.priority - b.priority).map((contact, idx) => (
                    <div key={idx} className="p-4 bg-white rounded-lg border-2 border-red-300">
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <p className="font-semibold text-gray-900">{contact.name}</p>
                          <p className="text-sm text-gray-600">{contact.relationship}</p>
                        </div>
                        <Badge className="bg-red-600">Priorität {contact.priority}</Badge>
                      </div>
                      <div className="space-y-1 text-sm">
                        <a href={`tel:${contact.phone}`} className="flex items-center gap-2 text-blue-600 hover:underline">
                          <Phone className="h-4 w-4" />
                          {contact.phone}
                        </a>
                        {contact.email && (
                          <a href={`mailto:${contact.email}`} className="flex items-center gap-2 text-blue-600 hover:underline">
                            <Mail className="h-4 w-4" />
                            {contact.email}
                          </a>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* QR Code */}
          <EmergencyQRCode data={qrData} title="Notfall QR-Code (Offline verfügbar)" />

          {/* Last Sync Info */}
          {cachedData?.lastSync && (
            <Card className="border-2 border-gray-200 bg-gray-50">
              <CardContent className="pt-6">
                <div className="flex gap-3">
                  <Clock className="h-5 w-5 text-gray-600 flex-shrink-0" />
                  <div className="text-sm text-gray-700">
                    <p className="font-semibold mb-1">Datenstand</p>
                    <p>
                      Letzte Synchronisation: {format(new Date(cachedData.lastSync), "dd. MMMM yyyy 'um' HH:mm 'Uhr'", { locale: de })}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </>
      )}

      {/* Wallpaper Generator Action */}
      {hasData && (
        <Card className="border-2 border-indigo-200 bg-indigo-50">
          <CardContent className="pt-6">
            <div className="flex flex-col gap-4">
              <div className="flex gap-3">
                <Smartphone className="h-6 w-6 text-indigo-600 flex-shrink-0" />
                <div>
                  <h3 className="font-semibold text-indigo-900">Für den Sperrbildschirm</h3>
                  <p className="text-sm text-indigo-800">
                    Erstellen Sie ein Notfall-Hintergrundbild. So haben Ersthelfer Zugriff auf Ihre Daten, 
                    ohne Ihr Handy entsperren zu müssen.
                  </p>
                </div>
              </div>
              <Button 
                onClick={generateLockscreenWallpaper} 
                disabled={generatingWallpaper}
                className="w-full bg-indigo-600 hover:bg-indigo-700"
              >
                {generatingWallpaper ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Generiere Bild...
                  </>
                ) : (
                  <>
                    <Download className="h-4 w-4 mr-2" />
                    Als Hintergrundbild speichern
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Hidden Wallpaper Template */}
      <div className="fixed top-0 left-0 w-[1080px] h-[1920px] z-[-50] pointer-events-none opacity-0">
        <div 
          ref={wallpaperRef}
          className="w-full h-full bg-slate-900 text-white p-12 flex flex-col items-center justify-center gap-8 font-sans"
          style={{ 
            background: 'linear-gradient(180deg, #0f172a 0%, #1e293b 100%)',
          }}
        >
          {/* Header */}
          <div className="text-center space-y-4 mb-8">
            <div className="flex items-center justify-center gap-4 text-red-500 mb-4">
              <AlertTriangle className="h-24 w-24" />
            </div>
            <h1 className="text-7xl font-black tracking-tight text-red-500 uppercase">NOTFALL</h1>
            <h2 className="text-4xl font-bold text-white mt-4">Medizinische Informationen</h2>
          </div>

          {/* User Info */}
          {user && (
            <div className="bg-slate-800/80 p-8 rounded-3xl w-full border-4 border-slate-700 shadow-2xl">
              <div className="text-center border-b-4 border-slate-600 pb-6 mb-6">
                <p className="text-5xl font-bold text-white mb-2">{user.full_name}</p>
                <p className="text-3xl text-slate-300">
                  {user.date_of_birth && `Geb: ${format(new Date(user.date_of_birth), 'dd.MM.yyyy', { locale: de })}`}
                  {user.blood_type && ` • Blutgruppe: ${user.blood_type}`}
                </p>
              </div>

              <div className="grid gap-6">
                {allergies.length > 0 && (
                  <div className="bg-red-900/40 p-6 rounded-2xl border-l-8 border-red-500">
                    <p className="text-2xl font-bold text-red-400 mb-2 uppercase">⚠️ Allergien</p>
                    <p className="text-3xl font-medium text-white">
                      {allergies.map(a => a.allergen).join(", ")}
                    </p>
                  </div>
                )}
                
                {medications.length > 0 && (
                  <div className="bg-blue-900/40 p-6 rounded-2xl border-l-8 border-blue-500">
                    <p className="text-2xl font-bold text-blue-400 mb-2 uppercase">💊 Medikamente</p>
                    <p className="text-3xl font-medium text-white">
                      {medications.slice(0, 3).map(m => m.name).join(", ")}
                      {medications.length > 3 && ` (+${medications.length - 3})`}
                    </p>
                  </div>
                )}

                {profile?.critical_warnings && profile.critical_warnings.length > 0 && (
                  <div className="bg-orange-900/40 p-6 rounded-2xl border-l-8 border-orange-500">
                    <p className="text-2xl font-bold text-orange-400 mb-2 uppercase">⚡ Wichtig</p>
                    <ul className="text-2xl font-medium text-white list-disc list-inside">
                      {profile.critical_warnings.slice(0, 2).map((w, i) => (
                        <li key={i}>{w.warning}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Emergency Contacts */}
          {contacts.length > 0 && (
            <div className="w-full space-y-4">
              <p className="text-3xl font-bold text-slate-400 uppercase tracking-widest text-center mb-4">Notfallkontakte</p>
              {contacts.slice(0, 2).map((c, i) => (
                <div key={i} className="bg-white text-slate-900 p-6 rounded-2xl flex items-center justify-between">
                  <div>
                    <p className="text-3xl font-bold">{c.name}</p>
                    <p className="text-2xl text-slate-600">{c.relationship}</p>
                  </div>
                  <p className="text-4xl font-mono font-bold">{c.phone}</p>
                </div>
              ))}
            </div>
          )}

          {/* Footer with QR Code Placeholder or Text */}
          <div className="mt-8 text-center text-slate-500">
            <p className="text-2xl">Scannen für vollständiges Profil</p>
            <p className="text-xl mt-2">Gesundheit Plus App</p>
          </div>
        </div>
      </div>

      {/* Info Box */}
      <Card className="border-2 border-blue-200 bg-blue-50">
        <CardContent className="pt-6">
          <div className="flex gap-3">
            <Info className="h-5 w-5 text-blue-600 flex-shrink-0" />
            <div className="text-sm text-blue-900">
              <p className="font-semibold mb-2">Hinweis zur Offline-Funktionalität</p>
              <ul className="space-y-1 text-xs">
                <li>• Diese Seite ist jederzeit verfügbar, auch ohne Internet</li>
                <li>• Daten werden automatisch synchronisiert, wenn Sie online sind</li>
                <li>• Der QR-Code kann offline gescannt werden</li>
                <li>• Drucken Sie den QR-Code aus und bewahren Sie ihn im Portemonnaie auf</li>
                <li>• Für Aktualisierungen stellen Sie bitte eine Internetverbindung her</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Actions */}
      {isOnline && (
        <div className="grid grid-cols-2 gap-3">
          <Button
            onClick={() => window.location.href = "/Notfall-Einrichtung"}
            variant="outline"
            className="w-full"
          >
            Daten bearbeiten
          </Button>
          <Button
            onClick={() => window.location.reload()}
            className="w-full bg-green-600 hover:bg-green-700"
          >
            Neu synchronisieren
          </Button>
        </div>
      )}
    </div>
  );
}