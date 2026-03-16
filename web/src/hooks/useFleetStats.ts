import { useState, useEffect, useCallback } from 'react';
import type { FleetStats } from '../api/types';
import { getFleetStats } from '../api/client';

export function useFleetStats(pollInterval = 5000) {
  const [stats, setStats] = useState<FleetStats | null>(null);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      const data = await getFleetStats();
      setStats(data);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error');
    }
  }, []);

  useEffect(() => {
    refresh();
    const id = setInterval(refresh, pollInterval);
    return () => clearInterval(id);
  }, [refresh, pollInterval]);

  return { stats, error, refresh };
}
