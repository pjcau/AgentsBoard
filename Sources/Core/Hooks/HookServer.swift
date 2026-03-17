// MARK: - Hook Server (Step 3.3)
// Unix socket server receiving structured JSON events from Claude Code hooks.

import Foundation

#if canImport(Darwin)

final class HookServer {

    // MARK: - Properties

    private let socketPath: String
    private var serverFD: Int32 = -1
    private var isRunning = false
    private let queue = DispatchQueue(label: "com.agentsboard.hooks", qos: .userInitiated)
    private let parser: any HookEventParsing

    weak var delegate: HookEventReceiving?

    // MARK: - Init

    init(
        parser: any HookEventParsing,
        socketPath: String? = nil
    ) {
        self.parser = parser
        self.socketPath = socketPath ??
            "\(NSHomeDirectory())/Library/Application Support/AgentsBoard/hooks.sock"
    }

    deinit {
        stop()
    }

    // MARK: - Lifecycle

    func start() throws {
        // Remove existing socket
        unlink(socketPath)

        // Create socket
        serverFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFD >= 0 else {
            throw HookServerError.socketCreationFailed(errno)
        }

        // Bind
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let bound = ptr.withMemoryRebound(to: CChar.self, capacity: Int(104)) { dest in
                pathBytes.withUnsafeBufferPointer { src in
                    memcpy(dest, src.baseAddress!, min(src.count, 104))
                }
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                bind(serverFD, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindResult == 0 else {
            close(serverFD)
            throw HookServerError.bindFailed(errno)
        }

        // Listen
        guard listen(serverFD, 5) == 0 else {
            close(serverFD)
            throw HookServerError.listenFailed(errno)
        }

        isRunning = true

        queue.async { [weak self] in
            self?.acceptLoop()
        }
    }

    func stop() {
        isRunning = false
        if serverFD >= 0 {
            close(serverFD)
            serverFD = -1
        }
        unlink(socketPath)
    }

    // MARK: - Private

    private func acceptLoop() {
        while isRunning {
            let clientFD = accept(serverFD, nil, nil)
            guard clientFD >= 0 else {
                if errno == EINTR { continue }
                break
            }

            queue.async { [weak self] in
                self?.handleClient(fd: clientFD)
            }
        }
    }

    private func handleClient(fd: Int32) {
        defer { close(fd) }

        var buffer = [UInt8](repeating: 0, count: 65536)
        var accumulated = Data()

        while isRunning {
            let bytesRead = read(fd, &buffer, buffer.count)
            guard bytesRead > 0 else { break }

            accumulated.append(contentsOf: buffer[0..<bytesRead])

            // Try to parse complete JSON messages (newline-delimited)
            while let newlineIndex = accumulated.firstIndex(of: UInt8(ascii: "\n")) {
                let messageData = accumulated[accumulated.startIndex..<newlineIndex]
                accumulated = Data(accumulated[accumulated.index(after: newlineIndex)...])

                if let event = try? parser.parse(json: Data(messageData)) {
                    let sessionId = extractSessionId(from: Data(messageData))
                    DispatchQueue.main.async { [weak self] in
                        self?.delegate?.didReceiveHookEvent(event, forSession: sessionId)
                    }
                }
            }
        }
    }

    private func extractSessionId(from json: Data) -> String {
        if let dict = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
           let sessionId = dict["session_id"] as? String {
            return sessionId
        }
        return "unknown"
    }
}

// MARK: - Hook Event Parser Implementation

final class HookEventParserImpl: HookEventParsing {

    func parse(json: Data) throws -> HookEvent {
        guard let dict = try JSONSerialization.jsonObject(with: json) as? [String: Any],
              let eventType = dict["type"] as? String else {
            throw HookParseError.invalidFormat
        }

        switch eventType {
        case "tool_use":
            let name = dict["name"] as? String ?? ""
            let input = dict["input"] as? String ?? ""
            let output = dict["output"] as? String
            return .toolUse(name: name, input: input, output: output)

        case "file_read":
            let path = dict["path"] as? String ?? ""
            return .fileRead(path: path)

        case "file_write":
            let path = dict["path"] as? String ?? ""
            let diff = dict["diff"] as? String
            return .fileWrite(path: path, diff: diff)

        case "command_exec":
            let command = dict["command"] as? String ?? ""
            let exitCode = dict["exit_code"] as? Int ?? -1
            return .commandExec(command: command, exitCode: exitCode)

        case "sub_agent_spawn":
            let id = dict["id"] as? String ?? ""
            return .subAgentSpawn(id: id)

        case "cost_delta":
            let inputTokens = dict["input_tokens"] as? Int ?? 0
            let outputTokens = dict["output_tokens"] as? Int ?? 0
            let cost = Decimal(dict["cost"] as? Double ?? 0)
            return .costDelta(inputTokens: inputTokens, outputTokens: outputTokens, cost: cost)

        case "approval":
            let tool = dict["tool"] as? String ?? ""
            let statusStr = dict["status"] as? String ?? "pending"
            let status = HookEvent.ApprovalStatus(rawValue: statusStr) ?? .pending
            return .approval(tool: tool, status: status)

        default:
            throw HookParseError.unknownEventType(eventType)
        }
    }
}

// MARK: - Errors

enum HookServerError: Error {
    case socketCreationFailed(Int32)
    case bindFailed(Int32)
    case listenFailed(Int32)
}

#endif

enum HookParseError: Error {
    case invalidFormat
    case unknownEventType(String)
}
