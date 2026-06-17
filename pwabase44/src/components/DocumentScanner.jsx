import React, { useState, useRef, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Camera, Upload, X, RotateCw, Check, Loader2, ZoomIn, ZoomOut, Brain } from "lucide-react";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";

export default function DocumentScanner({ onScanComplete, documentType }) {
  const [image, setImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [processingStep, setProcessingStep] = useState("");
  const [isCameraActive, setIsCameraActive] = useState(false);
  const [stream, setStream] = useState(null);
  const [rotation, setRotation] = useState(0);
  const [zoom, setZoom] = useState(1);
  
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const fileInputRef = useRef(null);

  // Cleanup camera stream on unmount
  useEffect(() => {
    return () => {
      if (stream) {
        try {
          stream.getTracks().forEach(track => track.stop());
        } catch (error) {
          console.error("Error stopping stream:", error);
        }
      }
    };
  }, [stream]);

  const startCamera = async () => {
    try {
      // Check if mediaDevices is supported
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        toast.error("Kamera wird von Ihrem Browser nicht unterstützt");
        return;
      }

      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: { ideal: 'environment' },
          width: { ideal: 1920 },
          height: { ideal: 1080 }
        }
      });
      
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
      }
      
      setStream(mediaStream);
      setIsCameraActive(true);
      toast.success("Kamera aktiviert");
    } catch (error) {
      console.error("Camera error:", error);
      
      if (error.name === 'NotAllowedError') {
        toast.error("Kamerazugriff wurde verweigert. Bitte erlauben Sie den Zugriff in den Browsereinstellungen.");
      } else if (error.name === 'NotFoundError') {
        toast.error("Keine Kamera gefunden");
      } else {
        toast.error("Kamera konnte nicht gestartet werden");
      }
    }
  };

  const stopCamera = () => {
    if (stream) {
      try {
        stream.getTracks().forEach(track => track.stop());
        setStream(null);
      } catch (error) {
        console.error("Error stopping camera:", error);
      }
    }
    setIsCameraActive(false);
  };

  const captureImage = () => {
    if (!videoRef.current || !canvasRef.current) {
      toast.error("Fehler beim Aufnehmen des Bildes");
      return;
    }

    try {
      const canvas = canvasRef.current;
      const video = videoRef.current;
      
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        toast.error("Canvas-Kontext konnte nicht erstellt werden");
        return;
      }
      
      ctx.drawImage(video, 0, 0);
      
      canvas.toBlob((blob) => {
        if (!blob) {
          toast.error("Fehler beim Erstellen des Bildes");
          return;
        }
        
        const file = new File([blob], 'scan.jpg', { type: 'image/jpeg' });
        handleImageFile(file);
        stopCamera();
      }, 'image/jpeg', 0.85); // Reduced quality for smaller file size
    } catch (error) {
      console.error("Error capturing image:", error);
      toast.error("Fehler beim Aufnehmen des Bildes");
    }
  };

  const handleImageFile = (file) => {
    // Validate file size (max 10MB)
    if (file.size > 10 * 1024 * 1024) {
      toast.error("Datei ist zu groß (max. 10MB)");
      return;
    }

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast.error("Bitte wählen Sie eine Bilddatei");
      return;
    }

    setImage(file);
    const reader = new FileReader();
    
    reader.onload = (e) => {
      if (e.target?.result) {
        setImagePreview(e.target.result);
      }
    };
    
    reader.onerror = () => {
      toast.error("Fehler beim Laden des Bildes");
    };
    
    reader.readAsDataURL(file);
  };

  const handleFileUpload = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      handleImageFile(file);
    }
  };

  const rotateImage = () => {
    setRotation((prev) => (prev + 90) % 360);
  };

  const adjustZoom = (delta) => {
    setZoom((prev) => Math.max(0.5, Math.min(2, prev + delta)));
  };

  const processDocument = async () => {
    if (!image) {
      toast.error("Bitte laden Sie zuerst ein Bild hoch");
      return;
    }

    setIsProcessing(true);
    
    try {
      // Step 1: Upload image
      setProcessingStep("Bild wird hochgeladen...");
      toast.info("Bild wird hochgeladen...");
      
      const uploadResult = await base44.integrations.Core.UploadFile({ file: image });
      
      if (!uploadResult?.file_url) {
        throw new Error("Upload fehlgeschlagen - keine URL erhalten");
      }
      
      const imageUrl = uploadResult.file_url;

      // Step 2: Advanced OCR and Medical Entity Extraction
      setProcessingStep("Medizinische Analyse läuft...");
      toast.info("🧠 KI analysiert das Dokument...");
      
      const analysisResult = await base44.integrations.Core.InvokeLLM({
        prompt: `Du bist ein medizinisches Dokumenten-Analysesystem. Analysiere dieses medizinische Dokument gründlich und extrahiere ALLE relevanten Informationen.

AUFGABEN:
1. Erkenne den genauen Dokumenttyp (Arztbrief, Rezept, Laborbefund, etc.)
2. Extrahiere den kompletten Text (OCR)
3. Identifiziere alle medizinischen Entitäten:
   - Diagnosen mit ICD-Codes falls vorhanden
   - Verschriebene Medikamente mit Dosierung und Häufigkeit
   - Laborwerte mit Referenzbereichen und Status (normal/abnormal/kritisch)
   - Durchgeführte oder geplante Prozeduren
   - Erwähnte Allergien
   - Impfungen mit Datum und Chargennummer
4. Erstelle eine prägnante Zusammenfassung
5. Identifiziere die wichtigsten Erkenntnisse
6. Bewerte die Dringlichkeit (low/medium/high/urgent)
7. Schlage konkrete Aktionen vor, die der Patient basierend auf diesem Dokument unternehmen sollte

Sei präzise, gründlich und extrahiere alle numerischen Werte genau. Gib NULL zurück für Felder, die nicht im Dokument vorhanden sind.`,
        file_urls: [imageUrl],
        response_json_schema: {
          type: "object",
          properties: {
            full_text: { type: "string", description: "Vollständiger extrahierter Text" },
            document_type: { 
              type: "string",
              enum: ["Arztbrief", "Rezept", "Laborbefund", "Röntgenbild", "Impfpass", "Allergiepass", "Versicherungskarte", "Medikamentenplan", "Terminkarte", "Überweisungsschein", "Entlassungsbericht", "Sonstiges"]
            },
            document_date: { type: "string", description: "Datum des Dokuments im Format YYYY-MM-DD" },
            doctor_name: { type: "string" },
            patient_name: { type: "string" },
            medical_entities: {
              type: "object",
              properties: {
                diagnoses: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      condition: { type: "string" },
                      icd_code: { type: "string" },
                      severity: { type: "string" }
                    }
                  }
                },
                medications: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      name: { type: "string" },
                      dosage: { type: "string" },
                      frequency: { type: "string" },
                      duration: { type: "string" }
                    }
                  }
                },
                lab_results: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      test_name: { type: "string" },
                      value: { type: "string" },
                      unit: { type: "string" },
                      reference_range: { type: "string" },
                      status: { type: "string", enum: ["normal", "abnormal", "critical"] }
                    }
                  }
                },
                procedures: {
                  type: "array",
                  items: { type: "string" }
                },
                allergies: {
                  type: "array",
                  items: { type: "string" }
                },
                vaccinations: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      vaccine: { type: "string" },
                      date: { type: "string" },
                      batch_number: { type: "string" }
                    }
                  }
                }
              }
            },
            ai_insights: {
              type: "object",
              properties: {
                summary: { type: "string", description: "Kurze, verständliche Zusammenfassung für Patienten" },
                key_findings: {
                  type: "array",
                  items: { type: "string" },
                  description: "Die 3-5 wichtigsten Erkenntnisse"
                },
                urgency_level: {
                  type: "string",
                  enum: ["low", "medium", "high", "urgent"]
                },
                category_confidence: { type: "number", description: "Wie sicher ist die Kategorisierung (0-1)" },
                requires_attention: { type: "boolean" }
              }
            },
            suggested_actions: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  action_type: { 
                    type: "string",
                    enum: ["schedule_appointment", "add_medication", "update_allergy", "add_vaccination", "follow_up", "contact_doctor", "lifestyle_change"]
                  },
                  description: { type: "string" },
                  priority: { type: "string", enum: ["low", "medium", "high"] },
                  related_data: { 
                    type: "object",
                    description: "Strukturierte Daten für die Aktion"
                  }
                }
              }
            },
            suggested_title: { type: "string" },
            tags: {
              type: "array",
              items: { type: "string" },
              description: "Relevante Schlagwörter für die Suche"
            }
          }
        }
      });

      // Validate analysis result
      if (!analysisResult || typeof analysisResult !== 'object') {
        throw new Error("Ungültige Analyse-Antwort erhalten");
      }

      setProcessingStep("Analyse abgeschlossen!");
      toast.success("✅ Dokument erfolgreich analysiert!");
      
      onScanComplete({
        imageUrl,
        extractedData: analysisResult,
        documentType
      });

      // Reset
      setImage(null);
      setImagePreview(null);
      setRotation(0);
      setZoom(1);
      setProcessingStep("");
      
    } catch (error) {
      console.error("Processing error:", error);
      
      // Provide specific error messages
      if (error.message?.includes("Upload")) {
        toast.error("Fehler beim Hochladen des Bildes");
      } else if (error.message?.includes("Analyse")) {
        toast.error("Fehler bei der KI-Analyse");
      } else {
        toast.error("Fehler beim Verarbeiten des Dokuments");
      }
      
      setProcessingStep("");
    } finally {
      setIsProcessing(false);
    }
  };

  const resetScan = () => {
    setImage(null);
    setImagePreview(null);
    setRotation(0);
    setZoom(1);
    stopCamera();
  };

  return (
    <Card className="border-2">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Camera className="h-5 w-5" />
          Dokument scannen
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {!imagePreview && !isCameraActive && (
          <div className="space-y-3">
            <Button
              onClick={startCamera}
              className="w-full h-16 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700"
            >
              <Camera className="h-6 w-6 mr-2" />
              Kamera öffnen
            </Button>

            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="bg-white px-2 text-gray-500">oder</span>
              </div>
            </div>

            <Button
              onClick={() => fileInputRef.current?.click()}
              variant="outline"
              className="w-full h-16 border-2"
            >
              <Upload className="h-6 w-6 mr-2" />
              Datei hochladen
            </Button>
            
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handleFileUpload}
              className="hidden"
            />
          </div>
        )}

        {isCameraActive && (
          <div className="space-y-3">
            <div className="relative bg-black rounded-lg overflow-hidden">
              <video
                ref={videoRef}
                autoPlay
                playsInline
                className="w-full h-auto"
              />
              <canvas ref={canvasRef} className="hidden" />
            </div>

            <div className="flex gap-2">
              <Button
                onClick={captureImage}
                className="flex-1 h-14 bg-gradient-to-r from-green-500 to-green-600"
              >
                <Camera className="h-5 w-5 mr-2" />
                Aufnehmen
              </Button>
              <Button
                onClick={stopCamera}
                variant="outline"
                className="h-14 px-6"
              >
                <X className="h-5 w-5" />
              </Button>
            </div>
          </div>
        )}

        {imagePreview && (
          <div className="space-y-3">
            <div className="relative bg-gray-100 rounded-lg overflow-hidden">
              <img
                src={imagePreview}
                alt="Gescanntes Dokument"
                className="w-full h-auto"
                style={{
                  transform: `rotate(${rotation}deg) scale(${zoom})`,
                  transition: 'transform 0.3s ease'
                }}
              />
            </div>

            <div className="flex gap-2">
              <Button
                onClick={rotateImage}
                variant="outline"
                className="flex-1"
                disabled={isProcessing}
              >
                <RotateCw className="h-4 w-4 mr-2" />
                Drehen
              </Button>
              <Button
                onClick={() => adjustZoom(0.2)}
                variant="outline"
                className="px-4"
                disabled={isProcessing}
              >
                <ZoomIn className="h-4 w-4" />
              </Button>
              <Button
                onClick={() => adjustZoom(-0.2)}
                variant="outline"
                className="px-4"
                disabled={isProcessing}
              >
                <ZoomOut className="h-4 w-4" />
              </Button>
            </div>

            {isProcessing && (
              <div className="bg-blue-50 border-2 border-blue-200 rounded-lg p-4">
                <div className="flex items-center gap-3 mb-2">
                  <Brain className="h-5 w-5 text-blue-600 animate-pulse" />
                  <span className="font-semibold text-blue-900">KI-Analyse läuft...</span>
                </div>
                <p className="text-sm text-blue-700">{processingStep}</p>
                <div className="mt-3 h-2 bg-blue-200 rounded-full overflow-hidden">
                  <div className="h-full bg-blue-600 animate-pulse" style={{ width: '70%' }}></div>
                </div>
              </div>
            )}

            <div className="flex gap-2">
              <Button
                onClick={processDocument}
                disabled={isProcessing}
                className="flex-1 h-14 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700"
              >
                {isProcessing ? (
                  <>
                    <Loader2 className="h-5 w-5 mr-2 animate-spin" />
                    Analysiere...
                  </>
                ) : (
                  <>
                    <Brain className="h-5 w-5 mr-2" />
                    KI-Analyse starten
                  </>
                )}
              </Button>
              <Button
                onClick={resetScan}
                variant="outline"
                disabled={isProcessing}
                className="h-14 px-6"
              >
                <X className="h-5 w-5" />
              </Button>
            </div>
          </div>
        )}

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
          <p className="text-xs text-blue-800 font-semibold mb-2">
            🧠 KI-gestützte Analyse:
          </p>
          <ul className="text-xs text-blue-700 space-y-1 ml-4 list-disc">
            <li>Automatische Texterkennung (OCR)</li>
            <li>Erkennung von Diagnosen & Medikamenten</li>
            <li>Analyse von Laborwerten</li>
            <li>Intelligente Handlungsempfehlungen</li>
          </ul>
        </div>

        <div className="bg-gray-50 border border-gray-200 rounded-lg p-3">
          <p className="text-xs text-gray-700">
            <strong>Tipps für beste Ergebnisse:</strong>
          </p>
          <ul className="text-xs text-gray-600 mt-1 space-y-1 ml-4 list-disc">
            <li>Gute Beleuchtung verwenden</li>
            <li>Dokument flach ausbreiten</li>
            <li>Kamera parallel zum Dokument halten</li>
            <li>Text sollte scharf und lesbar sein</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}