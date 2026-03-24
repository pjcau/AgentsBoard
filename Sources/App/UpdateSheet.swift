// MARK: - Update Sheet

import SwiftUI
import AgentsBoardUI

/// Modal sheet for checking and applying Homebrew updates.
/// SRP: Only handles update UI — delegates all logic to BrewUpdateManager.
struct UpdateSheet: View {
    let updateManager: BrewUpdateManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text(L10n.App.updateTitle)
                .font(.title2)
                .fontWeight(.semibold)

            // Current version
            Text("\(L10n.App.currentVersion): \(updateManager.currentVersion)")
                .font(.callout)
                .foregroundStyle(.secondary)

            // State-specific content
            stateContent

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(L10n.App.close) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                actionButton
            }
        }
        .padding(24)
        .frame(width: 380, height: 280)
        .task {
            await updateManager.checkForUpdates()
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch updateManager.state {
        case .idle, .checking:
            ProgressView(L10n.App.checkingForUpdates)
                .controlSize(.small)

        case .upToDate:
            Label(L10n.App.upToDate, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.callout)

        case .available(let latest):
            Label(
                String(format: L10n.App.updateAvailable, latest),
                systemImage: "arrow.down.circle.fill"
            )
            .foregroundStyle(.orange)
            .font(.callout)

        case .updating:
            VStack(spacing: 8) {
                ProgressView(L10n.App.installingUpdate)
                    .controlSize(.small)
                Text(L10n.App.doNotClose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .restartRequired:
            Label(L10n.App.restarting, systemImage: "arrow.clockwise.circle.fill")
                .foregroundStyle(.blue)
                .font(.callout)

        case .error(let msg):
            VStack(spacing: 4) {
                Label(L10n.App.updateError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch updateManager.state {
        case .available:
            Button(L10n.App.updateNow) {
                Task { await updateManager.applyUpdate() }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)

        case .upToDate:
            Button(L10n.App.recheckUpdates) {
                Task { await updateManager.checkForUpdates() }
            }

        case .error:
            Button(L10n.App.recheckUpdates) {
                Task { await updateManager.checkForUpdates() }
            }

        default:
            EmptyView()
        }
    }
}
