// MARK: - Key Binding Models (Step 7.2)

import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Modifier flags for key bindings.
public struct KeyModifiers: OptionSet, Hashable, Codable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let command  = KeyModifiers(rawValue: 1 << 0)
    public static let shift    = KeyModifiers(rawValue: 1 << 1)
    public static let option   = KeyModifiers(rawValue: 1 << 2)
    public static let control  = KeyModifiers(rawValue: 1 << 3)

    #if canImport(AppKit)
    public var nsEventFlags: NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        if contains(.command)  { flags.insert(.command) }
        if contains(.shift)    { flags.insert(.shift) }
        if contains(.option)   { flags.insert(.option) }
        if contains(.control)  { flags.insert(.control) }
        return flags
    }

    public static func from(_ flags: NSEvent.ModifierFlags) -> KeyModifiers {
        var m = KeyModifiers()
        if flags.contains(.command)  { m.insert(.command) }
        if flags.contains(.shift)    { m.insert(.shift) }
        if flags.contains(.option)   { m.insert(.option) }
        if flags.contains(.control)  { m.insert(.control) }
        return m
    }
    #endif
}

/// A key combination (e.g., Cmd+K).
public struct KeyCombination: Hashable, Codable, Sendable {
    public let keyCode: UInt16
    public let modifiers: KeyModifiers

    public init(keyCode: UInt16, modifiers: KeyModifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Human-readable display string.
    public var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control)  { parts.append("⌃") }
        if modifiers.contains(.option)   { parts.append("⌥") }
        if modifiers.contains(.shift)    { parts.append("⇧") }
        if modifiers.contains(.command)  { parts.append("⌘") }
        parts.append(keyName)
        return parts.joined()
    }

    private var keyName: String {
        switch keyCode {
        case 0: return "A"; case 1: return "S"; case 2: return "D"
        case 3: return "F"; case 4: return "H"; case 5: return "G"
        case 6: return "Z"; case 7: return "X"; case 8: return "C"
        case 9: return "V"; case 11: return "B"; case 12: return "Q"
        case 13: return "W"; case 14: return "E"; case 15: return "R"
        case 16: return "Y"; case 17: return "T"; case 31: return "O"
        case 32: return "U"; case 34: return "I"; case 35: return "P"
        case 37: return "L"; case 38: return "J"; case 40: return "K"
        case 36: return "↩"; case 48: return "⇥"; case 49: return "Space"
        case 51: return "⌫"; case 53: return "⎋"
        case 123: return "←"; case 124: return "→"
        case 125: return "↓"; case 126: return "↑"
        default: return "?"
        }
    }
}

/// A registered key binding with its action.
public struct KeyBinding: Identifiable, Sendable {
    public let id: String
    public let combination: KeyCombination
    public let label: String
    public let category: String
    public let action: @Sendable () -> Void

    public init(id: String, combination: KeyCombination, label: String, category: String, action: @escaping @Sendable () -> Void) {
        self.id = id
        self.combination = combination
        self.label = label
        self.category = category
        self.action = action
    }
}
