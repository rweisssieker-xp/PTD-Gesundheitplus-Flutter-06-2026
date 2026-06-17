import React, { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { QrCode, Download, Share2 } from "lucide-react";
import { toast } from "sonner";

export default function QRCodeGenerator({ data, title = "QR-Code" }) {
  const [qrCodeUrl, setQrCodeUrl] = useState("");

  useEffect(() => {
    if (data) {
      generateQRCode();
    }
  }, [data]);

  const generateQRCode = () => {
    try {
      const jsonData = JSON.stringify(data);
      const base64Data = btoa(unescape(encodeURIComponent(jsonData)));
      
      // Using a QR code API service
      const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(base64Data)}`;
      setQrCodeUrl(qrUrl);
    } catch (error) {
      toast.error("Fehler beim Generieren des QR-Codes");
    }
  };

  const downloadQRCode = () => {
    if (!qrCodeUrl) return;
    
    const link = document.createElement('a');
    link.href = qrCodeUrl;
    link.download = 'gesundheit-plus-qr-code.png';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success("QR-Code heruntergeladen");
  };

  const shareQRCode = async () => {
    if (!qrCodeUrl) return;

    if (navigator.share) {
      try {
        const response = await fetch(qrCodeUrl);
        const blob = await response.blob();
        const file = new File([blob], 'qr-code.png', { type: 'image/png' });
        
        await navigator.share({
          title: 'Meine Gesundheitsdaten',
          text: 'QR-Code für Gesundheit Plus',
          files: [file]
        });
        toast.success("QR-Code geteilt");
      } catch (error) {
        toast.error("Teilen fehlgeschlagen");
      }
    } else {
      toast.info("Teilen wird von Ihrem Browser nicht unterstützt");
    }
  };

  if (!qrCodeUrl) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <QrCode className="h-12 w-12 text-gray-300 mx-auto mb-4 animate-pulse" />
          <p className="text-gray-500">QR-Code wird generiert...</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="border-2">
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          <QrCode className="h-5 w-5" />
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="bg-white p-4 rounded-lg border-2 flex items-center justify-center">
          <img 
            src={qrCodeUrl} 
            alt="QR Code" 
            className="w-64 h-64"
          />
        </div>
        
        <div className="space-y-2">
          <p className="text-sm text-gray-600 text-center">
            Ärzte können diesen QR-Code scannen, um Ihre Daten zu lesen
          </p>
          
          <div className="grid grid-cols-2 gap-3">
            <Button onClick={downloadQRCode} variant="outline" className="w-full">
              <Download className="h-4 w-4 mr-2" />
              Download
            </Button>
            <Button onClick={shareQRCode} variant="outline" className="w-full">
              <Share2 className="h-4 w-4 mr-2" />
              Teilen
            </Button>
          </div>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
          <p className="text-xs text-yellow-800">
            <strong>Datenschutz:</strong> Der QR-Code enthält Ihre persönlichen Gesundheitsdaten. 
            Teilen Sie ihn nur mit medizinischem Fachpersonal.
          </p>
        </div>
      </CardContent>
    </Card>
  );
}