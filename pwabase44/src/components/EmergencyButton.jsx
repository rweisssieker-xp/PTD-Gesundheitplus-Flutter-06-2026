import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { AlertCircle, Settings } from "lucide-react";
import { Link } from "react-router-dom";
import { createPageUrl } from "@/utils";
import EmergencyTrigger from "./EmergencyTrigger";

/**
 * EmergencyButton Component
 * Displays a prominent SOS button and manages emergency trigger flow
 */
export default function EmergencyButton() {
  const [showTrigger, setShowTrigger] = useState(false);

  return (
    <>
      <div className="relative">
        <Button
          onClick={() => setShowTrigger(true)}
          className="w-full h-24 bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 text-white shadow-2xl border-4 border-red-800 relative overflow-hidden group"
        >
          <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-20 transition-opacity animate-pulse"></div>
          <div className="flex flex-col items-center gap-2 relative z-10">
            <AlertCircle className="h-10 w-10 animate-pulse" />
            <span className="text-xl font-bold">🚨 NOTFALL</span>
            <span className="text-xs font-normal">Im Notfall hier drücken</span>
          </div>
        </Button>
        
        <Link to={createPageUrl("Notfall-Einrichtung")}>
          <Button
            variant="ghost"
            size="sm"
            className="absolute top-2 right-2 h-8 w-8 p-0 bg-white/20 hover:bg-white/30"
          >
            <Settings className="h-4 w-4" />
          </Button>
        </Link>
      </div>

      {showTrigger && (
        <EmergencyTrigger onClose={() => setShowTrigger(false)} />
      )}
    </>
  );
}