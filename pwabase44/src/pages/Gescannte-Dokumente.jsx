import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { createPageUrl } from "@/utils";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";
import { useEntities } from "@/lib/StorageContext";
import MedicalInsights from "../components/MedicalInsights";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { 
  FileText, 
  Search, 
  Plus, 
  Star,
  StarOff,
  Trash2,
  Eye,
  Calendar,
  User,
  Tag,
  Filter,
  Download,
  ZoomIn,
  Brain,
  AlertCircle
} from "lucide-react";
import { toast } from "sonner";
import { format } from "date-fns";

export default function GescanneDokumentePage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("all");
  const [urgencyFilter, setUrgencyFilter] = useState("all");
  const [selectedDocument, setSelectedDocument] = useState(null);
  const [showImageDialog, setShowImageDialog] = useState(false);
  const [activeTab, setActiveTab] = useState("details");

  const { data: documents = [], isLoading } = useQuery({
    queryKey: ['scanned-documents'],
    queryFn: () => entities.ScannedDocument.list('-created_date'),
  });

  const toggleFavoriteMutation = useMutation({
    mutationFn: ({ id, isFavorite }) => 
      entities.ScannedDocument.update(id, { is_favorite: !isFavorite }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['scanned-documents'] });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => entities.ScannedDocument.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['scanned-documents'] });
      toast.success("Dokument gelöscht");
      setSelectedDocument(null);
    }
  });

  const handleExecuteAction = async (action) => {
    const { action_type, related_data } = action;

    try {
      switch (action_type) {
        case 'add_medication':
          if (related_data) {
            await entities.Medication.create({
              name: related_data.name,
              dosage: related_data.dosage,
              frequency: related_data.frequency,
              active: true
            });
            toast.success("Medikament hinzugefügt!");
          }
          break;

        case 'schedule_appointment':
          navigate(createPageUrl("Termine"));
          toast.info("Bitte Termin manuell eintragen");
          break;

        case 'update_allergy':
          navigate(createPageUrl("Allergien"));
          toast.info("Bitte Allergie manuell eintragen");
          break;

        case 'add_vaccination':
          navigate(createPageUrl("Impfpass"));
          toast.info("Bitte Impfung manuell eintragen");
          break;

        default:
          toast.info("Diese Aktion muss manuell durchgeführt werden");
      }
    } catch (error) {
      toast.error("Fehler beim Ausführen der Aktion");
      console.error(error);
    }
  };

  const filteredDocuments = documents.filter(doc => {
    const matchesSearch = 
      doc.title?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.extracted_text?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.tags?.some(tag => tag.toLowerCase().includes(searchQuery.toLowerCase())) ||
      doc.related_doctor?.toLowerCase().includes(searchQuery.toLowerCase());
    
    const matchesType = typeFilter === "all" || doc.document_type === typeFilter;
    const matchesUrgency = urgencyFilter === "all" || doc.ai_insights?.urgency_level === urgencyFilter;
    
    return matchesSearch && matchesType && matchesUrgency;
  });

  const documentTypes = [...new Set(documents.map(d => d.document_type))];
  const favoriteDocuments = filteredDocuments.filter(d => d.is_favorite);
  const urgentDocuments = filteredDocuments.filter(d => 
    d.ai_insights?.urgency_level === 'urgent' || d.ai_insights?.urgency_level === 'high'
  );

  const downloadImage = async (url, title) => {
    try {
      const response = await fetch(url);
      const blob = await response.blob();
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `${title}.jpg`;
      link.click();
      toast.success("Download gestartet");
    } catch (error) {
      toast.error("Download fehlgeschlagen");
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin h-12 w-12 border-4 border-blue-500 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-600">Lade Dokumente...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 pb-24">
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Gescannte Dokumente</h1>
          <p className="text-gray-600">
            {documents.length} Dokument{documents.length !== 1 ? 'e' : ''} gespeichert
          </p>
        </div>
        <Button
          onClick={() => navigate(createPageUrl("Dokumenten-Scan"))}
          className="bg-gradient-to-r from-blue-500 to-blue-600"
        >
          <Plus className="h-5 w-5 mr-2" />
          Neu scannen
        </Button>
      </div>

      {urgentDocuments.length > 0 && (
        <Card className="border-2 border-red-300 bg-red-50">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <AlertCircle className="h-6 w-6 text-red-600" />
              <div>
                <p className="font-semibold text-red-900">
                  {urgentDocuments.length} Dokument{urgentDocuments.length !== 1 ? 'e' : ''} erfordert Aufmerksamkeit
                </p>
                <p className="text-sm text-red-700">Wichtige Befunde oder Handlungen erforderlich</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardContent className="pt-6 space-y-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
            <Input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Dokumente durchsuchen..."
              className="pl-10"
            />
          </div>

          <div className="grid grid-cols-2 gap-2">
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-gray-500 flex-shrink-0" />
              <Select value={typeFilter} onValueChange={setTypeFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="Typ" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Alle Typen</SelectItem>
                  {documentTypes.map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <Select value={urgencyFilter} onValueChange={setUrgencyFilter}>
              <SelectTrigger>
                <SelectValue placeholder="Dringlichkeit" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Alle</SelectItem>
                <SelectItem value="urgent">🚨 Dringend</SelectItem>
                <SelectItem value="high">⚠️ Hoch</SelectItem>
                <SelectItem value="medium">🔵 Mittel</SelectItem>
                <SelectItem value="low">ℹ️ Niedrig</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {favoriteDocuments.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Star className="h-5 w-5 text-yellow-500 fill-yellow-500" />
              Favoriten
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid gap-3">
              {favoriteDocuments.slice(0, 3).map(doc => (
                <DocumentCard
                  key={doc.id}
                  document={doc}
                  onToggleFavorite={toggleFavoriteMutation.mutate}
                  onView={() => setSelectedDocument(doc)}
                  onViewImage={() => {
                    setSelectedDocument(doc);
                    setShowImageDialog(true);
                  }}
                  onDelete={deleteMutation.mutate}
                  onDownload={downloadImage}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">
            {searchQuery || typeFilter !== "all" || urgencyFilter !== "all" ? "Suchergebnisse" : "Alle Dokumente"}
          </CardTitle>
        </CardHeader>
        <CardContent>
          {filteredDocuments.length === 0 ? (
            <div className="text-center py-12">
              <FileText className="h-16 w-16 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-500 mb-4">
                {searchQuery ? "Keine passenden Dokumente gefunden" : "Noch keine Dokumente gescannt"}
              </p>
              <Button
                onClick={() => navigate(createPageUrl("Dokumenten-Scan"))}
                variant="outline"
              >
                <Plus className="h-5 w-5 mr-2" />
                Erstes Dokument scannen
              </Button>
            </div>
          ) : (
            <div className="grid gap-3">
              {filteredDocuments.map(doc => (
                <DocumentCard
                  key={doc.id}
                  document={doc}
                  onToggleFavorite={toggleFavoriteMutation.mutate}
                  onView={() => setSelectedDocument(doc)}
                  onViewImage={() => {
                    setSelectedDocument(doc);
                    setShowImageDialog(true);
                  }}
                  onDelete={deleteMutation.mutate}
                  onDownload={downloadImage}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Document Details Dialog with Tabs */}
      <Dialog open={!!selectedDocument && !showImageDialog} onOpenChange={(open) => !open && setSelectedDocument(null)}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{selectedDocument?.title}</DialogTitle>
          </DialogHeader>
          {selectedDocument && (
            <Tabs value={activeTab} onValueChange={setActiveTab}>
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="details">Details</TabsTrigger>
                <TabsTrigger value="insights">
                  <Brain className="h-4 w-4 mr-1" />
                  KI-Analyse
                </TabsTrigger>
                <TabsTrigger value="text">Text</TabsTrigger>
              </TabsList>

              <TabsContent value="details" className="space-y-4">
                <div className="flex gap-2 flex-wrap">
                  <Badge>{selectedDocument.document_type}</Badge>
                  {selectedDocument.is_favorite && (
                    <Badge variant="outline" className="border-yellow-500 text-yellow-700">
                      <Star className="h-3 w-3 mr-1 fill-yellow-500" />
                      Favorit
                    </Badge>
                  )}
                  {selectedDocument.ai_insights?.urgency_level && (
                    <Badge variant={
                      selectedDocument.ai_insights.urgency_level === 'urgent' ? 'destructive' :
                      selectedDocument.ai_insights.urgency_level === 'high' ? 'destructive' : 'outline'
                    }>
                      {selectedDocument.ai_insights.urgency_level === 'urgent' ? '🚨 Dringend' :
                       selectedDocument.ai_insights.urgency_level === 'high' ? '⚠️ Hoch' :
                       selectedDocument.ai_insights.urgency_level === 'medium' ? '🔵 Mittel' : 'ℹ️ Niedrig'}
                    </Badge>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-4 text-sm">
                  {selectedDocument.document_date && (
                    <div>
                      <p className="text-gray-500 mb-1">Datum</p>
                      <p className="font-medium">{format(new Date(selectedDocument.document_date), 'dd.MM.yyyy')}</p>
                    </div>
                  )}
                  {selectedDocument.related_doctor && (
                    <div>
                      <p className="text-gray-500 mb-1">Arzt</p>
                      <p className="font-medium">{selectedDocument.related_doctor}</p>
                    </div>
                  )}
                </div>

                {selectedDocument.tags && selectedDocument.tags.length > 0 && (
                  <div>
                    <p className="text-sm text-gray-500 mb-2">Schlagwörter</p>
                    <div className="flex flex-wrap gap-2">
                      {selectedDocument.tags.map((tag, idx) => (
                        <Badge key={idx} variant="outline">{tag}</Badge>
                      ))}
                    </div>
                  </div>
                )}

                {selectedDocument.notes && (
                  <div>
                    <p className="text-sm text-gray-500 mb-2">Notizen</p>
                    <p className="text-sm">{selectedDocument.notes}</p>
                  </div>
                )}

                <div className="flex gap-2">
                  <Button
                    onClick={() => setShowImageDialog(true)}
                    variant="outline"
                    className="flex-1"
                  >
                    <ZoomIn className="h-4 w-4 mr-2" />
                    Bild anzeigen
                  </Button>
                  <Button
                    onClick={() => downloadImage(selectedDocument.image_url, selectedDocument.title)}
                    variant="outline"
                    className="flex-1"
                  >
                    <Download className="h-4 w-4 mr-2" />
                    Download
                  </Button>
                </div>
              </TabsContent>

              <TabsContent value="insights">
                <MedicalInsights 
                  document={selectedDocument}
                  onActionClick={handleExecuteAction}
                />
              </TabsContent>

              <TabsContent value="text">
                {selectedDocument.extracted_text ? (
                  <div className="p-4 bg-gray-50 rounded-lg text-sm max-h-96 overflow-y-auto whitespace-pre-wrap">
                    {selectedDocument.extracted_text}
                  </div>
                ) : (
                  <p className="text-center text-gray-500 py-8">Kein extrahierter Text verfügbar</p>
                )}
              </TabsContent>
            </Tabs>
          )}
        </DialogContent>
      </Dialog>

      {/* Image View Dialog */}
      <Dialog open={showImageDialog} onOpenChange={setShowImageDialog}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle>{selectedDocument?.title}</DialogTitle>
          </DialogHeader>
          {selectedDocument && (
            <img
              src={selectedDocument.image_url}
              alt={selectedDocument.title}
              className="w-full h-auto rounded-lg"
            />
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}

function DocumentCard({ document, onToggleFavorite, onView, onViewImage, onDelete, onDownload }) {
  const urgencyColors = {
    urgent: "border-red-400 bg-red-50",
    high: "border-orange-400 bg-orange-50",
    medium: "border-blue-200 bg-blue-50",
    low: "border-gray-200 bg-white"
  };

  const urgency = document.ai_insights?.urgency_level || 'low';
  const hasInsights = document.ai_insights || document.medical_entities;

  return (
    <Card className={`hover:shadow-lg transition-shadow border-2 ${urgencyColors[urgency]}`}>
      <CardContent className="pt-6">
        <div className="flex gap-4">
          <div 
            className="w-20 h-20 flex-shrink-0 bg-gray-100 rounded-lg overflow-hidden cursor-pointer hover:opacity-80 transition-opacity"
            onClick={onViewImage}
          >
            <img
              src={document.image_url}
              alt={document.title}
              className="w-full h-full object-cover"
            />
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2 mb-2">
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-gray-900 truncate cursor-pointer hover:text-blue-600" onClick={onView}>
                  {document.title}
                </h3>
                {hasInsights && (
                  <div className="flex items-center gap-1 mt-1">
                    <Brain className="h-3 w-3 text-purple-600" />
                    <span className="text-xs text-purple-600 font-medium">KI-analysiert</span>
                  </div>
                )}
              </div>
              <Button
                size="icon"
                variant="ghost"
                onClick={() => onToggleFavorite({ id: document.id, isFavorite: document.is_favorite })}
                className="flex-shrink-0"
              >
                {document.is_favorite ? (
                  <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
                ) : (
                  <StarOff className="h-4 w-4 text-gray-400" />
                )}
              </Button>
            </div>

            <div className="flex flex-wrap gap-1 mb-2">
              <Badge className="text-xs">{document.document_type}</Badge>
              {document.ai_insights?.urgency_level && document.ai_insights.urgency_level !== 'low' && (
                <Badge variant={urgency === 'urgent' || urgency === 'high' ? 'destructive' : 'outline'} className="text-xs">
                  {urgency === 'urgent' ? '🚨' : urgency === 'high' ? '⚠️' : '🔵'}
                </Badge>
              )}
            </div>

            <div className="space-y-1 text-xs text-gray-600">
              {document.document_date && (
                <div className="flex items-center gap-1">
                  <Calendar className="h-3 w-3" />
                  {format(new Date(document.document_date), 'dd.MM.yyyy')}
                </div>
              )}
              {document.related_doctor && (
                <div className="flex items-center gap-1">
                  <User className="h-3 w-3" />
                  {document.related_doctor}
                </div>
              )}
              {document.tags && document.tags.length > 0 && (
                <div className="flex items-center gap-1">
                  <Tag className="h-3 w-3" />
                  {document.tags.slice(0, 3).join(", ")}
                  {document.tags.length > 3 && "..."}
                </div>
              )}
            </div>

            <div className="flex gap-2 mt-3">
              <Button size="sm" variant="outline" onClick={onView}>
                <Eye className="h-3 w-3 mr-1" />
                Details
              </Button>
              <Button
                size="sm"
                variant="outline"
                onClick={() => onDownload(document.image_url, document.title)}
              >
                <Download className="h-3 w-3" />
              </Button>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => onDelete(document.id)}
                className="text-red-600 hover:text-red-700 hover:bg-red-50"
              >
                <Trash2 className="h-3 w-3" />
              </Button>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}