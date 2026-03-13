// MARK: - Key Event Handler (Step 7.2)
// NSEvent monitor that routes key events to the keybinding manager.

import AppKit
import AgentsBoardCore

final class KeyEventHandler {

    private let keybindingManager: KeybindingManaging
    private var monitor: Any?

    init(keybindingManager: KeybindingManaging) {
        self.keybindingManager = keybindingManager
    }

    func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if self.keybindingManager.handle(event: event) {
                return nil // Consumed
            }
            return event // Pass through
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stop()
    }
}
