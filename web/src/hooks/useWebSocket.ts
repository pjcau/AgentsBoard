import { useEffect, useRef, useState } from 'react';
import { AgentsBoardWebSocket } from '../api/websocket';
import type { WSEvent } from '../api/types';

export function useWebSocket(channel?: string) {
  const wsRef = useRef<AgentsBoardWebSocket | null>(null);
  const [lastEvent, setLastEvent] = useState<WSEvent | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const ws = new AgentsBoardWebSocket();
    wsRef.current = ws;
    ws.connect();

    const checkConnection = setInterval(() => {
      setIsConnected(ws.isConnected);
    }, 1000);

    const unsubscribe = ws.subscribe(channel ?? '*', (event) => {
      setLastEvent(event);
    });

    return () => {
      clearInterval(checkConnection);
      unsubscribe();
      ws.disconnect();
    };
  }, [channel]);

  return { lastEvent, isConnected };
}
