// MARK: - Layout Engine (Step 5.1)
// Calculates positions and sizes for N session cards given layout mode.

import Foundation
import SwiftUI
import AgentsBoardCore

/// Protocol for layout strategies (OCP: add layouts without modifying engine).
protocol LayoutProviding {
    func layout(cardCount: Int, in size: CGSize) -> [CardFrame]
}

/// Computed frame for a single card.
struct CardFrame: Identifiable {
    let id: Int
    let rect: CGRect
    let isFocused: Bool

    init(id: Int, rect: CGRect, isFocused: Bool = false) {
        self.id = id
        self.rect = rect
        self.isFocused = isFocused
    }
}

/// Calculates card frames based on the active layout mode.
final class LayoutEngine {

    private var layouts: [LayoutMode: any LayoutProviding] = [:]

    init() {
        layouts[.single] = SingleLayout()
        layouts[.list] = ListLayout()
        layouts[.twoColumn] = TwoColumnLayout()
        layouts[.threeColumn] = ThreeColumnLayout()
        layouts[.fleet] = FleetGridLayout()
    }

    /// Register a custom layout (OCP).
    func register(_ layout: any LayoutProviding, for mode: LayoutMode) {
        layouts[mode] = layout
    }

    func computeFrames(cardCount: Int, in size: CGSize, mode: LayoutMode) -> [CardFrame] {
        guard let layout = layouts[mode] else { return [] }
        return layout.layout(cardCount: cardCount, in: size)
    }
}
