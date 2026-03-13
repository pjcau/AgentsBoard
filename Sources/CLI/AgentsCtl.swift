// MARK: - AgentsCtl CLI (Step 13.2)
// Command-line tool to control a running AgentsBoard instance.

import Foundation

@main
struct AgentsCtl {
    static func main() {
        let args = CommandLine.arguments.dropFirst()
        guard let command = args.first else {
            printUsage()
            return
        }

        let socketPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("AgentsBoard/agentsctl.sock").path

        let client = ControlClient(socketPath: socketPath)

        switch command {
        case "list":
            let params = parseFlags(Array(args.dropFirst()))
            client.send(method: "tools/call", params: [
                "name": "list_sessions",
                "arguments": params
            ])
        case "status":
            client.send(method: "tools/call", params: [
                "name": "get_fleet_stats"
            ])
        case "states":
            client.send(method: "tools/call", params: [
                "name": "get_agent_states"
            ])
        case "send":
            let remaining = Array(args.dropFirst())
            guard remaining.count >= 2 else {
                print("Usage: agentsctl send <session-id> \"text\"")
                return
            }
            client.send(method: "tools/call", params: [
                "name": "send_input",
                "arguments": ["sessionId": remaining[0], "text": remaining[1]]
            ])
        case "log":
            let params = parseFlags(Array(args.dropFirst()))
            client.send(method: "tools/call", params: [
                "name": "get_activity_log",
                "arguments": params
            ])
        case "cost":
            client.send(method: "tools/call", params: [
                "name": "get_fleet_stats"
            ])
        default:
            print("Unknown command: \(command)")
            printUsage()
        }
    }

    static func printUsage() {
        print("""
        agentsctl — Control AgentsBoard from the command line

        USAGE:
          agentsctl list [--state <state>] [--provider <provider>]
          agentsctl status
          agentsctl states
          agentsctl send <session-id> "text"
          agentsctl log [--limit <n>] [--session <id>]
          agentsctl cost

        COMMANDS:
          list      List all sessions with status
          status    Show fleet overview statistics
          states    Show current state of all agents
          send      Send text input to a session
          log       Show activity log
          cost      Show cost information
        """)
    }

    static func parseFlags(_ args: [String]) -> [String: String] {
        var result: [String: String] = [:]
        var i = 0
        while i < args.count {
            if args[i].hasPrefix("--"), i + 1 < args.count {
                let key = String(args[i].dropFirst(2))
                result[key] = args[i + 1]
                i += 2
            } else {
                i += 1
            }
        }
        return result
    }
}

// MARK: - Control Client

final class ControlClient {
    private let socketPath: String

    init(socketPath: String) {
        self.socketPath = socketPath
    }

    func send(method: String, params: [String: Any]) {
        let clientSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        guard clientSocket >= 0 else {
            print("Error: Cannot create socket")
            return
        }
        defer { close(clientSocket) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: 104) { dest in
                pathBytes.withUnsafeBufferPointer { src in
                    let count = min(src.count, 104)
                    dest.update(from: src.baseAddress!, count: count)
                }
            }
        }

        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                connect(clientSocket, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard connectResult == 0 else {
            print("Error: Cannot connect to AgentsBoard. Is it running?")
            return
        }

        let request: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: request),
              let json = String(data: data, encoding: .utf8) else {
            print("Error: Cannot serialize request")
            return
        }

        _ = json.withCString { ptr in
            write(clientSocket, ptr, json.count)
        }

        var buffer = [UInt8](repeating: 0, count: 65536)
        let bytesRead = read(clientSocket, &buffer, buffer.count)
        if bytesRead > 0 {
            let responseData = Data(buffer[..<bytesRead])
            if let response = String(data: responseData, encoding: .utf8) {
                prettyPrint(response)
            }
        }
    }

    private func prettyPrint(_ json: String) {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
              let str = String(data: pretty, encoding: .utf8) else {
            print(json)
            return
        }
        print(str)
    }
}
