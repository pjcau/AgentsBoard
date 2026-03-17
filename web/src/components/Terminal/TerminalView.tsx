import { useRef, useEffect } from 'react';
import { Terminal } from '@xterm/xterm';
import { FitAddon } from '@xterm/addon-fit';
import { WebglAddon } from '@xterm/addon-webgl';
import '@xterm/xterm/css/xterm.css';

interface Props {
  sessionId: string;
  wsUrl?: string;
}

export function TerminalView({ sessionId, wsUrl }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const terminalRef = useRef<Terminal | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    const terminal = new Terminal({
      fontFamily: "'SF Mono', 'JetBrains Mono', monospace",
      fontSize: 13,
      theme: {
        background: '#1e1e2e',
        foreground: '#cdd6f4',
        cursor: '#f5e0dc',
        selectionBackground: '#585b70',
      },
    });

    const fitAddon = new FitAddon();
    terminal.loadAddon(fitAddon);
    terminal.open(containerRef.current);

    try {
      const webglAddon = new WebglAddon();
      terminal.loadAddon(webglAddon);
    } catch {
      console.warn('[Terminal] WebGL not available, using canvas renderer');
    }

    fitAddon.fit();
    terminalRef.current = terminal;

    // Connect to terminal stream via WebSocket
    const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const url = wsUrl ?? `${wsProtocol}//${window.location.host}/api/v1/sessions/${sessionId}/terminal/stream`;
    const ws = new WebSocket(url);

    ws.onmessage = (event) => {
      // Server sends base64-encoded terminal output
      try {
        const data = atob(event.data);
        terminal.write(data);
      } catch {
        terminal.write(event.data);
      }
    };

    terminal.onData((data) => {
      ws.send(data);
    });

    const resizeObserver = new ResizeObserver(() => fitAddon.fit());
    resizeObserver.observe(containerRef.current);

    return () => {
      resizeObserver.disconnect();
      ws.close();
      terminal.dispose();
    };
  }, [sessionId, wsUrl]);

  return <div ref={containerRef} className="terminal-container" />;
}
