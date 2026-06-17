/**
 * Privacy Policy / Datenschutz Page
 * GDPR-compliant privacy information
 */

import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { 
  Shield, 
  Lock, 
  Database,
  Eye,
  Download,
  Trash2,
  CheckCircle,
  AlertTriangle,
  FileText,
  Settings,
  Info
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { toast } from "sonner";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter
} from "@/components/ui/dialog";

export default function DatenschutzPage() {
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showExportDialog, setShowExportDialog] = useState(false);
  const [isExporting, setIsExporting] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleExportData = async () => {
    setIsExporting(true);
    
    try {
      const user = await base44.auth.me();
      
      // Collect all user data
      const [
        medications, allergies, medicalHistory, appointments, 
        vaccinations, healthPasses, contacts, notifications,
        scannedDocs
      ] = await Promise.all([
        base44.entities.Medication.list().catch(() => []),
        base44.entities.Allergy.list().catch(() => []),
        base44.entities.MedicalHistory.list().catch(() => []),
        base44.entities.Appointment.list().catch(() => []),
        base44.entities.Vaccination.list().catch(() => []),
        base44.entities.HealthPass.list().catch(() => []),
        base44.entities.EmergencyContact.list().catch(() => []),
        base44.entities.Notification.list().catch(() => []),
        base44.entities.ScannedDocument.list().catch(() => [])
      ]);

      const exportData = {
        export_date: new Date().toISOString(),
        user_profile: {
          email: user.email,
          full_name: user.full_name,
          date_of_birth: user.date_of_birth,
          gender: user.gender,
          height: user.height,
          weight: user.weight,
          preferred_language: user.preferred_language
        },
        medical_data: {
          medications: medications,
          allergies: allergies,
          medical_history: medicalHistory,
          appointments: appointments,
          vaccinations: vaccinations,
          health_passes: healthPasses,
          scanned_documents: scannedDocs.map(d => ({
            ...d,
            image_url: '[REDACTED - Download separately]'
          }))
        },
        emergency_data: {
          contacts: contacts,
          emergency_profile: user.emergency_profile
        },
        notifications: notifications,
        metadata: {
          total_records: medications.length + allergies.length + appointments.length + 
                         vaccinations.length + healthPasses.length + contacts.length,
          app_version: "1.0",
          export_format: "JSON"
        }
      };

      // Create downloadable file
      const blob = new Blob([JSON.stringify(exportData, null, 2)], { 
        type: 'application/json' 
      });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `gesundheit-plus-export-${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);

      toast.success('✅ Datenexport erfolgreich', {
        description: 'Ihre Daten wurden als JSON-Datei heruntergeladen'
      });

      setShowExportDialog(false);

    } catch (error) {
      console.error('Export error:', error);
      toast.error('Fehler beim Datenexport');
    } finally {
      setIsExporting(false);
    }
  };

  const handleDeleteAllData = async () => {
    setIsDeleting(true);
    
    try {
      // Delete all entity data
      const deletePromises = [];
      
      const entities = [
        'Medication', 'Allergy', 'MedicalHistory', 'Appointment',
        'Vaccination', 'HealthPass', 'EmergencyContact', 'Notification',
        'ScannedDocument'
      ];

      for (const entity of entities) {
        try {
          const records = await base44.entities[entity].list();
          for (const record of records) {
            deletePromises.push(base44.entities[entity].delete(record.id));
          }
        } catch (error) {
          console.error(`Error deleting ${entity}:`, error);
        }
      }

      await Promise.all(deletePromises);

      // Reset user profile data
      await base44.auth.updateMe({
        date_of_birth: null,
        gender: null,
        height: null,
        weight: null,
        emergency_profile: null,
        last_health_analysis: null
      });

      toast.success('✅ Alle Daten gelöscht', {
        description: 'Ihr Account wurde zurückgesetzt'
      });

      setShowDeleteDialog(false);

      // Reload page
      setTimeout(() => {
        window.location.href = '/';
      }, 2000);

    } catch (error) {
      console.error('Delete error:', error);
      toast.error('Fehler beim Löschen der Daten');
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className="p-6 space-y-6 pb-24">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2 flex items-center gap-2">
            <Shield className="h-7 w-7 text-blue-600" />
            Datenschutz & Sicherheit
          </h1>
          <p className="text-gray-600">
            Ihre Daten sind sicher und geschützt gemäß DSGVO
          </p>
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card className="border-2 border-blue-200 hover:shadow-lg transition-shadow cursor-pointer"
                onClick={() => setShowExportDialog(true)}>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
                  <Download className="h-6 w-6 text-blue-600" />
                </div>
                <div>
                  <p className="font-semibold text-gray-900">Daten exportieren</p>
                  <p className="text-sm text-gray-600">DSGVO Art. 20</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="border-2 border-red-200 hover:shadow-lg transition-shadow cursor-pointer"
                onClick={() => setShowDeleteDialog(true)}>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="h-12 w-12 rounded-full bg-red-100 flex items-center justify-center">
                  <Trash2 className="h-6 w-6 text-red-600" />
                </div>
                <div>
                  <p className="font-semibold text-gray-900">Daten löschen</p>
                  <p className="text-sm text-gray-600">DSGVO Art. 17</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Security Features */}
        <Card className="border-2 border-green-200 bg-green-50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Lock className="h-5 w-5 text-green-600" />
              Ihre Datensicherheit
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-start gap-3">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-gray-900">Ende-zu-Ende-Verschlüsselung</p>
                <p className="text-sm text-gray-600">Alle Daten werden verschlüsselt übertragen und gespeichert</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-gray-900">DSGVO-konform</p>
                <p className="text-sm text-gray-600">Vollständige Einhaltung der EU-Datenschutzgrundverordnung</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-gray-900">Server in Deutschland</p>
                <p className="text-sm text-gray-600">Ihre Daten werden ausschließlich in Deutschland gespeichert</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-gray-900">Keine Weitergabe</p>
                <p className="text-sm text-gray-600">Ihre Daten werden niemals an Dritte verkauft oder weitergegeben</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Data Storage Info */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Database className="h-5 w-5 text-blue-600" />
              Welche Daten speichern wir?
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <h3 className="font-semibold text-gray-900 mb-2">Gesundheitsdaten</h3>
                <ul className="text-sm text-gray-600 space-y-1 ml-4 list-disc">
                  <li>Medikamente, Allergien, Diagnosen</li>
                  <li>Impfungen, Termine, Behandlungshistorie</li>
                  <li>Gescannte Dokumente (Arztbriefe, Rezepte)</li>
                  <li>KI-generierte Notfallprofile und Analysen</li>
                </ul>
              </div>

              <div>
                <h3 className="font-semibold text-gray-900 mb-2">Persönliche Daten</h3>
                <ul className="text-sm text-gray-600 space-y-1 ml-4 list-disc">
                  <li>Name, E-Mail-Adresse, Geburtsdatum</li>
                  <li>Notfallkontakte (nur zum Zweck der Notfallbenachrichtigung)</li>
                </ul>
              </div>

              <div>
                <h3 className="font-semibold text-gray-900 mb-2">Nutzungsdaten</h3>
                <ul className="text-sm text-gray-600 space-y-1 ml-4 list-disc">
                  <li>Login-Zeitpunkte, Zugriffsprotokolle</li>
                  <li>Einstellungen und Präferenzen</li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Your Rights */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Eye className="h-5 w-5 text-purple-600" />
              Ihre Rechte (DSGVO)
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <Info className="h-5 w-5 text-blue-500 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-gray-900">Auskunftsrecht (Art. 15)</p>
                  <p className="text-sm text-gray-600">Sie haben das Recht zu erfahren, welche Daten wir über Sie speichern</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Download className="h-5 w-5 text-green-500 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-gray-900">Datenübertragbarkeit (Art. 20)</p>
                  <p className="text-sm text-gray-600">Sie können Ihre Daten in einem strukturierten Format exportieren</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Settings className="h-5 w-5 text-yellow-500 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-gray-900">Berichtigungsrecht (Art. 16)</p>
                  <p className="text-sm text-gray-600">Sie können Ihre Daten jederzeit selbst bearbeiten und korrigieren</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Trash2 className="h-5 w-5 text-red-500 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-gray-900">Löschungsrecht (Art. 17)</p>
                  <p className="text-sm text-gray-600">Sie können alle Ihre Daten jederzeit vollständig löschen lassen</p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <AlertTriangle className="h-5 w-5 text-orange-500 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-gray-900">Widerspruchsrecht (Art. 21)</p>
                  <p className="text-sm text-gray-600">Sie können der Verarbeitung Ihrer Daten widersprechen</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Data Processing Purpose */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5 text-indigo-600" />
              Zweck der Datenverarbeitung
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3 text-sm text-gray-600">
              <p>
                <strong>Primärzweck:</strong> Bereitstellung einer digitalen Gesundheitsakte zur 
                Verwaltung Ihrer medizinischen Daten und Verbesserung Ihrer Gesundheitsversorgung.
              </p>
              <p>
                <strong>Notfallbenachrichtigung:</strong> Im Notfall können Ihre hinterlegten 
                Kontakte über Ihren Gesundheitszustand informiert werden (nur mit Ihrer Zustimmung).
              </p>
              <p>
                <strong>KI-Analysen:</strong> Zur Generierung personalisierter Gesundheitsempfehlungen 
                und Notfallprofile werden Ihre Daten KI-gestützt analysiert (lokal, keine externe Weitergabe).
              </p>
              <p>
                <strong>Gesetzliche Aufbewahrungspflicht:</strong> Keine. Sie können Ihre Daten 
                jederzeit vollständig löschen.
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Contact */}
        <Card className="border-2 border-gray-200 bg-gray-50">
          <CardContent className="pt-6">
            <h3 className="font-semibold text-gray-900 mb-2">
              Fragen zum Datenschutz?
            </h3>
            <p className="text-sm text-gray-600 mb-4">
              Unser Datenschutzbeauftragter steht Ihnen zur Verfügung:
            </p>
            <div className="space-y-1 text-sm">
              <p><strong>E-Mail:</strong> datenschutz@gesundheit-plus.de</p>
              <p><strong>Adresse:</strong> Gesundheit Plus GmbH, Datenschutz, 10115 Berlin</p>
            </div>
            <p className="text-xs text-gray-500 mt-4">
              Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbehörde zu beschweren.
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Export Dialog */}
      <Dialog open={showExportDialog} onOpenChange={setShowExportDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Download className="h-5 w-5" />
              Daten exportieren
            </DialogTitle>
            <DialogDescription>
              Laden Sie alle Ihre Daten als JSON-Datei herunter (DSGVO Art. 20).
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3 py-4">
            <p className="text-sm text-gray-600">
              Der Export enthält:
            </p>
            <ul className="text-sm text-gray-600 space-y-1 ml-4 list-disc">
              <li>Ihr Benutzerprofil</li>
              <li>Alle medizinischen Daten (Medikamente, Allergien, etc.)</li>
              <li>Notfallkontakte und -profile</li>
              <li>Termine und Benachrichtigungen</li>
              <li>Metadaten (ohne Bilddateien)</li>
            </ul>
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
              <p className="text-xs text-blue-900">
                💡 <strong>Hinweis:</strong> Bilddateien (gescannte Dokumente) müssen 
                separat über die Dokumenten-Seite heruntergeladen werden.
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowExportDialog(false)}>
              Abbrechen
            </Button>
            <Button 
              onClick={handleExportData} 
              disabled={isExporting}
              className="bg-blue-600 hover:bg-blue-700"
            >
              {isExporting ? (
                <>Exportiere...</>
              ) : (
                <>
                  <Download className="h-4 w-4 mr-2" />
                  Jetzt exportieren
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-red-600">
              <AlertTriangle className="h-5 w-5" />
              Alle Daten löschen
            </DialogTitle>
            <DialogDescription>
              Diese Aktion kann nicht rückgängig gemacht werden!
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3 py-4">
            <div className="bg-red-50 border-2 border-red-200 rounded-lg p-4">
              <p className="text-sm text-red-900 font-semibold mb-2">
                ⚠️ WARNUNG: Unwiderrufliche Löschung
              </p>
              <p className="text-sm text-red-800">
                Alle Ihre Gesundheitsdaten, Medikamente, Allergien, Termine, 
                Notfallkontakte, gescannte Dokumente und KI-Profile werden 
                permanent gelöscht.
              </p>
            </div>
            <p className="text-sm text-gray-600">
              <strong>Betroffen sind:</strong>
            </p>
            <ul className="text-sm text-gray-600 space-y-1 ml-4 list-disc">
              <li>Alle medizinischen Einträge</li>
              <li>Notfallkontakte und -profile</li>
              <li>Gescannte Dokumente</li>
              <li>Termine und Benachrichtigungen</li>
              <li>KI-Analysen und Empfehlungen</li>
            </ul>
            <p className="text-sm text-gray-600">
              <strong>Nicht betroffen:</strong> Ihr Account bleibt bestehen, Sie können 
              die App weiterhin nutzen.
            </p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDeleteDialog(false)}>
              Abbrechen
            </Button>
            <Button 
              onClick={handleDeleteAllData} 
              disabled={isDeleting}
              className="bg-red-600 hover:bg-red-700"
            >
              {isDeleting ? (
                <>Lösche...</>
              ) : (
                <>
                  <Trash2 className="h-4 w-4 mr-2" />
                  Alle Daten löschen
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}