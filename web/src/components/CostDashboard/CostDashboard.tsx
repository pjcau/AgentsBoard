import React, { useState, useEffect, useCallback } from 'react';
import type { CostSummary, CostEntry } from '../../api/types';
import { getCosts, getCostHistory } from '../../api/client';

export function CostDashboard() {
  const [summary, setSummary] = useState<CostSummary | null>(null);
  const [history, setHistory] = useState<CostEntry[]>([]);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      const [s, h] = await Promise.all([getCosts(), getCostHistory()]);
      setSummary(s);
      setHistory(h);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error');
    }
  }, []);

  useEffect(() => {
    refresh();
    const id = setInterval(refresh, 10000);
    return () => clearInterval(id);
  }, [refresh]);

  if (error) {
    return <div className="card" style={{ color: 'var(--error)' }}>Error: {error}</div>;
  }

  return (
    <div>
      <h3 style={{ marginBottom: 12 }}>Cost Dashboard</h3>

      {summary && (
        <div className="stats-grid" style={{ marginBottom: 16 }}>
          <div className="stat-card">
            <div className="value">${summary.fleetTotal}</div>
            <div className="label">Fleet Total</div>
          </div>
        </div>
      )}

      <div className="card" style={{ padding: 0 }}>
        <div style={{ padding: '12px 16px', borderBottom: '1px solid var(--border)', fontWeight: 600 }}>
          Recent Cost History
        </div>
        {history.length === 0 && (
          <div style={{ padding: 16, color: 'var(--text-muted)' }}>No cost data yet</div>
        )}
        {history.map((entry, i) => (
          <div key={i} className="activity-item">
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>
                <strong>{entry.provider}</strong> / {entry.model}
              </span>
              <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--warning)' }}>
                ${entry.cost}
              </span>
            </div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>
              {entry.inputTokens} in / {entry.outputTokens} out | {new Date(entry.timestamp).toLocaleString()}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
