// MARK: - Command Palette View (Step 7.1)
// Cmd+K spotlight-style command palette with fuzzy search.

import SwiftUI
import AgentsBoardCore

struct CommandPaletteView: View {
    @Bindable var viewModel: CommandPaletteViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                TextField("Type a command...", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isSearchFocused)
                    .onSubmit { viewModel.executeSelected() }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)

            Divider()

            // Category tabs
            if viewModel.query.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        CategoryTab(title: "All", isSelected: viewModel.selectedCategory == nil) {
                            viewModel.selectedCategory = nil
                        }
                        ForEach(CommandCategory.allCases, id: \.self) { category in
                            CategoryTab(
                                title: category.rawValue,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }

            // Results
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(viewModel.results.enumerated()), id: \.element.command.id) { index, match in
                            CommandRow(
                                match: match,
                                isSelected: index == viewModel.selectedIndex
                            )
                            .id(index)
                            .onTapGesture {
                                viewModel.selectedIndex = index
                                viewModel.executeSelected()
                            }
                        }
                    }
                    .padding(8)
                }
                .onChange(of: viewModel.selectedIndex) { _, newIndex in
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }

            // Footer
            HStack {
                KeyHint(keys: ["↑", "↓"], label: "navigate")
                KeyHint(keys: ["↩"], label: "execute")
                KeyHint(keys: ["esc"], label: "dismiss")
                Spacer()
                Text("\(viewModel.results.count) commands")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 400, idealWidth: 600, maxWidth: 700,
               minHeight: 300, idealHeight: 420, maxHeight: 500)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .onAppear { isSearchFocused = true }
    }
}

// MARK: - Command Row

struct CommandRow: View {
    let match: FuzzyMatch
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: match.command.icon)
                .font(.callout)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(match.command.title)
                    .font(.callout)
                    .lineLimit(1)
                if let subtitle = match.command.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let shortcut = match.command.shortcut {
                Text(shortcut)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(isSelected ? Color.accentColor : Color.clear))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Key Hint

struct KeyHint: View {
    let keys: [String]
    let label: String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.trailing, 8)
    }
}

// MARK: - View Model

@Observable
final class CommandPaletteViewModel {
    var query: String = "" {
        didSet { updateResults() }
    }
    var selectedCategory: CommandCategory? = nil {
        didSet { updateResults() }
    }
    var selectedIndex: Int = 0
    var isPresented: Bool = false

    private(set) var results: [FuzzyMatch] = []

    private let registry: CommandRegistry
    private let matcher = FuzzyMatcher()

    init(registry: CommandRegistry) {
        self.registry = registry
        updateResults()
    }

    func moveUp() {
        if selectedIndex > 0 { selectedIndex -= 1 }
    }

    func moveDown() {
        if selectedIndex < results.count - 1 { selectedIndex += 1 }
    }

    func executeSelected() {
        guard selectedIndex < results.count else { return }
        let command = results[selectedIndex].command
        isPresented = false
        command.action()
    }

    func toggle() {
        isPresented.toggle()
        if isPresented {
            query = ""
            selectedIndex = 0
            updateResults()
        }
    }

    private func updateResults() {
        let commands: [PaletteCommand]
        if let category = selectedCategory {
            commands = registry.commands(in: category)
        } else {
            commands = registry.allCommands
        }

        if query.isEmpty {
            results = commands.map { FuzzyMatch(command: $0, score: 0, matchedRanges: []) }
        } else {
            results = matcher.match(query: query, commands: commands)
        }

        selectedIndex = 0
    }
}
