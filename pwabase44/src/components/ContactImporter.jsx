/**
 * Contact Importer Component
 * Allows importing contacts from device address book
 */

import React, { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { 
  Users, 
  Upload, 
  CheckCircle, 
  AlertCircle,
  Search,
  Phone
} from "lucide-react";
import { Input } from "@/components/ui/input";
import { toast } from "sonner";
import { base44 } from "@/api/base44Client";

export default function ContactImporter({ onImport, onClose }) {
  const [contacts, setContacts] = useState([]);
  const [selectedContacts, setSelectedContacts] = useState(new Set());
  const [isLoading, setIsLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [hasAccess, setHasAccess] = useState(false);

  const requestContactAccess = async () => {
    setIsLoading(true);
    
    try {
      // Check if Contacts API is supported
      if (!('contacts' in navigator) || !('ContactsManager' in window)) {
        toast.error('Adressbuch-Zugriff nicht unterstützt', {
          description: 'Ihr Browser oder Gerät unterstützt keinen Zugriff auf Kontakte.'
        });
        setIsLoading(false);
        return;
      }

      // Request contacts with specific properties
      const props = ['name', 'tel'];
      const opts = { multiple: true };

      const selectedDeviceContacts = await navigator.contacts.select(props, opts);
      
      if (selectedDeviceContacts && selectedDeviceContacts.length > 0) {
        // Process contacts
        const processedContacts = selectedDeviceContacts
          .filter(contact => contact.tel && contact.tel.length > 0)
          .map((contact, index) => ({
            id: `import_${Date.now()}_${index}`,
            name: contact.name?.[0] || 'Unbekannter Kontakt',
            phone: contact.tel[0], // First phone number
            allPhones: contact.tel || [],
            source: 'device_contacts',
            rawData: contact
          }));

        setContacts(processedContacts);
        setHasAccess(true);
        toast.success(`${processedContacts.length} Kontakte gefunden`);
      } else {
        toast.info('Keine Kontakte ausgewählt');
      }
    } catch (error) {
      console.error('Contact access error:', error);
      
      if (error.name === 'SecurityError') {
        toast.error('Zugriff verweigert', {
          description: 'Bitte erlauben Sie den Zugriff auf Kontakte in den Browser-Einstellungen.'
        });
      } else if (error.name === 'NotSupportedError') {
        toast.error('Nicht unterstützt', {
          description: 'Ihr Browser unterstützt keinen Kontakt-Zugriff. Bitte nutzen Sie Chrome/Edge auf Android.'
        });
      } else {
        toast.error('Fehler beim Zugriff auf Kontakte', {
          description: error.message
        });
      }
    } finally {
      setIsLoading(false);
    }
  };

  const toggleContact = (contactId) => {
    const newSelected = new Set(selectedContacts);
    if (newSelected.has(contactId)) {
      newSelected.delete(contactId);
    } else {
      newSelected.add(contactId);
    }
    setSelectedContacts(newSelected);
  };

  const handleImport = async () => {
    if (selectedContacts.size === 0) {
      toast.warning('Keine Kontakte ausgewählt');
      return;
    }

    setIsLoading(true);

    try {
      const importedContacts = [];
      
      for (const contactId of selectedContacts) {
        const contact = contacts.find(c => c.id === contactId);
        if (!contact) continue;

        // Format phone number
        let formattedPhone = contact.phone.replace(/\s+/g, '');
        if (!formattedPhone.startsWith('+')) {
          // Assume German number if no country code
          if (formattedPhone.startsWith('0')) {
            formattedPhone = '+49' + formattedPhone.substring(1);
          }
        }

        // Create emergency contact
        const emergencyContact = await base44.entities.EmergencyContact.create({
          name: contact.name,
          phone: formattedPhone,
          relationship: 'Sonstige',
          priority: 3,
          notify_via_sms: true,
          notify_via_email: false,
          notify_via_telegram: false,
          notify_via_whatsapp: false,
          imported_from_contacts: true,
          contact_raw_data: contact.rawData,
          verification_status: {
            phone_verified: false,
            whatsapp_verified: false,
            telegram_verified: false,
            email_verified: false
          },
          notes: 'Aus Adressbuch importiert'
        });

        importedContacts.push(emergencyContact);
      }

      toast.success(`${importedContacts.length} Kontakte importiert`, {
        description: 'Bitte verifizieren Sie die Kontakte für sichere Benachrichtigungen.'
      });

      if (onImport) {
        onImport(importedContacts);
      }

      if (onClose) {
        onClose();
      }

    } catch (error) {
      console.error('Import error:', error);
      toast.error('Fehler beim Importieren', {
        description: error.message
      });
    } finally {
      setIsLoading(false);
    }
  };

  const filteredContacts = contacts.filter(contact =>
    contact.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    contact.phone.includes(searchQuery)
  );

  return (
    <Card className="border-2 border-blue-200">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Users className="h-5 w-5" />
          Kontakte importieren
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {!hasAccess ? (
          <>
            <div className="text-center py-6">
              <div className="h-20 w-20 rounded-full bg-blue-100 flex items-center justify-center mx-auto mb-4">
                <Users className="h-10 w-10 text-blue-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">
                Kontakte aus Adressbuch importieren
              </h3>
              <p className="text-sm text-gray-600 mb-4">
                Importieren Sie vorhandene Kontakte direkt aus Ihrem Adressbuch.
              </p>
              
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3 mb-4 text-left">
                <div className="flex gap-2">
                  <AlertCircle className="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
                  <div className="text-sm text-yellow-900">
                    <p className="font-semibold mb-1">Wichtige Hinweise:</p>
                    <ul className="space-y-1 ml-4 list-disc text-xs">
                      <li>Funktioniert nur auf mobilen Geräten (Android Chrome/Edge)</li>
                      <li>Sie müssen den Zugriff explizit erlauben</li>
                      <li>Es werden nur Kontakte mit Telefonnummern angezeigt</li>
                      <li>Importierte Kontakte müssen verifiziert werden</li>
                    </ul>
                  </div>
                </div>
              </div>

              <Button
                onClick={requestContactAccess}
                disabled={isLoading}
                className="w-full bg-blue-600 hover:bg-blue-700"
              >
                <Upload className="h-4 w-4 mr-2" />
                {isLoading ? 'Lädt...' : 'Zugriff auf Kontakte anfordern'}
              </Button>
            </div>

            <div className="border-t pt-4">
              <p className="text-xs text-gray-500 text-center">
                Alternative: Kontakte manuell hinzufügen
              </p>
              {onClose && (
                <Button
                  onClick={onClose}
                  variant="outline"
                  className="w-full mt-2"
                >
                  Abbrechen
                </Button>
              )}
            </div>
          </>
        ) : (
          <>
            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                type="text"
                placeholder="Kontakte durchsuchen..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>

            {/* Contact List */}
            <div className="space-y-2 max-h-96 overflow-y-auto">
              {filteredContacts.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  <p className="text-sm">Keine Kontakte gefunden</p>
                </div>
              ) : (
                filteredContacts.map((contact) => (
                  <div
                    key={contact.id}
                    className={`flex items-center gap-3 p-3 rounded-lg border-2 cursor-pointer transition-colors ${
                      selectedContacts.has(contact.id)
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                    onClick={() => toggleContact(contact.id)}
                  >
                    <Checkbox
                      checked={selectedContacts.has(contact.id)}
                      onCheckedChange={() => toggleContact(contact.id)}
                    />
                    <div className="flex-1">
                      <p className="font-semibold text-gray-900">{contact.name}</p>
                      <div className="flex items-center gap-1 text-sm text-gray-600">
                        <Phone className="h-3 w-3" />
                        <span>{contact.phone}</span>
                      </div>
                      {contact.allPhones.length > 1 && (
                        <p className="text-xs text-gray-500 mt-1">
                          +{contact.allPhones.length - 1} weitere Nummer(n)
                        </p>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>

            {/* Actions */}
            <div className="flex gap-3 pt-4 border-t">
              <Button
                onClick={handleImport}
                disabled={selectedContacts.size === 0 || isLoading}
                className="flex-1 bg-blue-600 hover:bg-blue-700"
              >
                <CheckCircle className="h-4 w-4 mr-2" />
                {isLoading ? 'Importiere...' : `${selectedContacts.size} Kontakt(e) importieren`}
              </Button>
              {onClose && (
                <Button
                  onClick={onClose}
                  variant="outline"
                >
                  Abbrechen
                </Button>
              )}
            </div>

            {/* Summary */}
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
              <p className="text-xs text-blue-900">
                📋 {contacts.length} Kontakte gefunden • {selectedContacts.size} ausgewählt
              </p>
              <p className="text-xs text-blue-700 mt-1">
                Nach dem Import müssen die Kontakte verifiziert werden.
              </p>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}