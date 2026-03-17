// MARK: - Keybinding Tests

import Testing
import Foundation
#if canImport(AppKit)
import AppKit
#endif
@testable import AgentsBoardCore

// MARK: - KeyModifiers Tests

@Suite("KeyModifiers")
struct KeyModifiersTests {
    @Test func singleModifier() {
        let cmd = KeyModifiers.command
        #expect(cmd.contains(.command))
        #expect(!cmd.contains(.shift))
    }

    @Test func combinedModifiers() {
        let combo: KeyModifiers = [.command, .shift]
        #expect(combo.contains(.command))
        #expect(combo.contains(.shift))
        #expect(!combo.contains(.option))
    }

    @Test func allModifiers() {
        let all: KeyModifiers = [.command, .shift, .option, .control]
        #expect(all.contains(.command))
        #expect(all.contains(.shift))
        #expect(all.contains(.option))
        #expect(all.contains(.control))
    }

    #if canImport(AppKit)
    @Test func nsEventFlagsConversion() {
        let cmd = KeyModifiers.command
        let flags = cmd.nsEventFlags
        #expect(flags.contains(.command))
    }

    @Test func fromNSEventFlags() {
        let flags: NSEvent.ModifierFlags = [.command, .shift]
        let modifiers = KeyModifiers.from(flags)
        #expect(modifiers.contains(.command))
        #expect(modifiers.contains(.shift))
    }
    #endif
}

// MARK: - KeyCombination Tests

@Suite("KeyCombination")
struct KeyCombinationTests {
    @Test func creation() {
        let combo = KeyCombination(keyCode: 0x25, modifiers: [.command]) // L key
        #expect(combo.keyCode == 0x25)
        #expect(combo.modifiers.contains(.command))
    }

    @Test func hashable() {
        let c1 = KeyCombination(keyCode: 0x25, modifiers: [.command])
        let c2 = KeyCombination(keyCode: 0x25, modifiers: [.command])
        #expect(c1 == c2)
    }

    @Test func differentCombosNotEqual() {
        let c1 = KeyCombination(keyCode: 0x25, modifiers: [.command])
        let c2 = KeyCombination(keyCode: 0x25, modifiers: [.command, .shift])
        #expect(c1 != c2)
    }

    @Test func displayString() {
        let combo = KeyCombination(keyCode: 0x25, modifiers: [.command])
        let display = combo.displayString
        #expect(!display.isEmpty)
    }
}

// MARK: - KeyBinding Tests

@Suite("KeyBinding")
struct KeyBindingTests {
    @Test func creation() {
        let binding = KeyBinding(
            id: "test",
            combination: KeyCombination(keyCode: 0x24, modifiers: [.command]),
            label: "Test Action",
            category: "general",
            action: {}
        )
        #expect(binding.id == "test")
        #expect(binding.label == "Test Action")
        #expect(binding.category == "general")
    }
}

// MARK: - KeybindingManager Tests

@Suite("KeybindingManager")
struct KeybindingManagerTests {
    @Test func initiallyEmpty() {
        let manager = KeybindingManager()
        #expect(manager.allBindings.isEmpty)
    }

    @Test func registerBinding() {
        let manager = KeybindingManager()
        let binding = KeyBinding(
            id: "test",
            combination: KeyCombination(keyCode: 0x24, modifiers: [.command]),
            label: "Test",
            category: "general",
            action: {}
        )
        manager.register(binding)
        #expect(manager.allBindings.count == 1)
    }

    @Test func registerMultipleBindings() {
        let manager = KeybindingManager()
        for i in 0..<5 {
            let binding = KeyBinding(
                id: "test_\(i)",
                combination: KeyCombination(keyCode: UInt16(i), modifiers: [.command]),
                label: "Test \(i)",
                category: "general",
                action: {}
            )
            manager.register(binding)
        }
        #expect(manager.allBindings.count == 5)
    }
}
