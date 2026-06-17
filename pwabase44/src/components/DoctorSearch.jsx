import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Search, MapPin, Phone, Navigation, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";

export default function DoctorSearch({ onSelectDoctor }) {
  const [searchQuery, setSearchQuery] = useState("");
  const [isSearching, setIsSearching] = useState(false);
  const [results, setResults] = useState([]);
  const [userLocation, setUserLocation] = useState(null);

  const getUserLocation = () => {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error("Geolocation wird nicht unterstützt"));
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          const location = {
            lat: position.coords.latitude,
            lng: position.coords.longitude
          };
          setUserLocation(location);
          resolve(location);
        },
        (error) => {
          reject(error);
        }
      );
    });
  };

  const searchDoctors = async () => {
    if (!searchQuery.trim()) {
      toast.error("Bitte geben Sie eine Fachrichtung ein");
      return;
    }

    setIsSearching(true);

    try {
      let location = userLocation;
      
      if (!location) {
        toast.info("Standort wird ermittelt...");
        try {
          location = await getUserLocation();
        } catch (error) {
          toast.warning("Standort konnte nicht ermittelt werden. Suche ohne Entfernung.");
        }
      }

      const searchPrompt = location 
        ? `Finde Ärzte mit der Fachrichtung "${searchQuery}" in der Nähe von Koordinaten ${location.lat}, ${location.lng} in Deutschland. Gib eine Liste mit Name, Adresse, Telefon und ungefährer Entfernung zurück.`
        : `Finde Ärzte mit der Fachrichtung "${searchQuery}" in Deutschland. Gib eine Liste mit Name, Adresse und Telefon zurück.`;

      const response = await base44.integrations.Core.InvokeLLM({
        prompt: searchPrompt,
        add_context_from_internet: true,
        response_json_schema: {
          type: "object",
          properties: {
            doctors: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  specialty: { type: "string" },
                  address: { type: "string" },
                  phone: { type: "string" },
                  distance: { type: "string" },
                  opening_hours: { type: "string" }
                }
              }
            }
          }
        }
      });

      if (response.doctors && response.doctors.length > 0) {
        setResults(response.doctors);
        toast.success(`${response.doctors.length} Ärzte gefunden`);
      } else {
        setResults([]);
        toast.info("Keine Ärzte gefunden");
      }
    } catch (error) {
      toast.error("Fehler bei der Suche");
      console.error(error);
    } finally {
      setIsSearching(false);
    }
  };

  const handleSelectDoctor = (doctor) => {
    onSelectDoctor({
      name: doctor.name,
      specialty: doctor.specialty || searchQuery,
      address: doctor.address,
      phone: doctor.phone,
      opening_hours: doctor.opening_hours
    });
    toast.success("Arzt übernommen");
  };

  return (
    <Card className="border-2 bg-gradient-to-br from-green-50 to-blue-50">
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          <Search className="h-5 w-5" />
          Facharzt-Suche
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-2">
          <Input
            placeholder="z.B. Kardiologe, Orthopäde..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && searchDoctors()}
            className="flex-1"
          />
          <Button 
            onClick={searchDoctors} 
            disabled={isSearching}
            className="bg-green-600 hover:bg-green-700"
          >
            {isSearching ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : (
              <>
                <Search className="h-5 w-5 mr-2" />
                Suchen
              </>
            )}
          </Button>
        </div>

        {userLocation && (
          <div className="flex items-center gap-2 text-sm text-gray-600">
            <Navigation className="h-4 w-4 text-green-600" />
            <span>Standort aktiviert - Suche mit Entfernung</span>
          </div>
        )}

        {results.length > 0 && (
          <div className="space-y-3 max-h-96 overflow-y-auto">
            <p className="text-sm font-semibold text-gray-700">
              {results.length} Ergebnisse:
            </p>
            {results.map((doctor, index) => (
              <Card key={index} className="border hover:shadow-md transition-shadow">
                <CardContent className="p-4">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <h4 className="font-bold text-gray-900">{doctor.name}</h4>
                      <p className="text-sm text-gray-600">{doctor.specialty}</p>
                    </div>
                    {doctor.distance && (
                      <div className="flex items-center gap-1 text-sm text-blue-600">
                        <MapPin className="h-3 w-3" />
                        <span>{doctor.distance}</span>
                      </div>
                    )}
                  </div>
                  
                  {doctor.address && (
                    <div className="flex items-start gap-2 text-sm text-gray-700 mb-1">
                      <MapPin className="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0" />
                      <span>{doctor.address}</span>
                    </div>
                  )}
                  
                  {doctor.phone && (
                    <div className="flex items-center gap-2 text-sm text-gray-700 mb-2">
                      <Phone className="h-4 w-4 text-gray-400" />
                      <a href={`tel:${doctor.phone}`} className="text-blue-600 hover:underline">
                        {doctor.phone}
                      </a>
                    </div>
                  )}

                  {doctor.opening_hours && (
                    <p className="text-xs text-gray-500 mb-2">{doctor.opening_hours}</p>
                  )}

                  <Button 
                    onClick={() => handleSelectDoctor(doctor)}
                    size="sm"
                    variant="outline"
                    className="w-full"
                  >
                    Zu meinen Ärzten hinzufügen
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-xs text-blue-800">
            <strong>Tipp:</strong> Aktivieren Sie Ihren Standort, um Ärzte in Ihrer Nähe mit Entfernungsangabe zu finden.
          </p>
        </div>
      </CardContent>
    </Card>
  );
}