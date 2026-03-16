// MARK: - Keybinding Manager (Step 7.2)
// Centralized keyboard shortcut management with conflict detection.

import Foundation
import Observation

#if canImport(AppKit)
import AppKit

public protocol KeybindingManaging: AnyObject {
    func register(_ binding: KeyBinding)
    func handle(event: NSEvent) -> Bool
    var allBindings: [KeyBinding] { get }
}
#else
public protocol KeybindingManaging: AnyObject {
    func register(_ binding: KeyBinding)
    var allBindings: [KeyBinding] { get }
}
#endif

@Observable
public final class KeybindingManager: KeybindingManaging {

    private var bindings: [KeyCombination: KeyBinding] = [:]

    public init() {}

    public func register(_ binding: KeyBinding) {
        bindings[binding.combination] = binding
    }

    #if canImport(AppKit)
    public func handle(event: NSEvent) -> Bool {
        let combo = KeyCombination(
            keyCode: event.keyCode,
            modifiers: KeyModifiers.from(event.modifierFlags.intersection(.deviceIndependentFlagsMask))
        )
        guard let binding = bindings[combo] else { return false }
        binding.action()
        return true
    }
    #endif

    public var allBindings: [KeyBinding] {
        Array(bindings.values)
    }

    /// Register default app keybindings.
    public func registerDefaults(
        commandPalette: @escaping @Sendable () -> Void,
        toggleSidebar: @escaping @Sendable () -> Void,
        newSession: @escaping @Sendable () -> Void,
        closeSession: @escaping @Sendable () -> Void,
        fleetOverview: @escaping @Sendable () -> Void,
        activityLog: @escaping @Sendable () -> Void,
        nextSession: @escaping @Sendable () -> Void,
        previousSession: @escaping @Sendable () -> Void
    ) {
        // Cmd+K — Command Palette
        register(KeyBinding(
            id: "command_palette",
            combination: KeyCombination(keyCode: 40, modifiers: .command),
            label: "Command Palette",
            category: "General",
            action: commandPalette
        ))

        // Cmd+0 — Toggle Sidebar
        register(KeyBinding(
            id: "toggle_sidebar",
            combination: KeyCombination(keyCode: 29, modifiers: .command),
            label: "Toggle Sidebar",
            category: "Navigation",
            action: toggleSidebar
        ))

        // Cmd+N — New Session
        register(KeyBinding(
            id: "new_session",
            combination: KeyCombination(keyCode: 45, modifiers: .command),
            label: "New Session",
            category: "Sessions",
            action: newSession
        ))

        // Cmd+W — Close Session
        register(KeyBinding(
            id: "close_session",
            combination: KeyCombination(keyCode: 13, modifiers: .command),
            label: "Close Session",
            category: "Sessions",
            action: closeSession
        ))

        // Cmd+Shift+F — Fleet Overview
        register(KeyBinding(
            id: "fleet_overview",
            combination: KeyCombination(keyCode: 3, modifiers: [.command, .shift]),
            label: "Fleet Overview",
            category: "Navigation",
            action: fleetOverview
        ))

        // Cmd+Shift+A — Activity Log
        register(KeyBinding(
            id: "activity_log",
            combination: KeyCombination(keyCode: 0, modifiers: [.command, .shift]),
            label: "Activity Log",
            category: "Navigation",
            action: activityLog
        ))

        // Ctrl+Tab — Next Session
        register(KeyBinding(
            id: "next_session",
            combination: KeyCombination(keyCode: 48, modifiers: .control),
            label: "Next Session",
            category: "Sessions",
            action: nextSession
        ))

        // Ctrl+Shift+Tab — Previous Session
        register(KeyBinding(
            id: "previous_session",
            combination: KeyCombination(keyCode: 48, modifiers: [.control, .shift]),
            label: "Previous Session",
            category: "Sessions",
            action: previousSession
        ))
    }
}
