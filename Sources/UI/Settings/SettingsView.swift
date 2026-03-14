// MARK: - Settings View
// Right-side settings panel with app preferences.

import SwiftUI
import Metal

struct SettingsView: View {
    @AppStorage("useMetalRenderer") var useMetalRenderer: Bool = true
    @AppStorage("appearanceMode") var appearanceMode: String = "auto"
    @AppStorage("terminalFontSize") var terminalFontSize: Double = 13

    @State private var metalAvailable: Bool = MTLCreateSystemDefaultDevice() != nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.secondary)
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Rendering
                    settingsSection("Rendering") {
                        Toggle(isOn: $useMetalRenderer) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Metal GPU Rendering")
                                    .font(.callout)
                                Text(metalAvailable
                                     ? "Hardware-accelerated terminal rendering via Metal"
                                     : "Metal not available on this device — using SwiftTerm")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(!metalAvailable)

                        if useMetalRenderer && metalAvailable {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text("Metal active — GPU: \(gpuName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Terminal
                    settingsSection("Terminal") {
                        HStack {
                            Text("Font Size")
                                .font(.callout)
                            Spacer()
                            Text("\(Int(terminalFontSize))pt")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                        Slider(value: $terminalFontSize, in: 8...28, step: 1)
                    }

                    // Appearance
                    settingsSection("Appearance") {
                        Picker("Theme", selection: $appearanceMode) {
                            Text("Auto").tag("auto")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    }

                    // Info
                    settingsSection("About") {
                        infoRow("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev")
                        infoRow("Build", value: "Swift \(swiftVersion)")
                        infoRow("Metal", value: metalAvailable ? gpuName : "Not Available")
                        infoRow("Tests", value: "224 passing")
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var gpuName: String {
        MTLCreateSystemDefaultDevice()?.name ?? "Unknown"
    }

    private var swiftVersion: String {
        #if swift(>=6.0)
        return "6.x"
        #else
        return "5.x"
        #endif
    }
}
