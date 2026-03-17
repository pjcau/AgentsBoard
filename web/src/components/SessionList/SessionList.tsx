import { useSessions } from '../../hooks/useSessions';

interface Props {
  selectedId: string | null;
  onSelect: (id: string) => void;
}

export function SessionList({ selectedId, onSelect }: Props) {
  const { sessions, error } = useSessions();

  if (error) {
    return <div style={{ padding: 8, color: 'var(--error)', fontSize: 12 }}>Disconnected</div>;
  }

  return (
    <div>
      <div style={{ padding: '8px 4px', fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
        Sessions ({sessions.length})
      </div>
      {sessions.map((s) => (
        <div
          key={s.sessionId}
          onClick={() => onSelect(s.sessionId)}
          className="session-card"
          style={{
            borderColor: selectedId === s.sessionId ? 'var(--accent)' : undefined,
            padding: 10,
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: 13, fontWeight: 500 }}>{s.sessionName}</span>
            <span className={`state-badge state-${s.state}`} style={{ fontSize: 10 }}>{s.state}</span>
          </div>
          {s.provider && (
            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>{s.provider}</div>
          )}
        </div>
      ))}
    </div>
  );
}
