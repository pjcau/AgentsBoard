// MARK: - iOS Simulator Preview (Step 10.3)
// Embedded simulator screenshot/stream viewer.

import SwiftUI
import AgentsBoardCore

struct SimulatorPreviewView: View {
    @Bindable var viewModel: SimulatorPreviewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("Device", selection: $viewModel.selectedDevice) {
                    ForEach(viewModel.availableDevices, id: \.udid) { device in
                        Text(device.name).tag(device.udid)
                    }
                }
                .frame(maxWidth: 200)

                Spacer()

                Button { viewModel.captureScreenshot() } label: {
                    Label("Capture", systemImage: "camera")
                }
                .buttonStyle(.borderless)

                Button { viewModel.toggleAutoRefresh() } label: {
                    Label(
                        viewModel.autoRefresh ? "Stop" : "Auto",
                        systemImage: viewModel.autoRefresh ? "stop.fill" : "play.fill"
                    )
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
            .background(.ultraThinMaterial)

            Divider()

            // Simulator frame
            ZStack {
                if let image = viewModel.currentScreenshot {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 8)
                        .padding(20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "iphone")
                            .font(.system(size: 48))
                            .foregroundStyle(.quaternary)
                        Text("No simulator running")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("Start a simulator or capture a screenshot")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

// MARK: - Models

struct SimulatorDevice: Identifiable {
    let id = UUID()
    let udid: String
    let name: String
    let runtime: String
    let state: String
}

// MARK: - View Model

@Observable
final class SimulatorPreviewViewModel {
    var selectedDevice: String = ""
    var availableDevices: [SimulatorDevice] = []
    var currentScreenshot: NSImage?
    var autoRefresh: Bool = false

    private var refreshTask: Task<Void, Never>?

    func loadDevices() {
        Task {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["simctl", "list", "devices", "--json"]

            let pipe = Pipe()
            process.standardOutput = pipe

            try? process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let devices = json["devices"] as? [String: [[String: Any]]] else { return }

            var result: [SimulatorDevice] = []
            for (runtime, deviceList) in devices {
                for device in deviceList {
                    guard let name = device["name"] as? String,
                          let udid = device["udid"] as? String,
                          let state = device["state"] as? String else { continue }
                    result.append(SimulatorDevice(
                        udid: udid, name: name,
                        runtime: runtime.components(separatedBy: ".").last ?? runtime,
                        state: state
                    ))
                }
            }

            await MainActor.run {
                self.availableDevices = result.filter { $0.state == "Booted" }
                if self.selectedDevice.isEmpty, let first = self.availableDevices.first {
                    self.selectedDevice = first.udid
                }
            }
        }
    }

    func captureScreenshot() {
        guard !selectedDevice.isEmpty else { return }

        Task {
            let tempPath = NSTemporaryDirectory() + "sim_screenshot_\(UUID().uuidString).png"

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["simctl", "io", selectedDevice, "screenshot", tempPath]

            try? process.run()
            process.waitUntilExit()

            if let image = NSImage(contentsOfFile: tempPath) {
                await MainActor.run {
                    self.currentScreenshot = image
                }
            }
            try? FileManager.default.removeItem(atPath: tempPath)
        }
    }

    func toggleAutoRefresh() {
        autoRefresh.toggle()
        if autoRefresh {
            refreshTask = Task {
                while !Task.isCancelled && autoRefresh {
                    captureScreenshot()
                    try? await Task.sleep(for: .seconds(2))
                }
            }
        } else {
            refreshTask?.cancel()
            refreshTask = nil
        }
    }
}
