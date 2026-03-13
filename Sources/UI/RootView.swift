// MARK: - Root View

import SwiftUI
import AgentsBoardCore

public struct RootView: View {
    public init() {}

    public var body: some View {
        NavigationSplitView {
            // Sidebar — Step 5.3
            VStack {
                Text("AgentsBoard")
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .frame(minWidth: 200)
        } detail: {
            // Main content — starts as placeholder, replaced by layout engine in Step 5.1
            VStack(spacing: 16) {
                Image(systemName: "cpu")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("AgentsBoard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("AI Agent Mission Control")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("No active sessions")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
