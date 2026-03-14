// MARK: - CollectionGridView
// NSCollectionView wrapper for SwiftUI — proper cell reuse for heavy terminal views.
// Replaces LazyVGrid which doesn't recycle NSViewRepresentable subviews properly.

import SwiftUI
import AppKit
import AgentsBoardCore

/// NSViewRepresentable wrapping NSCollectionView with real cell reuse.
struct CollectionGridView: NSViewRepresentable {
    let sessions: [any AgentSessionRepresentable]
    let selectedSessionId: String?
    let onSelect: (String) -> Void
    let viewModelProvider: (any AgentSessionRepresentable) -> SessionCardViewModel
    let columnCount: Int

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let layout = NSCollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let collectionView = NSCollectionView()
        collectionView.collectionViewLayout = layout
        collectionView.isSelectable = true
        collectionView.backgroundColors = [.clear]
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator

        collectionView.register(
            SessionCollectionItem.self,
            forItemWithIdentifier: SessionCollectionItem.identifier
        )

        scrollView.documentView = collectionView
        context.coordinator.collectionView = collectionView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.sessions = sessions
        coordinator.selectedSessionId = selectedSessionId
        coordinator.onSelect = onSelect
        coordinator.viewModelProvider = viewModelProvider
        coordinator.columnCount = columnCount

        if let collectionView = coordinator.collectionView {
            // Update layout item size
            if let layout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout {
                let width = scrollView.frame.width
                let cols = CGFloat(max(1, columnCount))
                let spacing = layout.minimumInteritemSpacing * (cols - 1) + layout.sectionInset.left + layout.sectionInset.right
                let itemWidth = max(300, (width - spacing) / cols)
                layout.itemSize = NSSize(width: itemWidth, height: 340)
            }
            collectionView.reloadData()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegate {
        var sessions: [any AgentSessionRepresentable] = []
        var selectedSessionId: String?
        var onSelect: ((String) -> Void)?
        var viewModelProvider: ((any AgentSessionRepresentable) -> SessionCardViewModel)?
        var columnCount: Int = 2
        weak var collectionView: NSCollectionView?

        func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }

        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            sessions.count
        }

        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let item = collectionView.makeItem(
                withIdentifier: SessionCollectionItem.identifier,
                for: indexPath
            ) as! SessionCollectionItem

            let session = sessions[indexPath.item]
            let isSelected = selectedSessionId == session.sessionId

            if let provider = viewModelProvider {
                let vm = provider(session)
                item.configure(with: vm, isSelected: isSelected)
            }

            return item
        }

        func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
            guard let indexPath = indexPaths.first, indexPath.item < sessions.count else { return }
            onSelect?(sessions[indexPath.item].sessionId)
        }
    }
}

// MARK: - Collection View Item (reusable cell)

final class SessionCollectionItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("SessionCollectionItem")

    private var hostingView: NSHostingView<AnyView>?

    override func loadView() {
        self.view = NSView(frame: .zero)
    }

    func configure(with viewModel: SessionCardViewModel, isSelected: Bool) {
        let cardView = AnyView(
            SessionCardView(viewModel: viewModel, isFocused: isSelected)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.green, lineWidth: isSelected ? 3 : 0)
                )
                .shadow(color: isSelected ? .green.opacity(0.3) : .clear, radius: 6)
        )

        if let existing = hostingView {
            existing.rootView = cardView
        } else {
            let hosting = NSHostingView(rootView: cardView)
            hosting.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hosting)
            NSLayoutConstraint.activate([
                hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hosting.topAnchor.constraint(equalTo: view.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            hostingView = hosting
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // NSHostingView is reused — rootView will be updated in configure()
    }
}
