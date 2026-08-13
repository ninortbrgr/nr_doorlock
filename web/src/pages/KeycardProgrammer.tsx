import { useState } from 'react';
import { fetchNui } from '../utils/fetchNui';
import { CreditCard, ShieldCheck, User, CheckCircle2 } from 'lucide-react';

export default function KeycardProgrammer() {
  const [ownerName, setOwnerName] = useState('');
  const [accessLevel, setAccessLevel] = useState(1);
  const [faction, setFaction] = useState('lapd');
  const [statusMsg, setStatusMsg] = useState<string | null>(null);

  const handleProgramCard = () => {
    if (!ownerName) {
      setStatusMsg('Bitte einen Inhabernamen eingeben.');
      return;
    }

    fetchNui('programKeycard', {
      ownerName,
      accessLevel,
      faction,
      label: `Keycard - ${ownerName}`
    }).then((response: any) => {
      if (response.success) {
        setStatusMsg('Keycard erfolgreich beschrieben!');
      } else {
        setStatusMsg('Fehler beim Beschreiben der Karte.');
      }
    });
  };

  return (
    <div className="p-8 bg-slate-900 text-slate-100 min-h-screen font-sans flex justify-center items-center">
      <div className="max-w-md w-full bg-slate-800 border border-slate-700 rounded-xl p-6 shadow-2xl">
        <div className="flex items-center gap-3 mb-6 pb-4 border-b border-slate-700">
          <CreditCard className="w-8 h-8 text-blue-400" />
          <div>
            <h2 className="text-xl font-bold">Keycard Terminal</h2>
            <p className="text-xs text-slate-400">NFC-Karten codieren & zuweisen</p>
          </div>
        </div>

        <div className="space-y-4">
          {/* Inhaber */}
          <div>
            <label className="block text-xs font-semibold uppercase text-slate-400 mb-1">
              Inhaber Name
            </label>
            <div className="relative">
              <User className="w-4 h-4 absolute left-3 top-3 text-slate-500" />
              <input
                type="text"
                placeholder="z.B. John Doe"
                value={ownerName}
                onChange={(e) => setOwnerName(e.target.value)}
                className="w-full bg-slate-900 border border-slate-700 rounded-lg pl-9 pr-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-blue-500"
              />
            </div>
          </div>

          {/* Fraktion */}
          <div>
            <label className="block text-xs font-semibold uppercase text-slate-400 mb-1">
              Fraktions-Bindung
            </label>
            <input
              type="text"
              placeholder="z.B. lapd oder sheriff"
              value={faction}
              onChange={(e) => setFaction(e.target.value)}
              className="w-full bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-blue-500"
            />
          </div>

          {/* Access Level Slider */}
          <div>
            <div className="flex justify-between items-center mb-1">
              <label className="text-xs font-semibold uppercase text-slate-400">
                Sicherheitsstufe (Access Level)
              </label>
              <span className="text-sm font-bold text-blue-400">Level {accessLevel}</span>
            </div>
            <input
              type="range"
              min="1"
              max="5"
              value={accessLevel}
              onChange={(e) => setAccessLevel(Number(e.target.value))}
              className="w-full accent-blue-500 cursor-pointer"
            />
          </div>

          {/* Status Message */}
          {statusMsg && (
            <div className="flex items-center gap-2 text-xs text-emerald-400 bg-emerald-950/40 p-3 rounded-lg border border-emerald-800/50">
              <CheckCircle2 className="w-4 h-4" />
              <span>{statusMsg}</span>
            </div>
          )}

          {/* Action Button */}
          <button
            onClick={handleProgramCard}
            className="w-full mt-4 bg-blue-600 hover:bg-blue-500 text-white font-medium py-2.5 rounded-lg transition-colors flex items-center justify-center gap-2 shadow-lg shadow-blue-600/30"
          >
            <ShieldCheck className="w-5 h-5" />
            Karte jetzt beschreiben
          </button>
        </div>
      </div>
    </div>
  );
}