// MARK: - Hooks Protocols

import Foundation

/// Receives structured hook events from Claude Code.
public protocol HookEventReceiving: AnyObject {
    func didReceiveHookEvent(_ event: HookEvent, forSession sessionId: String)
}

/// Parses raw JSON data into typed HookEvent.
public protocol HookEventParsing {
    func parse(json: Data) throws -> HookEvent
}
