/**
 * Live Location Tracker Component
 * Continuously tracks and sends location updates during emergency
 */

import React, { useState, useEffect, useRef } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { MapPin, StopCircle, Activity, CheckCircle, AlertCircle, Clock, Users } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";
import { Progress } from "@/components/ui/progress";

export default function LiveLocationTracker({ 
  trackingId, 
  contacts, 
  initialMessage,
  durationMinutes = 30,
  updateIntervalSeconds = 60,
  onStop 
}) {
  const [isTracking, setIsTracking] = useState(true);
  const [currentLocation, setCurrentLocation] = useState(null);
  const [updatesSent, setUpdatesSent] = useState(0);
  const [timeElapsed, setTimeElapsed] = useState(0);
  const [lastUpdateTime, setLastUpdateTime] = useState(null);
  const [trackingData, setTrackingData] = useState(null);
  
  const watchIdRef = useRef(null);
  const updateIntervalRef = useRef(null);
  const timerIntervalRef = useRef(null);

  useEffect(() => {
    startTracking();
    return () => stopTracking();
  }, []);

  const startTracking = async () => {
    // Create tracking record
    const tracking = await base44.entities.EmergencyTracking.create({
      tracking_id: trackingId,
      status: 'active',
      start_time: new Date().toISOString(),
      duration_minutes: durationMinutes,
      update_interval_seconds: updateIntervalSeconds,
      emergency_message: initialMessage,
      contacts_notified: contacts.map(c => c.id),
      location_history: [],
      updates_sent: 0
    });

    setTrackingData(tracking);

    // Start continuous location tracking
    if (navigator.geolocation) {
      watchIdRef.current = navigator.geolocation.watchPosition(
        (position) => {
          const location = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy,
            speed: position.coords.speed,
            heading: position.coords.heading,
            timestamp: new Date().toISOString()
          };
          
          setCurrentLocation(location);
          updateTrackingHistory(location);
        },
        (error) => {
          console.error('Location error:', error);
          toast.error('Standortverfolgung fehlgeschlagen', {
            description: error.message
          });
        },
        {
          enableHighAccuracy: true,
          maximumAge: 5000,
          timeout: 10000
        }
      );

      // Send updates at regular intervals
      updateIntervalRef.current = setInterval(() => {
        sendLocationUpdate();
      }, updateIntervalSeconds * 1000);

      // Update elapsed time every second
      timerIntervalRef.current = setInterval(() => {
        setTimeElapsed(prev => {
          const newTime = prev + 1;
          // Auto-stop after duration
          if (newTime >= durationMinutes * 60) {
            stopTracking('completed');
          }
          return newTime;
        });
      }, 1000);
    }
  };

  const updateTrackingHistory = async (location) => {
    if (!trackingData) return;

    try {
      const currentHistory = trackingData.location_history || [];
      await base44.entities.EmergencyTracking.update(trackingData.id, {
        location_history: [...currentHistory, location],
        last_update_time: new Date().toISOString()
      });
    } catch (error) {
      console.error('Failed to update history:', error);
    }
  };

  const sendLocationUpdate = async () => {
    if (!currentLocation || !isTracking) return;

    try {
      const user = await base44.auth.me();
      
      // Call backend function for location update
      const result = await base44.functions.sendLocationUpdate({
        contacts: contacts,
        location: currentLocation,
        trackingId: trackingId,
        userName: user.full_name || 'Patient',
        message: initialMessage
      });

      if (result.success) {
        const newCount = updatesSent + 1;
        setUpdatesSent(newCount);
        setLastUpdateTime(new Date());

        // Update tracking record
        if (trackingData) {
          await base44.entities.EmergencyTracking.update(trackingData.id, {
            updates_sent: newCount,
            last_update_time: new Date().toISOString()
          });
        }

        toast.success('Standort-Update gesendet', {
          description: `${result.results.sms.sent + result.results.telegram.sent + result.results.whatsapp.sent} Benachrichtigungen`
        });
      }
    } catch (error) {
      console.error('Update error:', error);
      toast.error('Update fehlgeschlagen');
    }
  };

  const stopTracking = async (reason = 'stopped') => {
    setIsTracking(false);

    // Clear intervals
    if (watchIdRef.current) {
      navigator.geolocation.clearWatch(watchIdRef.current);
    }
    if (updateIntervalRef.current) {
      clearInterval(updateIntervalRef.current);
    }
    if (timerIntervalRef.current) {
      clearInterval(timerIntervalRef.current);
    }

    // Update tracking record
    if (trackingData) {
      await base44.entities.EmergencyTracking.update(trackingData.id, {
        status: reason,
        end_time: new Date().toISOString(),
        stopped_by_user: reason === 'stopped'
      });
    }

    // Send final notification
    if (currentLocation) {
      try {
        const user = await base44.auth.me();
        await base44.functions.sendLocationUpdate({
          contacts: contacts,
          location: currentLocation,
          trackingId: trackingId,
          userName: user.full_name || 'Patient',
          message: '✅ Live-Tracking beendet'
        });
      } catch (error) {
        console.error('Final update error:', error);
      }
    }

    toast.success('Live-Tracking beendet');
    
    if (onStop) {
      onStop(reason);
    }
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${String(secs).padStart(2, '0')}`;
  };

  const progressPercent = (timeElapsed / (durationMinutes * 60)) * 100;

  return (
    <Card className="border-2 border-orange-300 bg-gradient-to-br from-orange-50 to-red-50 shadow-xl">
      <CardContent className="pt-6 space-y-4">
        {/* Status Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Activity className="h-6 w-6 text-orange-600 animate-pulse" />
            <div>
              <p className="font-bold text-orange-900">Live-Tracking aktiv</p>
              <p className="text-xs text-orange-700">Kontakte werden informiert</p>
            </div>
          </div>
          <Button
            onClick={() => stopTracking('stopped')}
            variant="destructive"
            size="sm"
            className="gap-2"
          >
            <StopCircle className="h-4 w-4" />
            Stoppen
          </Button>
        </div>

        {/* Progress Bar */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2 text-orange-800">
              <Clock className="h-4 w-4" />
              <span>{formatTime(timeElapsed)} / {durationMinutes} Min</span>
            </div>
            <span className="text-orange-700 font-semibold">
              {Math.round(progressPercent)}%
            </span>
          </div>
          <Progress value={progressPercent} className="h-2" />
        </div>

        {/* Current Location */}
        {currentLocation && (
          <div className="bg-white rounded-lg p-3 border-2 border-orange-200">
            <div className="flex items-start gap-3">
              <MapPin className="h-5 w-5 text-orange-600 flex-shrink-0 mt-0.5" />
              <div className="flex-1 space-y-1">
                <p className="text-sm font-semibold text-gray-900">Aktueller Standort:</p>
                <p className="text-xs text-gray-700 font-mono">
                  {currentLocation.latitude.toFixed(6)}, {currentLocation.longitude.toFixed(6)}
                </p>
                <p className="text-xs text-gray-600">
                  Genauigkeit: ±{Math.round(currentLocation.accuracy)}m
                </p>
                {currentLocation.speed !== null && currentLocation.speed > 0 && (
                  <p className="text-xs text-gray-600">
                    Geschwindigkeit: {(currentLocation.speed * 3.6).toFixed(1)} km/h
                  </p>
                )}
                <a
                  href={`https://maps.google.com/?q=${currentLocation.latitude},${currentLocation.longitude}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-xs text-blue-600 hover:underline inline-flex items-center gap-1"
                >
                  In Google Maps öffnen →
                </a>
              </div>
            </div>
          </div>
        )}

        {/* Statistics */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-white rounded-lg p-3 border-2 border-green-200">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <div>
                <p className="text-xs text-gray-600">Updates gesendet</p>
                <p className="text-2xl font-bold text-gray-900">{updatesSent}</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-lg p-3 border-2 border-blue-200">
            <div className="flex items-center gap-2">
              <Users className="h-5 w-5 text-blue-600" />
              <div>
                <p className="text-xs text-gray-600">Kontakte</p>
                <p className="text-2xl font-bold text-gray-900">{contacts.length}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Last Update */}
        {lastUpdateTime && (
          <div className="flex items-center gap-2 text-xs text-gray-600">
            <CheckCircle className="h-4 w-4 text-green-600" />
            <span>
              Letztes Update: {lastUpdateTime.toLocaleTimeString('de-DE')}
            </span>
          </div>
        )}

        {/* Next Update Countdown */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-xs text-blue-800">
            ⏳ Nächstes Update in ~{updateIntervalSeconds - (timeElapsed % updateIntervalSeconds)} Sek.
          </p>
        </div>

        {/* Info */}
        <div className="flex items-start gap-2 text-xs text-orange-800 bg-orange-100 rounded-lg p-3">
          <AlertCircle className="h-4 w-4 flex-shrink-0 mt-0.5" />
          <p>
            Ihre Kontakte erhalten alle {updateIntervalSeconds} Sekunden automatische Standort-Updates.
            Das Tracking läuft für {durationMinutes} Minuten.
          </p>
        </div>
      </CardContent>
    </Card>
  );
}