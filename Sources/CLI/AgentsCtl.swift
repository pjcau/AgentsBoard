// MARK: - AgentsCtl CLI (v0.8.0)
// Command-line tool to control a running AgentsBoard instance via HTTP API.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@main
struct AgentsCtl {
    static func main() {
        let args = CommandLine.arguments.dropFirst()
        guard let command = args.first else {
            printUsage()
            return
        }

        // Parse --host and --port flags
        let flags = parseFlags(Array(args))
        let host = flags["host"] ?? "localhost"
        let port = flags["port"] ?? "19850"
        let baseURL = "http://\(host):\(port)"
        let client = HTTPClient(baseURL: baseURL)

        switch command {
        case "list":
            let stateFilter = flags["state"]
            let providerFilter = flags["provider"]
            var url = "/api/v1/sessions"
            var queryParts: [String] = []
            if let s = stateFilter { queryParts.append("state=\(s)") }
            if let p = providerFilter { queryParts.append("provider=\(p)") }
            if !queryParts.isEmpty { url += "?" + queryParts.joined(separator: "&") }
            client.get(url)

        case "status", "stats":
            client.get("/api/v1/fleet/stats")

        case "states":
            client.get("/api/v1/sessions")

        case "send":
            let remaining = Array(args.dropFirst()).filter { !$0.hasPrefix("--") }
            // Remove command name and flags
            let positional = remaining.dropFirst() // drop "send"
            guard positional.count >= 2 else {
                print("Usage: agentsctl send <session-id> \"text\"")
                return
            }
            let sessionId = Array(positional)[0]
            let text = Array(positional)[1]
            client.post("/api/v1/sessions/\(sessionId)/input", body: ["text": text])

        case "log":
            var url = "/api/v1/activity"
            var queryParts: [String] = []
            if let limit = flags["limit"] { queryParts.append("limit=\(limit)") }
            if let session = flags["session"] { queryParts.append("session=\(session)") }
            if !queryParts.isEmpty { url += "?" + queryParts.joined(separator: "&") }
            client.get(url)

        case "cost":
            if let session = flags["session"] {
                client.get("/api/v1/costs/session/\(session)")
            } else {
                client.get("/api/v1/costs")
            }

        case "config":
            client.get("/api/v1/config")

        case "themes":
            client.get("/api/v1/themes")

        default:
            print("Unknown command: \(command)")
            printUsage()
        }
    }

    static func printUsage() {
        print("""
        agentsctl — Control AgentsBoard from the command line

        USAGE:
          agentsctl <command> [--host <host>] [--port <port>]

        COMMANDS:
          list      List all sessions [--state <state>] [--provider <provider>]
          status    Show fleet overview statistics
          states    Show current state of all agents
          send      Send text input: send <session-id> "text"
          log       Show activity log [--limit <n>] [--session <id>]
          cost      Show cost information [--session <id>]
          config    Show current configuration
          themes    List available themes

        OPTIONS:
          --host    Server hostname (default: localhost)
          --port    Server port (default: 19850)
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

// MARK: - HTTP Client

final class HTTPClient {
    private let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func get(_ path: String) {
        request(method: "GET", path: path)
    }

    func post(_ path: String, body: [String: Any]) {
        request(method: "POST", path: path, body: body)
    }

    private func request(method: String, path: String, body: [String: Any]? = nil) {
        guard let url = URL(string: baseURL + path) else {
            print("Error: Invalid URL")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 10

        if let body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: req) { data, response, error in
            defer { semaphore.signal() }

            if let error {
                print("Error: \(error.localizedDescription)")
                print("Is AgentsBoard running with the HTTP server enabled?")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: No response")
                return
            }

            guard let data else {
                print("Error: No data (HTTP \(httpResponse.statusCode))")
                return
            }

            if httpResponse.statusCode >= 400 {
                print("Error (HTTP \(httpResponse.statusCode)):")
            }

            Self.prettyPrint(data)
        }

        task.resume()
        semaphore.wait()
    }

    private static func prettyPrint(_ data: Data) {
        if let obj = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
           let str = String(data: pretty, encoding: .utf8) {
            print(str)
        } else if let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }
}
