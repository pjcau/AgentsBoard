// MARK: - Layout Implementations (Step 5.1)

import Foundation
import AgentsBoardCore

// MARK: - Single Layout
/// One session takes the entire content area.
struct SingleLayout: LayoutProviding {
    func layout(cardCount: Int, in size: CGSize) -> [CardFrame] {
        guard cardCount > 0 else { return [] }
        return [CardFrame(id: 0, rect: CGRect(origin: .zero, size: size), isFocused: true)]
    }
}

// MARK: - List Layout
/// Vertical stack of cards, each taking full width.
struct ListLayout: LayoutProviding {
    let minCardHeight: CGFloat = 200
    let spacing: CGFloat = 8

    func layout(cardCount: Int, in size: CGSize) -> [CardFrame] {
        guard cardCount > 0 else { return [] }
        let totalSpacing = spacing * CGFloat(cardCount - 1)
        let cardHeight = max(minCardHeight, (size.height - totalSpacing) / CGFloat(cardCount))

        return (0..<cardCount).map { i in
            let y = CGFloat(i) * (cardHeight + spacing)
            return CardFrame(
                id: i,
                rect: CGRect(x: 0, y: y, width: size.width, height: cardHeight)
            )
        }
    }
}

// MARK: - Two Column Layout
/// Grid with 2 columns.
struct TwoColumnLayout: LayoutProviding {
    let spacing: CGFloat = 8

    func layout(cardCount: Int, in size: CGSize) -> [CardFrame] {
        gridLayout(cardCount: cardCount, columns: 2, in: size, spacing: spacing)
    }
}

// MARK: - Three Column Layout
/// Grid with 3 columns.
struct ThreeColumnLayout: LayoutProviding {
    let spacing: CGFloat = 8

    func layout(cardCount: Int, in size: CGSize) -> [CardFrame] {
        gridLayout(cardCount: cardCount, columns: 3, in: size, spacing: spacing)
    }
}

// MARK: - Fleet Grid Layout
/// Auto-fitting grid that adapts column count to available space.
struct FleetGridLayout: LayoutProviding {
    let minCardWidth: CGFloat
    let minCardHeight: CGFloat = 200
    let spacing: CGFloat = 8

    init(minCardWidth: CGFloat = 420) {
        self.minCardWidth = minCardWidth
    }

    func layout(cardCount: Int, in size: CGSize) -> [CardFrame] {
        guard cardCount > 0 else { return [] }
        let columns = max(1, Int(size.width / (minCardWidth + spacing)))
        return gridLayout(cardCount: cardCount, columns: columns, in: size, spacing: spacing)
    }
}

// MARK: - Shared Grid Helper

private func gridLayout(cardCount: Int, columns: Int, in size: CGSize, spacing: CGFloat) -> [CardFrame] {
    guard cardCount > 0, columns > 0 else { return [] }
    // If computed card width would be too narrow for a terminal, reduce column count
    let effectiveColumns: Int = {
        var cols = columns
        while cols > 1 {
            let w = (size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
            if w >= 350 { return cols }
            cols -= 1
        }
        return 1
    }()
    let rows = Int(ceil(Double(cardCount) / Double(effectiveColumns)))
    let cardWidth = (size.width - spacing * CGFloat(effectiveColumns - 1)) / CGFloat(effectiveColumns)
    let cardHeight = (size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)

    return (0..<cardCount).map { i in
        let col = i % effectiveColumns
        let row = i / effectiveColumns
        let x = CGFloat(col) * (cardWidth + spacing)
        let y = CGFloat(row) * (cardHeight + spacing)
        return CardFrame(id: i, rect: CGRect(x: x, y: y, width: cardWidth, height: cardHeight))
    }
}
