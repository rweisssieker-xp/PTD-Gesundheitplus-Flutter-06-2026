import React from "react";
import { useNavigate, useLocation } from "react-router-dom";
import StorageModeGate from "@/components/StorageModeGate";
import { ArrowLeft, Home, Settings, Play, Shield } from "lucide-react";
import { Button } from "@/components/ui/button";
import NotificationCenter from "@/components/NotificationCenter";
import LanguageSwitcher from "@/components/LanguageSwitcher";
import OfflineIndicator from "@/components/OfflineIndicator";
import OfflineManager from "@/components/OfflineManager";
import DementiaReminderService from "@/components/DementiaReminderService";
import ProactiveHealthMonitor from "@/components/ProactiveHealthMonitor";
import MedicationReminderService from "@/components/MedicationReminderService";
import PreventiveCareReminderService from "@/components/PreventiveCareReminderService";
import { LanguageProvider } from "@/components/LanguageProvider";
import { Link } from "react-router-dom";
import { createPageUrl } from "@/utils";
import { useStorage } from "@/lib/StorageContext";

function StorageBadge() {
  const { isLocal } = useStorage();
  if (!isLocal) return null;
  return (
    <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full border border-green-200 flex items-center gap-1">
      <Shield className="h-3 w-3" />Lokal
    </span>
  );
}

function LayoutContent({ children, currentPageName }) {
  const navigate = useNavigate();
  const location = useLocation();
  const isHomePage = location.pathname === "/" || currentPageName === "Home";

  return (
    <StorageModeGate>
      <div className="min-h-screen bg-gradient-to-b from-red-50 to-white flex flex-col">
        <OfflineManager />
        <DementiaReminderService />
        <ProactiveHealthMonitor />
        <MedicationReminderService />
        <PreventiveCareReminderService />
        
        <OfflineIndicator />

        <header className="bg-white border-b-4 border-red-600 shadow-md sticky top-0 z-50">
          <div className="max-w-md mx-auto px-4 py-4">
            <div className="flex items-center justify-between">
              {!isHomePage && (
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={() => navigate(-1)}
                    className="h-12 w-12 border-2"
                  >
                    <ArrowLeft className="h-6 w-6" />
                  </Button>
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={() => navigate("/")}
                    className="h-12 w-12 border-2"
                  >
                    <Home className="h-6 w-6" />
                  </Button>
                </div>
              )}
              <div className={isHomePage ? "mx-auto text-center" : "flex-1 text-center"}>
                <h1 className="text-2xl font-bold text-gray-900">Gesundheit Plus</h1>
                <div className="flex items-center justify-center gap-2">
                  <p className="text-xs text-gray-500">Ihre digitale Gesundheitsakte</p>
                  <StorageBadge />
                </div>
              </div>
              <div className="flex items-center gap-2">
                <LanguageSwitcher />
                <NotificationCenter />
                <Link to={createPageUrl("Datenschutz")}>
                  <Button variant="ghost" size="icon" className="h-10 w-10">
                    <Settings className="h-5 w-5 text-gray-600" />
                  </Button>
                </Link>
              </div>
              {!isHomePage && <div className="w-0"></div>}
            </div>
          </div>
        </header>

        <main className="flex-1 max-w-md mx-auto w-full">
          {children}
        </main>

        <footer className="bg-white border-t-2 border-gray-200 mt-auto">
          <div className="max-w-md mx-auto px-4 py-6">
            <div className="flex flex-col items-center justify-center gap-3">
              <Link to={createPageUrl("Onboarding")} className="w-full">
                <Button className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white shadow-lg">
                  <Play className="h-5 w-5 mr-2" />
                  Demo / Onboarding starten
                </Button>
              </Link>
              <div className="flex items-center gap-4 text-xs text-gray-500">
                <Link to={createPageUrl("Datenschutz")} className="hover:text-gray-900 hover:underline">
                  Datenschutz
                </Link>
                <span>•</span>
                <Link to="/Speicher-Modus" className="hover:text-gray-900 hover:underline flex items-center gap-1">
                  <Shield className="h-3 w-3" />
                  Speicher-Modus
                </Link>
                <span>•</span>
                <a href="mailto:kontakt@gesundheit-plus.de" className="hover:text-gray-900 hover:underline">
                  Kontakt
                </a>
              </div>
              <p className="text-xs text-gray-500 text-center">
                Eine Initiative für Ihre Gesundheit
              </p>
            </div>
          </div>
        </footer>
      </div>
    </StorageModeGate>
  );
}

export default function Layout({ children, currentPageName }) {
  return (
    <LanguageProvider>
      <LayoutContent children={children} currentPageName={currentPageName} />
    </LanguageProvider>
  );
}