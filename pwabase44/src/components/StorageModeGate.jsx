import React, { useState } from 'react';
import { useStorage } from '@/lib/StorageContext';
import StorageModeSelector from './StorageModeSelector';
import { Card, CardContent } from '@/components/ui/card';
import { Shield } from 'lucide-react';

/**
 * Shows a full-screen mode selector on first use.
 * Once a mode is chosen it's persisted and never shown again.
 */
export default function StorageModeGate({ children }) {
  const { isChosen, setMode } = useStorage();
  const [dismissed, setDismissed] = useState(false);

  if (isChosen || dismissed) {
    return <>{children}</>;
  }

  return (
    <div className="fixed inset-0 z-50 bg-gradient-to-b from-red-50 to-white flex items-center justify-center p-6 overflow-y-auto">
      <div className="max-w-md w-full">
        <div className="text-center mb-2">
          <h1 className="text-2xl font-bold text-gray-900">Gesundheit Plus</h1>
          <p className="text-gray-500 text-sm">Ersteinrichtung der Datenspeicherung</p>
        </div>
        <StorageModeSelector onSelected={(mode) => setMode(mode)} />
      </div>
    </div>
  );
}