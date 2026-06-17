import React, { useState, useEffect } from "react";
import { WifiOff, Wifi, AlertTriangle, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { checkOnlineStatus, syncEmergencyData, getCachedEmergencyData } from "./OfflineManager";
import { toast } from "sonner";
import { format } from "date-fns";
import { de } from "date-fns/locale";

/**
 * Offline Indicator Component
 * Shows connection status and allows manual sync
 */
export default function OfflineIndicator() {
  const [isOnline, setIsOnline] = useState(checkOnlineStatus());
  const [showDetails, setShowDetails] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const [cachedData, setCachedData] = useState(null);

  useEffect(() => {
    // Load cached data info
    const data = getCachedEmergencyData();
    setCachedData(data);

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

  const handleManualSync = async () => {
    if (!isOnline) {
      toast.error("Keine Internetverbindung", {
        description: "Synchronisation nicht möglich"
      });
      return;
    }

    setIsSyncing(true);
    try {
      const result = await syncEmergencyData();
      if (result.success) {
        toast.success("Notfalldaten synchronisiert");
        const data = getCachedEmergencyData();
        setCachedData(data);
      } else {
        toast.error("Synchronisation fehlgeschlagen");
      }
    } catch (error) {
      toast.error("Fehler bei der Synchronisation");
    } finally {
      setIsSyncing(false);
    }
  };

  // Only show when offline or when user wants to see details
  if (isOnline && !showDetails) {
    return (
      <button
        onClick={() => setShowDetails(!showDetails)}
        className="fixed bottom-6 right-6 z-50 h-10 w-10 rounded-full bg-green-500 shadow-lg flex items-center justify-center hover:bg-green-600 transition-colors"
      >
        <Wifi className="h-5 w-5 text-white" />
      </button>
    );
  }

  return (
    <>
      {/* Floating indicator button */}
      <button
        onClick={() => setShowDetails(!showDetails)}
        className={`fixed bottom-6 right-6 z-50 h-12 w-12 rounded-full shadow-lg flex items-center justify-center transition-all ${
          isOnline ? 'bg-green-500 hover:bg-green-600' : 'bg-orange-500 hover:bg-orange-600 animate-pulse'
        }`}
      >
        {isOnline ? (
          <Wifi className="h-6 w-6 text-white" />
        ) : (
          <WifiOff className="h-6 w-6 text-white" />
        )}
      </button>

      {/* Details panel */}
      {showDetails && (
        <div className="fixed bottom-24 right-6 z-50 w-80 animate-in slide-in-from-bottom">
          <Card className={`border-2 ${isOnline ? 'border-green-200 bg-green-50' : 'border-orange-200 bg-orange-50'} shadow-2xl`}>
            <CardContent className="pt-6">
              <div className="space-y-4">
                {/* Status Header */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {isOnline ? (
                      <Wifi className="h-5 w-5 text-green-600" />
                    ) : (
                      <WifiOff className="h-5 w-5 text-orange-600" />
                    )}
                    <span className={`font-semibold ${isOnline ? 'text-green-900' : 'text-orange-900'}`}>
                      {isOnline ? 'Online' : 'Offline-Modus'}
                    </span>
                  </div>
                  <button
                    onClick={() => setShowDetails(false)}
                    className="text-gray-500 hover:text-gray-700"
                  >
                    ✕
                  </button>
                </div>

                {/* Offline Warning */}
                {!isOnline && (
                  <div className="flex gap-2 p-3 bg-orange-100 border border-orange-300 rounded-lg">
                    <AlertTriangle className="h-5 w-5 text-orange-600 flex-shrink-0 mt-0.5" />
                    <div className="text-sm text-orange-900">
                      <p className="font-semibold mb-1">Eingeschränkter Modus</p>
                      <p className="text-xs">
                        Notfalldaten sind weiterhin verfügbar. Neue Daten können nicht gespeichert werden.
                      </p>
                    </div>
                  </div>
                )}

                {/* Cached Data Info */}
                {cachedData?.hasCachedData && (
                  <div className="space-y-2">
                    <p className="text-sm font-semibold text-gray-900">Verfügbare Offline-Daten:</p>
                    <ul className="text-xs space-y-1 text-gray-700">
                      {cachedData.user && (
                        <li>✓ Benutzerprofil</li>
                      )}
                      {cachedData.emergencyProfile && (
                        <li>✓ KI-Notfallprofil</li>
                      )}
                      {cachedData.contacts?.length > 0 && (
                        <li>✓ {cachedData.contacts.length} Notfallkontakt(e)</li>
                      )}
                      {cachedData.medications?.length > 0 && (
                        <li>✓ {cachedData.medications.length} Medikament(e)</li>
                      )}
                      {cachedData.allergies?.length > 0 && (
                        <li>✓ {cachedData.allergies.length} Allergie(n)</li>
                      )}
                    </ul>
                    {cachedData.lastSync && (
                      <p className="text-xs text-gray-500 mt-2">
                        Letzte Synchronisation: {format(new Date(cachedData.lastSync), 'dd.MM.yyyy HH:mm', { locale: de })} Uhr
                      </p>
                    )}
                  </div>
                )}

                {/* No cached data warning */}
                {!cachedData?.hasCachedData && (
                  <div className="flex gap-2 p-3 bg-red-100 border border-red-300 rounded-lg">
                    <AlertTriangle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
                    <div className="text-sm text-red-900">
                      <p className="font-semibold mb-1">Keine Offline-Daten</p>
                      <p className="text-xs">
                        Bitte stellen Sie eine Internetverbindung her, um Notfalldaten zu speichern.
                      </p>
                    </div>
                  </div>
                )}

                {/* Sync Button */}
                {isOnline && (
                  <Button
                    onClick={handleManualSync}
                    disabled={isSyncing}
                    className="w-full bg-green-600 hover:bg-green-700"
                    size="sm"
                  >
                    {isSyncing ? (
                      <>
                        <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                        Synchronisiere...
                      </>
                    ) : (
                      <>
                        <RefreshCw className="h-4 w-4 mr-2" />
                        Jetzt synchronisieren
                      </>
                    )}
                  </Button>
                )}

                {/* Offline Access Button */}
                <Button
                  onClick={() => {
                    window.location.href = "/Offline-Notfall";
                    setShowDetails(false);
                  }}
                  variant="outline"
                  className="w-full"
                  size="sm"
                >
                  Notfalldaten anzeigen
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </>
  );
}