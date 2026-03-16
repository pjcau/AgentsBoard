// Typed HTTP client for AgentsBoard REST API

import type {
  Session,
  FleetStats,
  ActivityEvent,
  CostSummary,
  CostEntry,
  AppConfig,
  ThemesInfo,
  TerminalOutput,
} from './types';

const BASE_URL = '/api/v1';

async function fetchJSON<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...init,
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`HTTP ${res.status}: ${body}`);
  }
  return res.json();
}

// Sessions
export const getSessions = () => fetchJSON<Session[]>('/sessions');
export const getSession = (id: string) => fetchJSON<Session>(`/sessions/${id}`);
export const sendInput = (id: string, text: string) =>
  fetchJSON<{ status: string }>(`/sessions/${id}/input`, {
    method: 'POST',
    body: JSON.stringify({ text }),
  });
export const archiveSession = (id: string) =>
  fetchJSON<{ status: string }>(`/sessions/${id}/archive`, { method: 'POST' });
export const deleteSession = (id: string) =>
  fetchJSON<{ status: string }>(`/sessions/${id}`, { method: 'DELETE' });

// Fleet
export const getFleetStats = () => fetchJSON<FleetStats>('/fleet/stats');

// Activity
export const getActivity = (opts?: { limit?: number; session?: string }) => {
  const params = new URLSearchParams();
  if (opts?.limit) params.set('limit', String(opts.limit));
  if (opts?.session) params.set('session', opts.session);
  const qs = params.toString();
  return fetchJSON<ActivityEvent[]>(`/activity${qs ? '?' + qs : ''}`);
};

// Costs
export const getCosts = () => fetchJSON<CostSummary>('/costs');
export const getSessionCost = (id: string) =>
  fetchJSON<{ sessionId: string; totalCost: string }>(`/costs/session/${id}`);
export const getCostHistory = (from?: string, to?: string) => {
  const params = new URLSearchParams();
  if (from) params.set('from', from);
  if (to) params.set('to', to);
  const qs = params.toString();
  return fetchJSON<CostEntry[]>(`/costs/history${qs ? '?' + qs : ''}`);
};

// Config
export const getConfig = () => fetchJSON<AppConfig>('/config');
export const getThemes = () => fetchJSON<ThemesInfo>('/themes');
export const setTheme = (name: string) =>
  fetchJSON<{ status: string }>('/themes', {
    method: 'PUT',
    body: JSON.stringify({ name }),
  });

// Terminal
export const getTerminalOutput = (id: string, lines?: number) => {
  const qs = lines ? `?lines=${lines}` : '';
  return fetchJSON<TerminalOutput>(`/sessions/${id}/output${qs}`);
};
