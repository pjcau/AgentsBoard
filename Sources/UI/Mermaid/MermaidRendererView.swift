// MARK: - Mermaid Renderer View (Step 11.1)
// Renders Mermaid diagrams from agent output using embedded web view.

import SwiftUI
import AppKit
import AgentsBoardCore
import WebKit
import UniformTypeIdentifiers

struct MermaidRendererView: View {
    @Bindable var viewModel: MermaidRendererViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(.blue)
                Text("Diagram")
                    .font(.headline)

                Spacer()

                Picker("Theme", selection: $viewModel.diagramTheme) {
                    Text("Default").tag(MermaidTheme.default_)
                    Text("Dark").tag(MermaidTheme.dark)
                    Text("Forest").tag(MermaidTheme.forest)
                    Text("Neutral").tag(MermaidTheme.neutral)
                }
                .frame(maxWidth: 120)

                Button { viewModel.exportAsPNG() } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
            .background(.ultraThinMaterial)

            Divider()

            // Mermaid web view
            if viewModel.hasContent {
                MermaidWebView(definition: viewModel.mermaidSource, theme: viewModel.diagramTheme, viewModel: viewModel)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundStyle(.quaternary)
                    Text("No diagram to display")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Mermaid Theme

enum MermaidTheme: String, Sendable {
    case default_ = "default"
    case dark
    case forest
    case neutral
}

// MARK: - Mermaid Web View

struct MermaidWebView: NSViewRepresentable {
    let definition: String
    let theme: MermaidTheme
    weak var viewModel: MermaidRendererViewModel?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        viewModel?.webView = webView
        loadMermaid(in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        viewModel?.webView = webView
        loadMermaid(in: webView)
    }

    private func loadMermaid(in webView: WKWebView) {
        let escaped = definition
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "\n", with: "\\n")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    margin: 0; padding: 20px;
                    display: flex; justify-content: center; align-items: center;
                    min-height: 100vh;
                    background: transparent;
                    font-family: -apple-system, system-ui;
                }
                .mermaid { max-width: 100%; }
                .error { color: #ff6b6b; font-size: 14px; }
            </style>
            <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
        </head>
        <body>
            <div class="mermaid" id="diagram"></div>
            <script>
                mermaid.initialize({
                    startOnLoad: false,
                    theme: '\(theme.rawValue)',
                    securityLevel: 'strict'
                });
                async function render() {
                    try {
                        const { svg } = await mermaid.render('rendered', `\(escaped)`);
                        document.getElementById('diagram').innerHTML = svg;
                    } catch(e) {
                        document.getElementById('diagram').innerHTML =
                            '<div class="error">Diagram error: ' + e.message + '</div>';
                    }
                }
                render();
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - View Model

@Observable
final class MermaidRendererViewModel {
    var mermaidSource: String = ""
    var diagramTheme: MermaidTheme = .dark

    var hasContent: Bool { !mermaidSource.isEmpty }

    func loadFromOutput(_ text: String) {
        // Extract mermaid blocks from markdown
        let pattern = #"```mermaid\n([\s\S]*?)```"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return }
        mermaidSource = String(text[range])
    }

    /// Reference to the web view for screenshot export. Set by MermaidWebView coordinator.
    weak var webView: WKWebView?

    func exportAsPNG() {
        guard let webView else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "diagram.png"
        savePanel.canCreateDirectories = true

        guard savePanel.runModal() == .OK, let url = savePanel.url else { return }

        let config = WKSnapshotConfiguration()
        webView.takeSnapshot(with: config) { image, error in
            guard let image, error == nil else { return }
            guard let tiffData = image.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmapRep.representation(using: .png, properties: [:]) else { return }
            try? pngData.write(to: url)
        }
    }
}
