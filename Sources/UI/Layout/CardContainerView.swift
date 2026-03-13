// MARK: - Card Container View (Step 5.1)
// Positions session cards according to the active layout.

import SwiftUI
import AgentsBoardCore

struct CardContainerView<CardContent: View>: View {
    let cardCount: Int
    let layoutMode: LayoutMode
    let cardContent: (Int) -> CardContent

    @State private var engine = LayoutEngine()

    var body: some View {
        GeometryReader { geometry in
            let frames = engine.computeFrames(
                cardCount: cardCount,
                in: geometry.size,
                mode: layoutMode
            )

            ZStack(alignment: .topLeading) {
                ForEach(frames) { frame in
                    cardContent(frame.id)
                        .frame(width: frame.rect.width, height: frame.rect.height)
                        .offset(x: frame.rect.origin.x, y: frame.rect.origin.y)
                        .animation(.easeInOut(duration: 0.25), value: layoutMode)
                }
            }
        }
    }
}
