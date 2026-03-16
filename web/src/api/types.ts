// Mirror of Swift Codable types from AgentsBoardCore

export interface Session {
  sessionId: string;
  sessionName: string;
  state: AgentState;
  provider: string | null;
  model: string | null;
  totalCost: string;
  projectPath: string | null;
  startTime: string;
  lastEventTime: string | null;
  launchCommand: string | null;
  gitBranch: string | null;
  isArchived: boolean;
}

export type AgentState = 'working' | 'needsInput' | 'error' | 'inactive';

export interface FleetStats {
  totalSessions: number;
  activeSessions: number;
  needsInputCount: number;
  errorCount: number;
  totalCost: string;
  costByProvider: Record<string, string>;
  sessionsByState: Record<string, number>;
}

export interface ActivityEvent {
  id: string;
  sessionId: string;
  eventType: string;
  details: string;
  timestamp: string;
  cost: string | null;
}

export interface CostSummary {
  fleetTotal: string;
}

export interface CostEntry {
  sessionId: string;
  provider: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  cost: string;
  timestamp: string;
}

export interface AppConfig {
  theme: string;
  fontFamily: string;
  fontSize: number;
  notifications: boolean;
  scrollback: number;
  layout: string;
  menuBarMode: boolean;
}

export interface ThemesInfo {
  active: string;
  available: string[];
}

export interface TerminalOutput {
  sessionId: string;
  output: string;
  totalLines: number;
}

export interface WSEvent {
  channel: string;
  event: string;
  data: unknown;
  timestamp: string;
}
