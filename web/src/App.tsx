import { useEffect, useState } from 'react';
import KeycardProgrammer from './pages/KeycardProgrammer';
import Dashboard from './Dashboard';

export default function App() {
  const [currentView, setCurrentView] = useState<'none' | 'dashboard' | 'terminal'>('none');
  const [terminalData, setTerminalData] = useState<any>(null);

  useEffect(() => {
    const handleNuiMessage = (event: MessageEvent) => {
      const { action, data } = event.data;

      if (action === 'openTerminal') {
        setTerminalData(data);
        setCurrentView('terminal');
      } else if (action === 'closeUI') {
        setCurrentView('none');
      }
    };

    window.addEventListener('message', handleNuiMessage);
    return () => window.removeEventListener('message', handleNuiMessage);
  }, []);

  if (currentView === 'none') return null;

  return (
    <main className="w-screen h-screen flex items-center justify-center bg-black/60 backdrop-blur-sm">
      {currentView === 'terminal' && <KeycardProgrammer terminalData={terminalData} />}
      {currentView === 'dashboard' && <Dashboard />}
    </main>
  );
}