import React, { useState } from "react";
import { Link } from "react-router-dom";
import { createPageUrl } from "@/utils";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AlertCircle,
  Plus,
  Trash2,
  Save,
  Phone,
  Mail,
  Shield,
  Info,
  CheckCircle,
  Brain,
  MessageSquare,
  AlertTriangle,
  MessageCircle,
  ExternalLink,
  Upload,
  ShieldCheck,
  ShieldAlert,
  Users
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEntities } from "@/lib/StorageContext";
import { toast } from "sonner";
import EmergencyProfileGenerator from "@/components/EmergencyProfileGenerator";
import { isValidPhoneNumber, formatPhoneNumber } from "@/components/SMSService";
import { formatWhatsAppNumber } from "@/components/WhatsAppService";
import ContactImporter from "@/components/ContactImporter";
import ContactVerification from "@/components/ContactVerification";

export default function NotfallEinrichtungPage() {
  const queryClient = useQueryClient();
  const entities = useEntities();
  const [showForm, setShowForm] = useState(false);
  const [editingContact, setEditingContact] = useState(null);
  const [showImporter, setShowImporter] = useState(false);
  const [verifyingContact, setVerifyingContact] = useState(null);
  const [verifyingChannel, setVerifyingChannel] = useState(null);
  const [formData, setFormData] = useState({
    name: "",
    relationship: "Partner/in",
    phone: "",
    email: "",
    telegram_chat_id: "",
    whatsapp_number: "",
    priority: 1,
    notify_via_sms: true,
    notify_via_email: true,
    notify_via_telegram: false,
    notify_via_whatsapp: false,
    notes: ""
  });

  const { data: contacts = [], isLoading } = useQuery({
    queryKey: ['emergency-contacts'],
    queryFn: () => entities.EmergencyContact.list(),
  });

  const saveMutation = useMutation({
    mutationFn: (data) => {
      const formattedData = {
        ...data,
        phone: formatPhoneNumber(data.phone),
        whatsapp_number: data.whatsapp_number ? formatWhatsAppNumber(data.whatsapp_number) : "",
        // Initialize verification_status if not present, otherwise keep existing
        verification_status: data.verification_status || {
          phone_verified: false,
          whatsapp_verified: false,
          telegram_verified: false,
          email_verified: false
        }
      };

      if (editingContact) {
        return entities.EmergencyContact.update(editingContact.id, formattedData);
      }
      return entities.EmergencyContact.create(formattedData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['emergency-contacts'] });
      toast.success(editingContact ? "Kontakt aktualisiert" : "Kontakt hinzugefügt");
      resetForm();
    },
    onError: () => {
      toast.error("Fehler beim Speichern");
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => entities.EmergencyContact.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['emergency-contacts'] });
      toast.success("Kontakt gelöscht");
    }
  });

  const resetForm = () => {
    setFormData({
      name: "",
      relationship: "Partner/in",
      phone: "",
      email: "",
      telegram_chat_id: "",
      whatsapp_number: "",
      priority: 1,
      notify_via_sms: true,
      notify_via_email: true,
      notify_via_telegram: false,
      notify_via_whatsapp: false,
      notes: ""
    });
    setEditingContact(null);
    setShowForm(false);
  };

  const handleEdit = (contact) => {
    setFormData(contact);
    setEditingContact(contact);
    setShowForm(true);
  };

  const handleSave = () => {
    if (!formData.name || !formData.phone) {
      toast.error("Name und Telefonnummer sind erforderlich");
      return;
    }

    const formatted = formatPhoneNumber(formData.phone);
    if (!isValidPhoneNumber(formatted)) {
      toast.error("Ungültige Telefonnummer. Bitte im Format +49... eingeben");
      return;
    }

    if (formData.notify_via_sms && !formatted.startsWith('+')) {
      toast.warning("Telefonnummer sollte mit + beginnen für SMS-Versand");
    }

    if (formData.notify_via_telegram && !formData.telegram_chat_id) {
      toast.error("Telegram Chat-ID erforderlich für Telegram-Benachrichtigungen");
      return;
    }

    if (formData.notify_via_whatsapp && !formData.whatsapp_number) {
      toast.error("WhatsApp Nummer erforderlich für WhatsApp-Benachrichtigungen");
      return;
    }

    saveMutation.mutate(formData);
  };

  const handleImport = () => {
    queryClient.invalidateQueries({ queryKey: ['emergency-contacts'] });
    setShowImporter(false);
  };

  const handleVerify = (contact, channel) => {
    setVerifyingContact(contact);
    setVerifyingChannel(channel);
  };

  const handleVerified = () => {
    queryClient.invalidateQueries({ queryKey: ['emergency-contacts'] });
  };

  const sortedContacts = [...contacts].sort((a, b) => a.priority - b.priority);
  const smsEnabledContacts = contacts.filter(c => c.notify_via_sms && c.phone);
  const telegramEnabledContacts = contacts.filter(c => c.notify_via_telegram && c.telegram_chat_id);
  const whatsappEnabledContacts = contacts.filter(c => c.notify_via_whatsapp && c.whatsapp_number);

  // Calculate verification stats
  const verifiedStats = {
    sms: contacts.filter(c => c.notify_via_sms && c.verification_status?.phone_verified).length,
    telegram: contacts.filter(c => c.notify_via_telegram && c.verification_status?.telegram_verified).length,
    whatsapp: contacts.filter(c => c.notify_via_whatsapp && c.verification_status?.whatsapp_verified).length,
    email: contacts.filter(c => c.notify_via_email && c.email && c.verification_status?.email_verified).length
  };

  const unverifiedCount = contacts.filter(c => {
    const vs = c.verification_status || {};
    return (c.notify_via_sms && !vs.phone_verified) ||
           (c.notify_via_telegram && !vs.telegram_verified) ||
           (c.notify_via_whatsapp && !vs.whatsapp_verified) ||
           (c.notify_via_email && c.email && !vs.email_verified);
  }).length;

  return (
    <div className="p-6 space-y-6 pb-24">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2 flex items-center gap-2">
          <Shield className="h-7 w-7 text-red-600" />
          Notfall-Einrichtung
        </h1>
        <p className="text-gray-600">
          Richten Sie Ihre Notfallkontakte ein und verifizieren Sie Benachrichtigungswege.
        </p>
      </div>

      {/* Verification Warning */}
      {unverifiedCount > 0 && (
        <Card className="border-2 border-yellow-200 bg-yellow-50">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <ShieldAlert className="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-yellow-900 mb-1">
                  {unverifiedCount} Kontakt(e) nicht verifiziert
                </p>
                <p className="text-sm text-yellow-800 mb-3">
                  Bitte verifizieren Sie Ihre Notfallkontakte, um sicherzustellen, dass Benachrichtigungen ankommen.
                </p>
                <div className="flex items-center gap-2">
                  <ShieldCheck className="h-4 w-4 text-yellow-700" />
                  <span className="text-xs text-yellow-700">
                    Verifizierung dauert nur 1-2 Minuten pro Kontakt
                  </span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Multi-Channel Info */}
      <Card className="border-2 border-green-200 bg-gradient-to-br from-green-50 to-emerald-50">
        <CardContent className="pt-6">
          <div className="space-y-3">
            <div className="flex items-center gap-2 mb-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <p className="font-semibold text-green-900">Multi-Channel Notfall-System</p>
            </div>
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div className="flex items-center gap-2 text-green-800">
                <MessageSquare className="h-4 w-4" />
                <span>{smsEnabledContacts.length} SMS ({verifiedStats.sms} ✓)</span>
              </div>
              <div className="flex items-center gap-2 text-green-800">
                <Mail className="h-4 w-4" />
                <span>{contacts.filter(c => c.notify_via_email).length} E-Mail ({verifiedStats.email} ✓)</span>
              </div>
              <div className="flex items-center gap-2 text-blue-800">
                <MessageCircle className="h-4 w-4" />
                <span>{telegramEnabledContacts.length} Telegram ({verifiedStats.telegram} ✓)</span>
              </div>
              <div className="flex items-center gap-2 text-green-800">
                <MessageCircle className="h-4 w-4" />
                <span>{whatsappEnabledContacts.length} WhatsApp ({verifiedStats.whatsapp} ✓)</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Telegram Setup Link */}
      <Link to={createPageUrl("Telegram-Setup")}>
        <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-cyan-50 hover:shadow-lg transition-shadow cursor-pointer">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <MessageCircle className="h-8 w-8 text-blue-500" />
                <div>
                  <p className="font-semibold text-blue-900">Telegram verbinden</p>
                  <p className="text-sm text-blue-700">Sofortige Benachrichtigungen mit Standort</p>
                </div>
              </div>
              <ExternalLink className="h-5 w-5 text-blue-600" />
            </div>
          </CardContent>
        </Card>
      </Link>

      {/* Info Card */}
      <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-pink-50">
        <CardContent className="pt-6">
          <div className="flex gap-3">
            <Info className="h-5 w-5 text-purple-600 flex-shrink-0 mt-0.5" />
            <div className="space-y-2 text-sm text-purple-900">
              <p className="font-semibold">So funktioniert Emergency Guardian:</p>
              <ul className="space-y-1 ml-4 list-disc">
                <li>5-Sekunden Countdown zum Abbrechen</li>
                <li>Automatische GPS-Standort-Erfassung</li>
                <li><strong>📱 SMS:</strong> Schnelle Benachrichtigung</li>
                <li><strong>✈️ Telegram:</strong> Sofort + interaktiv + kostenlos</li>
                <li><strong>💬 WhatsApp:</strong> Weit verbreitet + zuverlässig</li>
                <li><strong>📧 E-Mail:</strong> Vollständige Details + KI-Profil</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* KI-Notfallprofil Generator */}
      <EmergencyProfileGenerator />

      {/* Action Buttons */}
      <div className="grid grid-cols-2 gap-4">
        <Button
          onClick={() => setShowImporter(true)}
          variant="outline"
          className="h-14 border-2 border-blue-200 hover:bg-blue-50"
        >
          <Upload className="h-5 w-5 mr-2" />
          <div className="text-left">
            <div className="font-semibold">Aus Adressbuch</div>
            <div className="text-xs text-gray-500">Kontakte importieren</div>
          </div>
        </Button>

        <Button
          onClick={() => setShowForm(true)}
          className="h-14 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700"
        >
          <Plus className="h-5 w-5 mr-2" />
          <div className="text-left">
            <div className="font-semibold">Manuell hinzufügen</div>
            <div className="text-xs opacity-90">Neuer Kontakt</div>
          </div>
        </Button>
      </div>

      {/* Contact Importer Dialog */}
      <Dialog open={showImporter} onOpenChange={setShowImporter}>
        <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Kontakte importieren</DialogTitle>
          </DialogHeader>
          <ContactImporter
            onImport={handleImport}
            onClose={() => setShowImporter(false)}
          />
        </DialogContent>
      </Dialog>

      {/* Verification Dialog */}
      <Dialog open={!!verifyingContact} onOpenChange={() => {
        setVerifyingContact(null);
        setVerifyingChannel(null);
      }}>
        <DialogContent className="max-w-md">
          {verifyingContact && verifyingChannel && (
            <ContactVerification
              contact={verifyingContact}
              channel={verifyingChannel}
              onClose={() => {
                setVerifyingContact(null);
                setVerifyingChannel(null);
              }}
              onVerified={handleVerified}
            />
          )}
        </DialogContent>
      </Dialog>
      
      {/* Warning if no contacts */}
      {contacts.length === 0 && (
        <Card className="border-2 border-orange-200 bg-orange-50">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <AlertCircle className="h-5 w-5 text-orange-600 flex-shrink-0" />
              <div>
                <p className="font-semibold text-orange-900 mb-1">
                  Keine Notfallkontakte eingerichtet
                </p>
                <p className="text-sm text-orange-800">
                  Bitte fügen Sie mindestens einen Notfallkontakt hinzu.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Add/Edit Form */}
      {showForm && (
        <Card className="border-2 border-green-200 bg-green-50">
          <CardHeader>
            <CardTitle className="text-lg">
              {editingContact ? "Kontakt bearbeiten" : "Neuer Notfallkontakt"}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label htmlFor="name">Name *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                placeholder="z.B. Maria Müller"
                className="mt-1 bg-white"
              />
            </div>

            <div>
              <Label htmlFor="relationship">Beziehung</Label>
              <Select
                value={formData.relationship}
                onValueChange={(value) => setFormData({...formData, relationship: value})}
              >
                <SelectTrigger className="mt-1 bg-white">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Partner/in">Partner/in</SelectItem>
                  <SelectItem value="Elternteil">Elternteil</SelectItem>
                  <SelectItem value="Kind">Kind</SelectItem>
                  <SelectItem value="Geschwister">Geschwister</SelectItem>
                  <SelectItem value="Freund/in">Freund/in</SelectItem>
                  <SelectItem value="Nachbar/in">Nachbar/in</SelectItem>
                  <SelectItem value="Betreuer/in">Betreuer/in</SelectItem>
                  <SelectItem value="Sonstige">Sonstige</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="phone">Telefonnummer * (für SMS)</Label>
              <Input
                id="phone"
                type="tel"
                value={formData.phone}
                onChange={(e) => setFormData({...formData, phone: e.target.value})}
                placeholder="+49 179 1292743"
                className="mt-1 bg-white"
              />
              <p className="text-xs text-gray-600 mt-1">
                📱 Format: +49... (mit Ländercode)
              </p>
            </div>

            <div>
              <Label htmlFor="email">E-Mail-Adresse</Label>
              <Input
                id="email"
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
                placeholder="kontakt@beispiel.de"
                className="mt-1 bg-white"
              />
            </div>

            <div>
              <Label htmlFor="priority">Priorität (1 = höchste)</Label>
              <Select
                value={formData.priority.toString()}
                onValueChange={(value) => setFormData({...formData, priority: parseInt(value)})}
              >
                <SelectTrigger className="mt-1 bg-white">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="1">1 - Höchste Priorität</SelectItem>
                  <SelectItem value="2">2 - Hoch</SelectItem>
                  <SelectItem value="3">3 - Normal</SelectItem>
                  <SelectItem value="4">4 - Niedrig</SelectItem>
                  <SelectItem value="5">5 - Niedrigste</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Notification Methods */}
            <div className="space-y-3 p-4 bg-white rounded-lg border-2">
              <p className="text-sm font-semibold text-gray-900 mb-3">Benachrichtigungsmethoden:</p>

              {/* SMS */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <MessageSquare className="h-4 w-4 text-green-600" />
                  <Label htmlFor="notify_sms" className="text-sm">Per SMS</Label>
                </div>
                <Switch
                  id="notify_sms"
                  checked={formData.notify_via_sms}
                  onCheckedChange={(checked) => setFormData({...formData, notify_via_sms: checked})}
                />
              </div>

              {/* Email */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-gray-600" />
                  <Label htmlFor="notify_email" className="text-sm">Per E-Mail (mit KI-Profil)</Label>
                </div>
                <Switch
                  id="notify_email"
                  checked={formData.notify_via_email}
                  onCheckedChange={(checked) => setFormData({...formData, notify_via_email: checked})}
                />
              </div>

              {/* Telegram */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <MessageCircle className="h-4 w-4 text-blue-500" />
                    <Label htmlFor="notify_telegram" className="text-sm">Per Telegram (empfohlen!)</Label>
                  </div>
                  <Switch
                    id="notify_telegram"
                    checked={formData.notify_via_telegram}
                    onCheckedChange={(checked) => setFormData({...formData, notify_via_telegram: checked})}
                  />
                </div>
                {formData.notify_via_telegram && (
                  <Input
                    placeholder="Telegram Chat-ID (z.B. 123456789)"
                    value={formData.telegram_chat_id}
                    onChange={(e) => setFormData({...formData, telegram_chat_id: e.target.value})}
                    className="bg-blue-50 text-sm"
                  />
                )}
              </div>

              {/* WhatsApp */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <MessageCircle className="h-4 w-4 text-green-600" />
                    <Label htmlFor="notify_whatsapp" className="text-sm">Per WhatsApp</Label>
                  </div>
                  <Switch
                    id="notify_whatsapp"
                    checked={formData.notify_via_whatsapp}
                    onCheckedChange={(checked) => setFormData({...formData, notify_via_whatsapp: checked})}
                  />
                </div>
                {formData.notify_via_whatsapp && (
                  <Input
                    placeholder="WhatsApp Nummer (z.B. +49 179 1292743)"
                    value={formData.whatsapp_number}
                    onChange={(e) => setFormData({...formData, whatsapp_number: e.target.value})}
                    className="bg-green-50 text-sm"
                  />
                )}
              </div>
            </div>

            <div>
              <Label htmlFor="notes">Notizen</Label>
              <Textarea
                id="notes"
                value={formData.notes}
                onChange={(e) => setFormData({...formData, notes: e.target.value})}
                placeholder="Zusätzliche Informationen..."
                rows={2}
                className="mt-1 bg-white"
              />
            </div>

            <div className="flex gap-3 pt-2">
              <Button
                onClick={handleSave}
                disabled={saveMutation.isPending}
                className="flex-1 h-12 bg-green-600 hover:bg-green-700"
              >
                <Save className="h-5 w-5 mr-2" />
                Speichern
              </Button>
              <Button
                onClick={resetForm}
                variant="outline"
                className="h-12 px-6"
              >
                Abbrechen
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Contacts List */}
      {sortedContacts.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-lg font-semibold text-gray-900">
            Ihre Notfallkontakte ({sortedContacts.length})
          </h2>

          {sortedContacts.map((contact, index) => {
            const vs = contact.verification_status || {};
            const hasUnverified = 
              (contact.notify_via_sms && !vs.phone_verified) ||
              (contact.notify_via_telegram && !vs.telegram_verified) ||
              (contact.notify_via_whatsapp && !vs.whatsapp_verified) ||
              (contact.notify_via_email && contact.email && !vs.email_verified);

            return (
              <Card key={contact.id} className={`border-2 hover:shadow-lg transition-shadow ${hasUnverified ? 'border-yellow-200 bg-yellow-50' : ''}`}>
                <CardContent className="pt-6">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <div className="h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center text-white font-bold">
                          {index + 1}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <p className="font-semibold text-gray-900">{contact.name}</p>
                            {contact.imported_from_contacts && (
                              <span className="text-xs bg-blue-100 text-blue-800 px-2 py-0.5 rounded">
                                <Users className="h-3 w-3 inline mr-1" />
                                Importiert
                              </span>
                            )}
                          </div>
                          <p className="text-sm text-gray-600">{contact.relationship}</p>
                        </div>
                      </div>

                      <div className="space-y-1 ml-12">
                        <div className="flex items-center gap-2 text-sm text-gray-700">
                          <Phone className="h-4 w-4 text-gray-500" />
                          <span>{contact.phone}</span>
                          {contact.notify_via_sms && (vs.phone_verified ? (
                            <ShieldCheck className="h-4 w-4 text-green-600" />
                          ) : (
                            <Button
                              size="sm"
                              variant="ghost"
                              className="h-6 text-xs text-yellow-600 hover:text-yellow-700 p-0"
                              onClick={() => handleVerify(contact, 'sms')}
                            >
                              Verifizieren
                            </Button>
                          ))}
                        </div>
                        {contact.email && (
                          <div className="flex items-center gap-2 text-sm text-gray-700">
                            <Mail className="h-4 w-4 text-gray-500" />
                            <span>{contact.email}</span>
                            {contact.notify_via_email && (vs.email_verified ? (
                              <ShieldCheck className="h-4 w-4 text-green-600" />
                            ) : (
                              <Button
                                size="sm"
                                variant="ghost"
                                className="h-6 text-xs text-yellow-600 hover:text-yellow-700 p-0"
                                onClick={() => handleVerify(contact, 'email')}
                              >
                                Verifizieren
                              </Button>
                            ))}
                          </div>
                        )}

                        <div className="flex gap-2 mt-2 flex-wrap">
                          {contact.notify_via_sms && (
                            <span className={`text-xs px-2 py-1 rounded flex items-center gap-1 ${vs.phone_verified ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}`}>
                              <MessageSquare className="h-3 w-3" />
                              SMS {vs.phone_verified && '✓'}
                            </span>
                          )}
                          {contact.notify_via_email && (
                            <span className={`text-xs px-2 py-1 rounded flex items-center gap-1 ${vs.email_verified ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                              <Mail className="h-3 w-3" />
                              E-Mail {vs.email_verified && '✓'}
                            </span>
                          )}
                          {contact.notify_via_telegram && (
                            <span className={`text-xs px-2 py-1 rounded flex items-center gap-1 ${vs.telegram_verified ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}`}>
                              <MessageCircle className="h-3 w-3" />
                              Telegram {vs.telegram_verified ? '✓' : (
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  className="h-4 p-0 text-xs underline text-yellow-800 hover:text-yellow-900"
                                  onClick={() => handleVerify(contact, 'telegram')}
                                >
                                  ?
                                </Button>
                              )}
                            </span>
                          )}
                          {contact.notify_via_whatsapp && (
                            <span className={`text-xs px-2 py-1 rounded flex items-center gap-1 ${vs.whatsapp_verified ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}`}>
                              <MessageCircle className="h-3 w-3" />
                              WhatsApp {vs.whatsapp_verified ? '✓' : (
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  className="h-4 p-0 text-xs underline text-yellow-800 hover:text-yellow-900"
                                  onClick={() => handleVerify(contact, 'whatsapp')}
                                >
                                  ?
                                </Button>
                              )}
                            </span>
                          )}
                        </div>

                        {contact.notes && (
                          <p className="text-xs text-gray-600 mt-2 italic">
                            {contact.notes}
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="flex flex-col gap-2">
                      <Button
                        onClick={() => handleEdit(contact)}
                        variant="outline"
                        size="sm"
                      >
                        Bearbeiten
                      </Button>
                      <Button
                        onClick={() => {
                          if (confirm(`${contact.name} wirklich löschen?`)) {
                            deleteMutation.mutate(contact.id);
                          }
                        }}
                        variant="outline"
                        size="sm"
                        className="text-red-600 hover:text-red-700 hover:bg-red-50"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}