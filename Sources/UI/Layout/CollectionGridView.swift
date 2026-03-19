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
        let oldSessionIds = coordinator.sessions.map(\.sessionId)
        let oldSelected = coordinator.selectedSessionId

        coordinator.sessions = sessions
        coordinator.selectedSessionId = selectedSessionId
        coordinator.onSelect = onSelect
        coordinator.viewModelProvider = viewModelProvider
        coordinator.columnCount = columnCount

        guard let collectionView = coordinator.collectionView else { return }

        // Update layout item size
        if let layout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout {
            let width = scrollView.frame.width
            let cols = CGFloat(max(1, columnCount))
            let spacing = layout.minimumInteritemSpacing * (cols - 1) + layout.sectionInset.left + layout.sectionInset.right
            let itemWidth = max(300, (width - spacing) / cols)
            layout.itemSize = NSSize(width: itemWidth, height: 340)
        }

        let newSessionIds = sessions.map(\.sessionId)

        // Full reload only when session list changes (add/remove/reorder)
        if oldSessionIds != newSessionIds {
            collectionView.reloadData()
            return
        }

        // Selection-only change: update just the affected cells without recreating terminals
        if oldSelected != selectedSessionId {
            var indexPathsToUpdate = Set<IndexPath>()
            for (index, session) in sessions.enumerated() {
                if session.sessionId == oldSelected || session.sessionId == selectedSessionId {
                    indexPathsToUpdate.insert(IndexPath(item: index, section: 0))
                }
            }
            // Update selection state on existing items without full reload
            for indexPath in indexPathsToUpdate {
                if let item = collectionView.item(at: indexPath) as? SessionCollectionItem {
                    let session = sessions[indexPath.item]
                    let isSelected = selectedSessionId == session.sessionId
                    item.updateSelection(isSelected: isSelected)
                }
            }
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
    private var currentSessionId: String?
    private var selectionModel = SelectionState()

    /// Observable selection state — lets us update the selection border
    /// without recreating the SessionCardView (which would kill the terminal).
    @Observable
    final class SelectionState {
        var isSelected: Bool = false
    }

    override func loadView() {
        self.view = NSView(frame: .zero)
    }

    func configure(with viewModel: SessionCardViewModel, isSelected: Bool) {
        selectionModel.isSelected = isSelected

        // Only rebuild the SwiftUI view tree if this is a different session
        guard currentSessionId != viewModel.sessionId else {
            // Same session — selection state is already updated via @Observable
            return
        }
        currentSessionId = viewModel.sessionId

        let selection = selectionModel
        let cardView = AnyView(
            SessionCardItemView(viewModel: viewModel, selection: selection)
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

    /// Update selection without recreating the card view.
    func updateSelection(isSelected: Bool) {
        selectionModel.isSelected = isSelected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentSessionId = nil
    }
}

// MARK: - Session Card Item View (selection-aware wrapper)

/// Wraps SessionCardView and observes SelectionState so the border updates
/// without SwiftUI recreating the terminal view identity.
private struct SessionCardItemView: View {
    let viewModel: SessionCardViewModel
    let selection: SessionCollectionItem.SelectionState

    var body: some View {
        SessionCardView(viewModel: viewModel, isFocused: selection.isSelected)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.green, lineWidth: selection.isSelected ? 3 : 0)
            )
            .shadow(color: selection.isSelected ? .green.opacity(0.3) : .clear, radius: 6)
    }
}
