import { useState } from 'react';
import { FleetOverview } from '../FleetOverview/FleetOverview';
import { SessionList } from '../SessionList/SessionList';
import { ActivityLog } from '../ActivityLog/ActivityLog';
import { CostDashboard } from '../CostDashboard/CostDashboard';

type View = 'fleet' | 'activity' | 'costs';

export function App() {
  const [activeView, setActiveView] = useState<View>('fleet');
  const [selectedSessionId, setSelectedSessionId] = useState<string | null>(null);

  return (
    <div className="app-layout">
      <header className="topbar">
        <strong>AgentsBoard</strong>
        <nav style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
          <button onClick={() => setActiveView('fleet')} className={activeView === 'fleet' ? 'active' : ''}>
            Fleet
          </button>
          <button onClick={() => setActiveView('activity')} className={activeView === 'activity' ? 'active' : ''}>
            Activity
          </button>
          <button onClick={() => setActiveView('costs')} className={activeView === 'costs' ? 'active' : ''}>
            Costs
          </button>
        </nav>
      </header>

      <aside className="sidebar">
        <SessionList
          selectedId={selectedSessionId}
          onSelect={setSelectedSessionId}
        />
      </aside>

      <main className="main-content">
        {activeView === 'fleet' && <FleetOverview />}
        {activeView === 'activity' && <ActivityLog />}
        {activeView === 'costs' && <CostDashboard />}
      </main>
    </div>
  );
}
