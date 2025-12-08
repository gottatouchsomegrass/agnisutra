"use client";

import Header from "../components/HeaderDashboard";
import { useAuth } from "../hooks/useAuth";
import { MapPin, Sprout, ArrowLeft } from "lucide-react";
import Link from "next/link";

export default function MyFieldsPage() {
  const { user } = useAuth();
  const userName = user?.name || "Farmer";

  // Mock data since backend storage isn't implemented yet
  const fields = [
    {
      id: 1,
      name: "Main Farm",
      crop: "Soybean",
      area: "2.5 acres",
      location: "20.5937, 78.9629",
    },
    {
      id: 2,
      name: "North Plot",
      crop: "Wheat",
      area: "1.2 acres",
      location: "20.6000, 78.9700",
    },
  ];

  return (
    <div className="min-h-screen bg-[#050b05] text-white">
      <Header userName={userName} showIcons={true} />

      <main className="max-w-7xl mx-auto px-4 md:px-6 py-8 space-y-8">
        <div className="flex items-center gap-4">
          <Link
            href="/dashboard"
            className="p-2 rounded-full bg-white/5 hover:bg-white/10 transition-colors"
          >
            <ArrowLeft size={20} />
          </Link>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-white to-gray-400 bg-clip-text text-transparent">
            My Fields
          </h1>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {fields.map((field) => (
            <div
              key={field.id}
              className="glass-card p-6 rounded-xl border border-[#879d7b]/20 hover:border-[#4ade80]/50 transition-all group"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="p-3 rounded-full bg-[#4ade80]/10 group-hover:bg-[#4ade80]/20 transition-colors">
                  <Sprout className="text-[#4ade80]" size={24} />
                </div>
                <span className="text-xs font-mono text-gray-500 bg-white/5 px-2 py-1 rounded">
                  ID: {field.id}
                </span>
              </div>

              <h3 className="text-xl font-bold text-white mb-2">
                {field.name}
              </h3>

              <div className="space-y-2 text-sm text-gray-400">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-yellow-500"></span>
                  <span>
                    Crop: <span className="text-white">{field.crop}</span>
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-blue-500"></span>
                  <span>
                    Area: <span className="text-white">{field.area}</span>
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <MapPin size={14} />
                  <span className="truncate">{field.location}</span>
                </div>
              </div>

              <div className="mt-6 pt-4 border-t border-white/5 flex gap-2">
                <button className="flex-1 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-sm font-medium transition-colors">
                  View Details
                </button>
                <button className="flex-1 py-2 rounded-lg bg-[#4ade80]/10 hover:bg-[#4ade80]/20 text-[#4ade80] text-sm font-medium transition-colors">
                  Analysis
                </button>
              </div>
            </div>
          ))}

          {/* Add New Field Card */}
          <button className="glass-card p-6 rounded-xl border border-[#879d7b]/20 border-dashed hover:border-[#4ade80] transition-all flex flex-col items-center justify-center gap-4 group min-h-[250px]">
            <div className="p-4 rounded-full bg-[#4ade80]/10 group-hover:bg-[#4ade80] transition-colors">
              <MapPin
                className="text-[#4ade80] group-hover:text-[#050b05]"
                size={32}
              />
            </div>
            <span className="text-gray-400 group-hover:text-white font-medium">
              Add New Field
            </span>
          </button>
        </div>
      </main>
    </div>
  );
}
