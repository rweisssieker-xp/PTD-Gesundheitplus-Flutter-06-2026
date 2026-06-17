import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Shield, Cloud, Smartphone, CheckCircle } from 'lucide-react';
import { useStorage } from '@/lib/StorageContext';

export default function StorageModeSelector({ onSelected }) {
  const { setMode } = useStorage();

  const handleSelect = (mode) => {
    setMode(mode);
    if (onSelected) onSelected(mode);
  };

  return (
    <div className="space-y-4">
      <div className="text-center mb-6">
        <Shield className="h-12 w-12 text-red-600 mx-auto mb-3" />
        <h2 className="text-xl font-bold text-gray-900">Wo sollen Ihre Daten gespeichert werden?</h2>
        <p className="text-gray-500 text-sm mt-1">Diese Entscheidung können Sie später in den Einstellungen ändern.</p>
      </div>

      {/* Local Mode */}
      <Card 
        className="border-2 border-green-200 hover:border-green-500 cursor-pointer transition-all hover:shadow-lg"
        onClick={() => handleSelect('local')}
      >
        <CardHeader className="pb-2">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center">
              <Smartphone className="h-6 w-6 text-green-600" />
            </div>
            <div>
              <CardTitle className="text-lg text-green-800">Nur auf diesem Gerät</CardTitle>
              <p className="text-xs text-green-600 font-semibold">Maximaler Datenschutz</p>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <ul className="text-sm text-gray-700 space-y-1">
            <li className="flex items-center gap-2"><CheckCircle className="h-4 w-4 text-green-500 flex-shrink-0" /> Daten verlassen nie Ihr Gerät</li>
            <li className="flex items-center gap-2"><CheckCircle className="h-4 w-4 text-green-500 flex-shrink-0" /> Kein Server-Zugriff auf Gesundheitsdaten</li>
            <li className="flex items-center gap-2"><CheckCircle className="h-4 w-4 text-green-500 flex-shrink-0" /> Funktioniert komplett offline</li>
          </ul>
          <div className="mt-3 p-2 bg-amber-50 border border-amber-200 rounded text-xs text-amber-700">
            ⚠️ Bei Geräteverlust oder App-Deinstallation gehen Daten verloren. KI-Features haben eingeschränkten Zugriff.
          </div>
          <Button className="w-full mt-4 bg-green-600 hover:bg-green-700" size="lg">
            <Smartphone className="h-5 w-5 mr-2" />
            Lokal speichern wählen
          </Button>
        </CardContent>
      </Card>

      {/* Cloud Mode */}
      <Card 
        className="border-2 border-blue-200 hover:border-blue-500 cursor-pointer transition-all hover:shadow-lg"
        onClick={() => handleSelect('cloud')}
      >
        <CardHeader className="pb-2">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center">
              <Cloud className="h-6 w-6 text-blue-600" />
            </div>
            <div>
              <CardTitle className="text-lg text-blue-800">Cloud-Synchronisation</CardTitle>
              <p className="text-xs text-blue-600 font-semibold">Volle Funktionalität</p>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <ul className="text-sm text-gray-700 space-y-1">
            <li className="flex items-center gap-2"><CheckCircle className="h-4 w-4 text-blue-500 flex-shrink-0" /> Auf allen Geräten verfügbar</li>
            <li className="flex items-center gap-2"><CheckCircle className="h-4 w-4 text-blue-500 flex-shrink-0" /> KI-Coach & alle Features voll verfügbar</li>
            <li className="flex items-center gap-2"><CheckCircle className="h-4 w-4 text-blue-500 flex-shrink-0" /> Automatisches Backup</li>
            <li className="flex items-center gap-2"><CheckCircle className="h-4 w-4 text-blue-500 flex-shrink-0" /> DSGVO-konform, Server in Deutschland</li>
          </ul>
          <Button className="w-full mt-4 bg-blue-600 hover:bg-blue-700" size="lg">
            <Cloud className="h-5 w-5 mr-2" />
            Cloud-Sync wählen
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}