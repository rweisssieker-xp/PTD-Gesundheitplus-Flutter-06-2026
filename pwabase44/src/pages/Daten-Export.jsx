import React, { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import * as XLSX from "xlsx";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Download, FileSpreadsheet, FileText, CheckCircle, Loader2, Shield, AlertTriangle } from "lucide-react";

const EXPORT_SECTIONS = [
  { key: "medications",       label: "Medikamente",           entity: "Medication",           color: "bg-blue-100 text-blue-800" },
  { key: "appointments",      label: "Termine",               entity: "Appointment",           color: "bg-green-100 text-green-800" },
  { key: "bloodpressure",     label: "Blutdruckwerte",         entity: "BloodPressureLog",      color: "bg-red-100 text-red-800" },
  { key: "weight",            label: "Gewichtsverlauf",        entity: "WeightLog",             color: "bg-yellow-100 text-yellow-800" },
  { key: "allergies",         label: "Allergien",              entity: "Allergy",               color: "bg-orange-100 text-orange-800" },
  { key: "vaccinations",      label: "Impfungen",              entity: "Vaccination",           color: "bg-purple-100 text-purple-800" },
  { key: "emergencycontacts", label: "Notfallkontakte",        entity: "EmergencyContact",      color: "bg-pink-100 text-pink-800" },
  { key: "treatmenthistory",  label: "Behandlungshistorie",    entity: "TreatmentHistory",      color: "bg-teal-100 text-teal-800" },
  { key: "preventivecare",    label: "Vorsorgeuntersuchungen", entity: "PreventiveCare",        color: "bg-indigo-100 text-indigo-800" },
  { key: "medicationlogs",    label: "Medikamenten-Tageslog",  entity: "MedicationLog",         color: "bg-cyan-100 text-cyan-800" },
];

function flattenObject(obj, prefix = "") {
  return Object.keys(obj || {}).reduce((acc, key) => {
    const val = obj[key];
    const newKey = prefix ? `${prefix}.${key}` : key;
    if (val && typeof val === "object" && !Array.isArray(val) && !(val instanceof Date)) {
      Object.assign(acc, flattenObject(val, newKey));
    } else if (Array.isArray(val)) {
      acc[newKey] = val.map(v => (typeof v === "object" ? JSON.stringify(v) : v)).join("; ");
    } else {
      acc[newKey] = val;
    }
    return acc;
  }, {});
}

export default function DatenExportPage() {
  const [selected, setSelected] = useState(new Set(EXPORT_SECTIONS.map(s => s.key)));
  const [loading, setLoading] = useState(false);
  const [counts, setCounts] = useState({});
  const [loadingCounts, setLoadingCounts] = useState(false);

  const toggleSection = (key) => {
    setSelected(prev => {
      const next = new Set(prev);
      next.has(key) ? next.delete(key) : next.add(key);
      return next;
    });
  };

  const loadCounts = async () => {
    setLoadingCounts(true);
    const results = {};
    await Promise.all(
      EXPORT_SECTIONS.map(async (s) => {
        try {
          const data = await base44.entities[s.entity].list();
          results[s.key] = data.length;
        } catch {
          results[s.key] = 0;
        }
      })
    );
    setCounts(results);
    setLoadingCounts(false);
  };

  React.useEffect(() => { loadCounts(); }, []);

  const fetchAllData = async () => {
    const result = {};
    await Promise.all(
      EXPORT_SECTIONS.filter(s => selected.has(s.key)).map(async (s) => {
        try {
          const data = await base44.entities[s.entity].list();
          result[s.key] = { label: s.label, data };
        } catch {
          result[s.key] = { label: s.label, data: [] };
        }
      })
    );
    return result;
  };

  const exportExcel = async () => {
    setLoading(true);
    const allData = await fetchAllData();
    const wb = XLSX.utils.book_new();
    Object.values(allData).forEach(({ label, data }) => {
      if (data.length === 0) {
        const ws = XLSX.utils.aoa_to_sheet([["Keine Daten vorhanden"]]);
        XLSX.utils.book_append_sheet(wb, ws, label.substring(0, 31));
        return;
      }
      const flat = data.map(row => flattenObject(row));
      const ws = XLSX.utils.json_to_sheet(flat);
      XLSX.utils.book_append_sheet(wb, ws, label.substring(0, 31));
    });
    const date = new Date().toISOString().split("T")[0];
    XLSX.writeFile(wb, `Gesundheitsakte_${date}.xlsx`);
    setLoading(false);
  };

  const exportCSV = async () => {
    setLoading(true);
    const allData = await fetchAllData();
    const parts = [];
    Object.values(allData).forEach(({ label, data }) => {
      parts.push(`\n\n=== ${label} ===`);
      if (data.length === 0) {
        parts.push("Keine Daten vorhanden");
        return;
      }
      const flat = data.map(row => flattenObject(row));
      const headers = [...new Set(flat.flatMap(r => Object.keys(r)))];
      parts.push(headers.join(","));
      flat.forEach(row => {
        parts.push(headers.map(h => {
          const v = row[h] ?? "";
          return `"${String(v).replace(/"/g, '""')}"`;
        }).join(","));
      });
    });
    const blob = new Blob([parts.join("\n")], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    const date = new Date().toISOString().split("T")[0];
    a.download = `Gesundheitsakte_${date}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    setLoading(false);
  };

  const totalRecords = Object.values(counts).reduce((a, b) => a + b, 0);
  const selectedRecords = EXPORT_SECTIONS
    .filter(s => selected.has(s.key))
    .reduce((a, s) => a + (counts[s.key] || 0), 0);

  return (
    <div className="p-4 space-y-4">
      <div className="text-center py-4">
        <h2 className="text-2xl font-bold text-gray-900">Daten-Export</h2>
        <p className="text-gray-500 text-sm mt-1">Ihre Gesundheitsakte als Datei herunterladen</p>
      </div>

      {/* Datenschutz-Hinweis */}
      <Card className="border-amber-200 bg-amber-50">
        <CardContent className="pt-4 pb-3">
          <div className="flex gap-3 items-start">
            <Shield className="h-5 w-5 text-amber-600 mt-0.5 shrink-0" />
            <p className="text-sm text-amber-800">
              Die exportierte Datei enthält sensible Gesundheitsdaten. Bitte speichern Sie diese nur auf vertrauenswürdigen Geräten und geben Sie sie nur an autorisierte Personen weiter.
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Übersicht */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base flex items-center justify-between">
            <span>Datenbereiche auswählen</span>
            {loadingCounts ? (
              <Loader2 className="h-4 w-4 animate-spin text-gray-400" />
            ) : (
              <span className="text-sm font-normal text-gray-500">{totalRecords} Einträge gesamt</span>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <div className="flex gap-2 mb-3">
            <Button variant="outline" size="sm" onClick={() => setSelected(new Set(EXPORT_SECTIONS.map(s => s.key)))}>
              Alle wählen
            </Button>
            <Button variant="outline" size="sm" onClick={() => setSelected(new Set())}>
              Alle abwählen
            </Button>
          </div>
          {EXPORT_SECTIONS.map((s) => (
            <div
              key={s.key}
              onClick={() => toggleSection(s.key)}
              className={`flex items-center justify-between p-3 rounded-lg border-2 cursor-pointer transition-all ${
                selected.has(s.key) ? "border-blue-500 bg-blue-50" : "border-gray-200 bg-white"
              }`}
            >
              <div className="flex items-center gap-3">
                {selected.has(s.key) ? (
                  <CheckCircle className="h-5 w-5 text-blue-500" />
                ) : (
                  <div className="h-5 w-5 rounded-full border-2 border-gray-300" />
                )}
                <span className="font-medium text-sm text-gray-800">{s.label}</span>
              </div>
              <Badge className={s.color}>
                {counts[s.key] !== undefined ? `${counts[s.key]} Einträge` : "..."}
              </Badge>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Export-Buttons */}
      <Card>
        <CardContent className="pt-4 space-y-3">
          <div className="text-center text-sm text-gray-500 mb-1">
            {selected.size} Bereiche · {selectedRecords} Einträge werden exportiert
          </div>

          {selected.size === 0 && (
            <div className="flex items-center gap-2 text-amber-600 text-sm justify-center">
              <AlertTriangle className="h-4 w-4" />
              Bitte mindestens einen Bereich auswählen
            </div>
          )}

          <Button
            onClick={exportExcel}
            disabled={loading || selected.size === 0}
            className="w-full h-14 bg-green-600 hover:bg-green-700 text-white text-base font-semibold"
          >
            {loading ? <Loader2 className="h-5 w-5 animate-spin mr-2" /> : <FileSpreadsheet className="h-5 w-5 mr-2" />}
            Als Excel (.xlsx) herunterladen
          </Button>

          <Button
            onClick={exportCSV}
            disabled={loading || selected.size === 0}
            variant="outline"
            className="w-full h-14 text-base font-semibold border-2"
          >
            {loading ? <Loader2 className="h-5 w-5 animate-spin mr-2" /> : <FileText className="h-5 w-5 mr-2" />}
            Als CSV herunterladen
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}