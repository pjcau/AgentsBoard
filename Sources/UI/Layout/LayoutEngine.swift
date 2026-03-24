// MARK: - Layout Engine (Step 5.1)
// Calculates positions and sizes for N session cards given layout mode.

import Foundation
import SwiftUI
import AgentsBoardCore

/// Protocol for layout strategies (OCP: add layouts without modifying engine).
public protocol LayoutProviding {
    func layout(cardCount: Int, in size: CGSize) -> [CardFrame]
}

/// Computed frame for a single card.
public struct CardFrame: Identifiable {
    public let id: Int
    public let rect: CGRect
    public let isFocused: Bool

    public init(id: Int, rect: CGRect, isFocused: Bool = false) {
        self.id = id
        self.rect = rect
        self.isFocused = isFocused
    }
}

/// Calculates card frames based on the active layout mode.
public final class LayoutEngine {

    private var layouts: [LayoutMode: any LayoutProviding] = [:]

    public init() {
        layouts[.single] = SingleLayout()
        layouts[.list] = ListLayout()
        layouts[.twoColumn] = TwoColumnLayout()
        layouts[.threeColumn] = ThreeColumnLayout()
        layouts[.fleet] = FleetGridLayout()
    }

    /// Register a custom layout (OCP).
    public func register(_ layout: any LayoutProviding, for mode: LayoutMode) {
        layouts[mode] = layout
    }

    /// Update the fleet grid minimum card width for user-resizable sessions.
    public func updateFleetCardWidth(_ width: CGFloat) {
        layouts[.fleet] = FleetGridLayout(minCardWidth: width)
    }

    public func computeFrames(cardCount: Int, in size: CGSize, mode: LayoutMode) -> [CardFrame] {
        guard let layout = layouts[mode] else { return [] }
        return layout.layout(cardCount: cardCount, in: size)
    }
}
