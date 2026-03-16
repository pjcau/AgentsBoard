import React, { useState, useEffect, useCallback } from 'react';
import type { ActivityEvent } from '../../api/types';
import { getActivity } from '../../api/client';

export function ActivityLog() {
  const [events, setEvents] = useState<ActivityEvent[]>([]);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      const data = await getActivity({ limit: 200 });
      setEvents(data);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error');
    }
  }, []);

  useEffect(() => {
    refresh();
    const id = setInterval(refresh, 5000);
    return () => clearInterval(id);
  }, [refresh]);

  if (error) {
    return <div className="card" style={{ color: 'var(--error)' }}>Error: {error}</div>;
  }

  return (
    <div>
      <h3 style={{ marginBottom: 12 }}>Activity Log</h3>
      <div className="card" style={{ padding: 0 }}>
        {events.length === 0 && (
          <div style={{ padding: 16, color: 'var(--text-muted)' }}>No activity yet</div>
        )}
        {events.map((event) => (
          <div key={event.id} className="activity-item">
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>
                <strong style={{ marginRight: 8 }}>{event.eventType}</strong>
                {event.details}
              </span>
              <span className="timestamp">
                {new Date(event.timestamp).toLocaleTimeString()}
              </span>
            </div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>
              Session: {event.sessionId.slice(0, 8)}
              {event.cost && ` | Cost: $${event.cost}`}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
