// WebSocket client with auto-reconnect for real-time events

import type { WSEvent } from './types';

type EventHandler = (event: WSEvent) => void;

export class AgentsBoardWebSocket {
  private ws: WebSocket | null = null;
  private handlers: Map<string, Set<EventHandler>> = new Map();
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private url: string;
  private _isConnected = false;

  constructor(url?: string) {
    const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    this.url = url ?? `${wsProtocol}//${window.location.host}/ws`;
  }

  get isConnected(): boolean {
    return this._isConnected;
  }

  connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN) return;

    this.ws = new WebSocket(this.url);

    this.ws.onopen = () => {
      this._isConnected = true;
      console.log('[WS] Connected');
      if (this.reconnectTimer) {
        clearTimeout(this.reconnectTimer);
        this.reconnectTimer = null;
      }
    };

    this.ws.onmessage = (msg) => {
      try {
        const event: WSEvent = JSON.parse(msg.data);
        this.dispatch(event);
      } catch {
        console.warn('[WS] Failed to parse message:', msg.data);
      }
    };

    this.ws.onclose = () => {
      this._isConnected = false;
      console.log('[WS] Disconnected, reconnecting in 3s...');
      this.scheduleReconnect();
    };

    this.ws.onerror = () => {
      this._isConnected = false;
    };
  }

  disconnect(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    this.ws?.close();
    this.ws = null;
    this._isConnected = false;
  }

  subscribe(channel: string, handler: EventHandler): () => void {
    if (!this.handlers.has(channel)) {
      this.handlers.set(channel, new Set());
    }
    this.handlers.get(channel)!.add(handler);

    // Return unsubscribe function
    return () => {
      this.handlers.get(channel)?.delete(handler);
    };
  }

  private dispatch(event: WSEvent): void {
    const channelHandlers = this.handlers.get(event.channel);
    if (channelHandlers) {
      for (const handler of channelHandlers) {
        handler(event);
      }
    }
    // Also dispatch to wildcard subscribers
    const wildcardHandlers = this.handlers.get('*');
    if (wildcardHandlers) {
      for (const handler of wildcardHandlers) {
        handler(event);
      }
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, 3000);
  }
}
