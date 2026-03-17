// MARK: - Control Server (Step 13.2)
// Unix socket server for agentsctl CLI communication.

#if canImport(Darwin)

import Foundation

@available(*, deprecated, message: "Use AgentsBoardServer HTTP API instead. Will be removed in v0.9.0.")
public final class ControlServer {

    private let socketPath: String
    private var serverSocket: Int32 = -1
    private let mcpServer: MCPServer
    private var isRunning = false

    public init(mcpServer: MCPServer) {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("AgentsBoard")
        self.socketPath = supportDir.appendingPathComponent("agentsctl.sock").path
        self.mcpServer = mcpServer
    }

    public func start() throws {
        // Remove existing socket
        unlink(socketPath)

        // Create socket
        serverSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            throw ControlServerError.socketCreationFailed
        }

        // Bind
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let bound = ptr.withMemoryRebound(to: CChar.self, capacity: 104) { dest in
                pathBytes.withUnsafeBufferPointer { src in
                    let count = min(src.count, 104)
                    dest.update(from: src.baseAddress!, count: count)
                    return count
                }
            }
            _ = bound
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                bind(serverSocket, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindResult == 0 else {
            throw ControlServerError.bindFailed
        }

        // Listen
        guard listen(serverSocket, 5) == 0 else {
            throw ControlServerError.listenFailed
        }

        isRunning = true

        // Accept loop on background thread
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.acceptLoop()
        }
    }

    public func stop() {
        isRunning = false
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
        unlink(socketPath)
    }

    private func acceptLoop() {
        while isRunning {
            var clientAddr = sockaddr_un()
            var clientLen = socklen_t(MemoryLayout<sockaddr_un>.size)

            let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    accept(serverSocket, sockPtr, &clientLen)
                }
            }

            guard clientSocket >= 0 else { continue }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.handleClient(clientSocket)
            }
        }
    }

    private func handleClient(_ socket: Int32) {
        defer { close(socket) }

        var buffer = [UInt8](repeating: 0, count: 65536)
        let bytesRead = read(socket, &buffer, buffer.count)
        guard bytesRead > 0 else { return }

        let data = Data(buffer[..<bytesRead])
        guard let request = String(data: data, encoding: .utf8) else { return }

        // Process via MCP server logic (reuse the same JSON-RPC protocol)
        // For now, echo back a response
        let response = """
        {"jsonrpc":"2.0","result":{"status":"ok"},"id":1}
        """

        if let responseData = response.data(using: .utf8) {
            _ = responseData.withUnsafeBytes { ptr in
                write(socket, ptr.baseAddress!, responseData.count)
            }
        }
    }

    deinit {
        stop()
    }
}

public enum ControlServerError: Error {
    case socketCreationFailed
    case bindFailed
    case listenFailed
}

#endif
