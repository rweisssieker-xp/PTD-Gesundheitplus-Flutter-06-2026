import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Download, QrCode, Info, Printer } from "lucide-react";
import { toast } from "sonner";

/**
 * Emergency QR Code Generator
 * Creates a QR code containing critical emergency information
 * Can be scanned offline by emergency responders
 */
export default function EmergencyQRCode({ data, title = "Notfall QR-Code" }) {
  const [qrCodeUrl, setQrCodeUrl] = useState(null);
  const [isGenerating, setIsGenerating] = useState(false);

  useEffect(() => {
    if (data) {
      generateQRCode();
    }
  }, [data]);

  const generateQRCode = async () => {
    if (!data) return;

    setIsGenerating(true);
    try {
      // Prepare compact emergency data
      const emergencyData = {
        name: data.name || "Unbekannt",
        dob: data.date_of_birth || "",
        blood: data.blood_type || "",
        allergies: data.allergies?.map(a => a.allergen).join(", ") || "Keine",
        meds: data.medications?.map(m => m.name).join(", ") || "Keine",
        contacts: data.contacts?.map(c => ({
          n: c.name,
          p: c.phone
        })) || [],
        profile: data.emergency_profile?.summary || "",
        warnings: data.emergency_profile?.critical_warnings?.join("; ") || "",
        timestamp: new Date().toISOString()
      };

      // Convert to JSON string
      const jsonString = JSON.stringify(emergencyData);

      // Use QR Code API (we'll use a free API service)
      const qrApiUrl = `https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=${encodeURIComponent(jsonString)}`;
      
      setQrCodeUrl(qrApiUrl);
      setIsGenerating(false);
    } catch (error) {
      console.error("Failed to generate QR code:", error);
      toast.error("QR-Code konnte nicht erstellt werden");
      setIsGenerating(false);
    }
  };

  const downloadQRCode = () => {
    if (!qrCodeUrl) return;

    const link = document.createElement('a');
    link.href = qrCodeUrl;
    link.download = `notfall-qr-code-${new Date().toISOString().split('T')[0]}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success("QR-Code wird heruntergeladen");
  };

  const printQRCode = () => {
    if (!qrCodeUrl) return;

    const printWindow = window.open('', '_blank');
    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Notfall QR-Code</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              text-align: center;
              padding: 20px;
            }
            h1 {
              color: #dc2626;
              margin-bottom: 20px;
            }
            img {
              border: 2px solid #dc2626;
              padding: 10px;
              margin: 20px 0;
            }
            .info {
              margin-top: 20px;
              font-size: 14px;
              color: #666;
            }
            .warning {
              background: #fee;
              border: 2px solid #dc2626;
              padding: 15px;
              margin: 20px 0;
              border-radius: 8px;
            }
            @media print {
              button { display: none; }
            }
          </style>
        </head>
        <body>
          <h1>🚨 NOTFALL QR-CODE</h1>
          <div class="warning">
            <p><strong>Für medizinisches Fachpersonal</strong></p>
            <p>Dieser QR-Code enthält wichtige Notfallinformationen</p>
          </div>
          <img src="${qrCodeUrl}" alt="Emergency QR Code" />
          <div class="info">
            <p><strong>Name:</strong> ${data.name || 'N/A'}</p>
            <p><strong>Erstellt am:</strong> ${new Date().toLocaleDateString('de-DE')}</p>
            <p>Bitte scannen Sie diesen Code im Notfall</p>
          </div>
        </body>
      </html>
    `);
    printWindow.document.close();
    printWindow.print();
  };

  if (!data) {
    return (
      <Card className="border-2 border-gray-200">
        <CardContent className="py-12 text-center">
          <QrCode className="h-12 w-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500">Keine Daten für QR-Code verfügbar</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-2 border-red-200 bg-gradient-to-br from-red-50 to-orange-50">
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          <QrCode className="h-5 w-5 text-red-600" />
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Info Box */}
        <div className="flex gap-2 p-3 bg-blue-100 border border-blue-300 rounded-lg">
          <Info className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-blue-900">
            <p className="font-semibold mb-1">Offline-Zugriff für Rettungsdienste</p>
            <p className="text-xs">
              Dieser QR-Code enthält Ihre wichtigsten Notfallinformationen und kann ohne Internet gescannt werden.
            </p>
          </div>
        </div>

        {/* QR Code Display */}
        {isGenerating ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-600"></div>
          </div>
        ) : qrCodeUrl ? (
          <div className="bg-white p-6 rounded-lg border-2 border-red-300 flex flex-col items-center">
            <img 
              src={qrCodeUrl} 
              alt="Emergency QR Code" 
              className="w-full max-w-xs"
            />
            <p className="text-xs text-gray-600 mt-4 text-center">
              Scannen Sie diesen Code, um Notfallinformationen anzuzeigen
            </p>
          </div>
        ) : null}

        {/* Actions */}
        <div className="grid grid-cols-2 gap-3">
          <Button
            onClick={downloadQRCode}
            disabled={!qrCodeUrl}
            variant="outline"
            className="w-full"
          >
            <Download className="h-4 w-4 mr-2" />
            Herunterladen
          </Button>
          <Button
            onClick={printQRCode}
            disabled={!qrCodeUrl}
            variant="outline"
            className="w-full"
          >
            <Printer className="h-4 w-4 mr-2" />
            Drucken
          </Button>
        </div>

        {/* Usage Instructions */}
        <div className="text-xs text-gray-600 space-y-1 p-3 bg-white rounded-lg border">
          <p className="font-semibold text-gray-900 mb-2">Verwendungshinweise:</p>
          <ul className="list-disc list-inside space-y-1">
            <li>Drucken Sie den QR-Code aus und bewahren Sie ihn im Portemonnaie auf</li>
            <li>Der Code funktioniert auch ohne Internetverbindung</li>
            <li>Aktualisieren Sie den Code bei wichtigen Änderungen</li>
            <li>Teilen Sie ihn nur mit vertrauenswürdigen Personen</li>
          </ul>
        </div>

        {/* Regenerate Button */}
        <Button
          onClick={generateQRCode}
          variant="outline"
          size="sm"
          className="w-full text-xs"
        >
          QR-Code neu generieren
        </Button>
      </CardContent>
    </Card>
  );
}