import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Shield, Cloud, Smartphone, Download, Trash2, RefreshCw, AlertTriangle, CheckCircle } from 'lucide-react';
import { useStorage } from '@/lib/StorageContext';
import { exportLocalData, clearLocalData } from '@/lib/storageService';
import { toast } from 'sonner';
import StorageModeSelector from '@/components/StorageModeSelector';

export default function SpeicherModusPage() {
  const { mode, setMode, isLocal, isCloud } = useStorage();
  const [showConfirmSwitch, setShowConfirmSwitch] = useState(null);
  const [showSelector, setShowSelector] = useState(false);

  const handleExportBackup = () => {
    const backup = exportLocalData();
    const blob = new Blob([JSON.stringify(backup, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `gesundheit-plus-backup-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success('Backup heruntergeladen');
  };

  const handleClearLocal = () => {
    if (confirm('Wirklich ALLE lokalen Daten löschen? Dies kann nicht rückgängig gemacht werden!')) {
      clearLocalData();
      toast.success('Lokale Daten gelöscht');
    }
  };

  const handleSwitchMode = (newMode) => {
    setMode(newMode);
    setShowSelector(false);
    setShowConfirmSwitch(null);
    toast.success(newMode === 'local' ? 'Lokaler Modus aktiviert' : 'Cloud-Sync aktiviert');
  };

  if (showSelector) {
    return (
      <div className="p-6">
        <StorageModeSelector onSelected={handleSwitchMode} />
        <Button variant="outline" className="w-full mt-4" onClick={() => setShowSelector(false)}>
          Abbrechen
        </Button>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-4 pb-24">
      <div className="flex items-center gap-3 mb-4">
        <Shield className="h-8 w-8 text-red-600" />
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Speicher-Modus</h1>
          <p className="text-gray-500 text-sm">Datenschutz & Datenspeicherung</p>
        </div>
      </div>

      {/* Current Mode */}
      <Card className={`border-2 ${isLocal ? 'border-green-400 bg-green-50' : 'border-blue-400 bg-blue-50'}`}>
        <CardContent className="pt-5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              {isLocal ? (
                <Smartphone className="h-8 w-8 text-green-600" />
              ) : (
                <Cloud className="h-8 w-8 text-blue-600" />
              )}
              <div>
                <p className="font-semibold text-gray-900">
                  {isLocal ? 'Lokaler Modus aktiv' : isCloud ? 'Cloud-Modus aktiv' : 'Kein Modus gewählt'}
                </p>
                <p className="text-sm text-gray-600">
                  {isLocal ? 'Daten nur auf diesem Gerät' : isCloud ? 'Daten in der Cloud synchronisiert' : 'Bitte Modus wählen'}
                </p>
              </div>
            </div>
            <Badge className={isLocal ? 'bg-green-600' : 'bg-blue-600'}>
              {isLocal ? 'Lokal' : isCloud ? 'Cloud' : 'Offen'}
            </Badge>
          </div>
        </CardContent>
      </Card>

      {/* Switch Mode */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base flex items-center gap-2">
            <RefreshCw className="h-5 w-5" />
            Modus wechseln
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {isLocal && (
            <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg text-sm text-amber-700">
              <AlertTriangle className="h-4 w-4 inline mr-1" />
              Beim Wechsel zu Cloud werden Ihre lokalen Daten <strong>nicht</strong> übertragen.
              Laden Sie zuerst ein Backup herunter!
            </div>
          )}
          {isCloud && (
            <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg text-sm text-blue-700">
              <AlertTriangle className="h-4 w-4 inline mr-1" />
              Beim Wechsel zu lokal werden die Cloud-Daten <strong>nicht</strong> lokal übernommen.
            </div>
          )}
          <Button
            onClick={() => setShowSelector(true)}
            variant="outline"
            className="w-full"
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Speicher-Modus ändern
          </Button>
        </CardContent>
      </Card>

      {/* Local Data Management */}
      {isLocal && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <Download className="h-5 w-5" />
              Lokale Datenverwaltung
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Button onClick={handleExportBackup} variant="outline" className="w-full">
              <Download className="h-4 w-4 mr-2" />
              Backup als JSON herunterladen
            </Button>
            <Button onClick={handleClearLocal} variant="outline" className="w-full border-red-200 text-red-600 hover:bg-red-50">
              <Trash2 className="h-4 w-4 mr-2" />
              Alle lokalen Daten löschen
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Info */}
      <Card className="bg-gray-50">
        <CardContent className="pt-5">
          <h3 className="font-semibold text-gray-800 mb-3">Unterschiede der Modi</h3>
          <div className="space-y-2 text-sm text-gray-600">
            <div className="flex items-start gap-2">
              <Smartphone className="h-4 w-4 text-green-600 mt-0.5 flex-shrink-0" />
              <div><strong>Lokal:</strong> Maximaler Datenschutz, kein Server-Zugriff, nur auf diesem Gerät, kein automatisches Backup</div>
            </div>
            <div className="flex items-start gap-2">
              <Cloud className="h-4 w-4 text-blue-600 mt-0.5 flex-shrink-0" />
              <div><strong>Cloud:</strong> Alle Features, Geräteübergreifend, automatisches Backup, DSGVO-konform</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}