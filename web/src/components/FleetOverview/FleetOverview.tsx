import { useFleetStats } from '../../hooks/useFleetStats';
import { useSessions } from '../../hooks/useSessions';

export function FleetOverview() {
  const { stats, error: statsError } = useFleetStats();
  const { sessions, error: sessionsError } = useSessions();

  if (statsError || sessionsError) {
    return <div className="card" style={{ color: 'var(--error)' }}>Connection error: {statsError || sessionsError}</div>;
  }

  if (!stats) {
    return <div className="card">Loading fleet data...</div>;
  }

  return (
    <div>
      <div className="stats-grid">
        <div className="stat-card">
          <div className="value">{stats.totalSessions}</div>
          <div className="label">Total Sessions</div>
        </div>
        <div className="stat-card">
          <div className="value">{stats.activeSessions}</div>
          <div className="label">Active</div>
        </div>
        <div className="stat-card">
          <div className="value">{stats.needsInputCount}</div>
          <div className="label">Needs Input</div>
        </div>
        <div className="stat-card">
          <div className="value">{stats.errorCount}</div>
          <div className="label">Errors</div>
        </div>
        <div className="stat-card">
          <div className="value">${stats.totalCost}</div>
          <div className="label">Fleet Cost</div>
        </div>
      </div>

      <h3 style={{ marginBottom: 12 }}>Sessions ({sessions.length})</h3>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 12 }}>
        {sessions.map((s) => (
          <div key={s.sessionId} className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <strong>{s.sessionName}</strong>
              <span className={`state-badge state-${s.state}`}>{s.state}</span>
            </div>
            {s.provider && <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{s.provider} {s.model && `/ ${s.model}`}</div>}
            {s.projectPath && <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 4 }}>{s.projectPath}</div>}
            {s.gitBranch && <div style={{ fontSize: 12, color: 'var(--accent)', marginTop: 2 }}>{s.gitBranch}</div>}
            <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 4 }}>Cost: ${s.totalCost}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
