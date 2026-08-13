import { useEffect, useState } from 'react';
import { fetchNui } from '../utils/fetchNui';
import { Lock, Unlock, Shield, Search } from 'lucide-react';

interface DoorItem {
  id: string;
  name: string;
  owner_faction: string | null;
  default_state: 'LOCKED' | 'UNLOCKED';
  auto_lock_time: number;
  security_level: number;
  state?: 'LOCKED' | 'UNLOCKED';
}

export default function Doors() {
  const [doors, setDoors] = useState<DoorItem[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDoors();
  }, []);

  const loadDoors = () => {
    fetchNui<DoorItem[]>('getAllDoors').then((data) => {
      setDoors(data || []);
      setLoading(false);
    });
  };

  const toggleRemoteDoor = (doorId: string) => {
    fetchNui('toggleDoorRemote', { doorId }).then(() => {
      loadDoors(); // Status neu laden
    });
  };

  const filteredDoors = doors.filter((door) =>
    door.name.toLowerCase().includes(search.toLowerCase()) ||
    (door.owner_faction && door.owner_faction.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className="p-8 bg-slate-900 text-slate-100 min-h-screen font-sans">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold">Tür-Verwaltung</h2>
          
          {/* Suche */}
          <div className="relative w-72">
            <Search className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="Tür oder Fraktion suchen..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-sm text-slate-100 focus:outline-none focus:border-blue-500"
            />
          </div>
        </div>

        {loading ? (
          <div className="text-slate-400">Lade Türen...</div>
        ) : (
          <div className="bg-slate-800 border border-slate-700 rounded-xl overflow-hidden shadow-xl">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-700 bg-slate-800/50 text-slate-400 text-xs uppercase tracking-wider">
                  <th className="p-4">Name</th>
                  <th className="p-4">Fraktion</th>
                  <th className="p-4">Security Level</th>
                  <th className="p-4">Auto-Lock</th>
                  <th className="p-4">Status</th>
                  <th className="p-4 text-right">Aktion</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50 text-sm">
                {filteredDoors.map((door) => (
                  <tr key={door.id} className="hover:bg-slate-700/30 transition-colors">
                    <td className="p-4 font-medium">{door.name}</td>
                    <td className="p-4">
                      {door.owner_faction ? (
                        <span className="px-2.5 py-1 bg-slate-700 text-slate-300 rounded-md text-xs font-semibold">
                          {door.owner_faction.toUpperCase()}
                        </span>
                      ) : (
                        <span className="text-slate-500 text-xs">Global</span>
                      )}
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-1">
                        <Shield className="w-4 h-4 text-blue-400" />
                        <span>Lvl {door.security_level}</span>
                      </div>
                    </td>
                    <td className="p-4 text-slate-400">
                      {door.auto_lock_time > 0 ? `${door.auto_lock_time}s` : 'Aus'}
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold ${
                        door.state === 'LOCKED' ? 'bg-rose-950/40 text-rose-400 border border-rose-800/50' : 'bg-emerald-950/40 text-emerald-400 border border-emerald-800/50'
                      }`}>
                        {door.state === 'LOCKED' ? <Lock className="w-3 h-3" /> : <Unlock className="w-3 h-3" />}
                        {door.state || door.default_state}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <button
                        onClick={() => toggleRemoteDoor(door.id)}
                        className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 rounded-lg text-xs font-medium transition-colors"
                      >
                        Umschalten
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}