import React, { useEffect, useState } from 'react';
// Passe den Pfad an, je nachdem wo dashboard.tsx liegt:
// Liegt dashboard.tsx in src/: './utils/fetchNui'
// Liegt dashboard.tsx in src/pages/: '../utils/fetchNui'
import { fetchNui } from './utils/fetchNui'; 
import { ShieldAlert, DoorClosed, CreditCard, Activity, X } from 'lucide-react';

interface DashboardStats {
  totalDoors: number;
  activeCredentials: number;
  recentAlarms: number;
  lockedDoors: number;
}

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchNui<DashboardStats>('getDashboardStats').then((data: DashboardStats) => {
      setStats(data);
      setLoading(false);
    });
  }, []);

  const closeMenu = () => {
    fetchNui('closeUI');
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 p-8 font-sans">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex justify-between items-center mb-8 pb-4 border-b border-slate-700">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Access Control Center</h1>
            <p className="text-slate-400 mt-1">Systemübersicht und Sicherheitsstatus</p>
          </div>
          <button 
            onClick={closeMenu}
            className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg transition-colors"
          >
            <X className="w-6 h-6 text-slate-300" />
          </button>
        </div>

        {/* Stat Cards */}
        {loading ? (
          <div className="text-slate-400 animate-pulse">Lade Systemdaten...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <StatCard 
              title="Registrierte Türen" 
              value={stats?.totalDoors || 0} 
              icon={<DoorClosed className="w-8 h-8 text-blue-400" />} 
            />
            <StatCard 
              title="Aktive Credentials" 
              value={stats?.activeCredentials || 0} 
              icon={<CreditCard className="w-8 h-8 text-emerald-400" />} 
            />
            <StatCard 
              title="Verschlossene Türen" 
              value={stats?.lockedDoors || 0} 
              icon={<ShieldAlert className="w-8 h-8 text-amber-400" />} 
            />
            <StatCard 
              title="Aktive Alarme" 
              value={stats?.recentAlarms || 0} 
              icon={<Activity className="w-8 h-8 text-rose-500" />} 
              isAlert={stats?.recentAlarms ? stats.recentAlarms > 0 : false}
            />
          </div>
        )}
      </div>
    </div>
  );
}

function StatCard({ 
  title, 
  value, 
  icon, 
  isAlert = false 
}: { 
  title: string; 
  value: number | string; 
  icon: React.ReactNode; 
  isAlert?: boolean; 
}) {
  return (
    <div className={`p-6 rounded-xl border ${isAlert ? 'bg-rose-950/20 border-rose-500/50' : 'bg-slate-800 border-slate-700'} shadow-lg`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-slate-400 mb-1">{title}</p>
          <p className="text-3xl font-semibold">{value}</p>
        </div>
        <div className="p-3 bg-slate-900/50 rounded-lg">
          {icon}
        </div>
      </div>
    </div>
  );
}