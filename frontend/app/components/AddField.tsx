"use client";

import { useState } from "react";
import dynamic from "next/dynamic";
import { Plus, MapPin, X } from "lucide-react";
import { useTranslations } from "next-intl";

const Map = dynamic(() => import("../components/Map"), {
  ssr: false,
  loading: () => (
    <div className="h-[400px] w-full bg-[#1a2e1a] animate-pulse rounded-lg flex items-center justify-center text-gray-500">
      Loading Map...
    </div>
  ),
});

export default function AddField() {
  const [showModal, setShowModal] = useState(false);
  const [selectedLocation, setSelectedLocation] = useState<{
    lat: number;
    lng: number;
  } | null>(null);
  const t = useTranslations("dashboard.actions");

  const handleLocationSelect = (lat: number, lng: number) => {
    setSelectedLocation({ lat, lng });
  };

  return (
    <>
      <button
        onClick={() => setShowModal(true)}
        className="glass-card rounded-xl p-6 flex flex-col items-center justify-center gap-3 group cursor-pointer w-full h-full hover:bg-[#4ade80]/5 transition-all"
      >
        <div className="p-3 rounded-full bg-[#4ade80]/10 group-hover:bg-[#4ade80]/20 transition-colors">
          <Plus className="text-[#4ade80]" size={24} />
        </div>
        <span className="text-gray-300 font-medium group-hover:text-white transition-colors">
          {t("add")}
        </span>
      </button>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="bg-[#0E1A0E] border border-[#879d7b]/30 rounded-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in duration-300">
            <div className="p-4 border-b border-[#879d7b]/20 flex items-center justify-between bg-[#1a2e1a]/50">
              <h3 className="text-xl font-bold text-white flex items-center gap-2">
                <MapPin className="text-[#4ade80]" />
                Add New Field
              </h3>
              <button
                onClick={() => setShowModal(false)}
                className="p-2 hover:bg-white/10 rounded-full transition-colors"
              >
                <X className="text-gray-400 hover:text-white" />
              </button>
            </div>

            <div className="p-6 overflow-y-auto flex-1">
              <div className="mb-6">
                <p className="text-gray-400 mb-4">
                  Click on the map to select your field location.
                </p>
                <div className="rounded-xl overflow-hidden border border-[#879d7b]/30 h-[400px]">
                  <Map onLocationSelect={handleLocationSelect} />
                </div>
              </div>

              {selectedLocation && (
                <div className="bg-[#4ade80]/10 border border-[#4ade80]/30 rounded-xl p-4 flex items-center justify-between animate-in slide-in-from-bottom-2">
                  <div>
                    <p className="text-[#4ade80] font-bold text-sm uppercase tracking-wider">
                      Selected Location
                    </p>
                    <p className="text-white font-mono text-sm mt-1">
                      {selectedLocation.lat.toFixed(6)},{" "}
                      {selectedLocation.lng.toFixed(6)}
                    </p>
                  </div>
                  <button
                    onClick={() => {
                      // Save logic would go here
                      setShowModal(false);
                    }}
                    className="bg-[#4ade80] text-[#050b05] px-6 py-2 rounded-lg font-bold hover:bg-[#22c55e] transition-colors shadow-[0_0_15px_rgba(74,222,128,0.3)]"
                  >
                    Confirm Location
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
