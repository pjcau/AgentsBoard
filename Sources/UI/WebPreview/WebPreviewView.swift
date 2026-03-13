// MARK: - Web Preview View (Step 10.2)
// Embedded web view for previewing agent-generated web content.

import SwiftUI
import AgentsBoardCore
import WebKit

struct WebPreviewView: View {
    @Bindable var viewModel: WebPreviewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Address bar
            HStack(spacing: 8) {
                Button { viewModel.goBack() } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.canGoBack)

                Button { viewModel.goForward() } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.canGoForward)

                Button { viewModel.reload() } label: {
                    Image(systemName: viewModel.isLoading ? "xmark" : "arrow.clockwise")
                }
                .buttonStyle(.borderless)

                HStack {
                    Image(systemName: viewModel.isSecure ? "lock.fill" : "lock.open")
                        .font(.caption)
                        .foregroundStyle(viewModel.isSecure ? .green : .secondary)

                    TextField("URL", text: $viewModel.urlString)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .onSubmit { viewModel.navigate() }
                }
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Device selector
                Picker("", selection: $viewModel.deviceMode) {
                    Image(systemName: "desktopcomputer").tag(DeviceMode.desktop)
                    Image(systemName: "ipad").tag(DeviceMode.tablet)
                    Image(systemName: "iphone").tag(DeviceMode.phone)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 120)
            }
            .padding(8)
            .background(.ultraThinMaterial)

            Divider()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
            }

            // Web content
            WebViewRepresentable(viewModel: viewModel)
                .frame(maxWidth: viewModel.viewportWidth, maxHeight: .infinity)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Device Mode

enum DeviceMode: String, Sendable {
    case desktop
    case tablet
    case phone
}

// MARK: - WebView Representable

struct WebViewRepresentable: NSViewRepresentable {
    let viewModel: WebPreviewViewModel

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        viewModel.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(viewModel: viewModel) }

    class Coordinator: NSObject, WKNavigationDelegate {
        let viewModel: WebPreviewViewModel

        init(viewModel: WebPreviewViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            viewModel.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.isLoading = false
            viewModel.canGoBack = webView.canGoBack
            viewModel.canGoForward = webView.canGoForward
            viewModel.urlString = webView.url?.absoluteString ?? ""
            viewModel.isSecure = webView.url?.scheme == "https"
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            viewModel.isLoading = false
        }
    }
}

// MARK: - View Model

@Observable
final class WebPreviewViewModel {
    var urlString: String = "http://localhost:3000"
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var isSecure: Bool = false
    var deviceMode: DeviceMode = .desktop

    weak var webView: WKWebView?

    var viewportWidth: CGFloat {
        switch deviceMode {
        case .desktop: return .infinity
        case .tablet: return 768
        case .phone: return 375
        }
    }

    func navigate() {
        guard let url = URL(string: urlString) else { return }
        webView?.load(URLRequest(url: url))
    }

    func reload() {
        if isLoading {
            webView?.stopLoading()
            isLoading = false
        } else {
            webView?.reload()
        }
    }

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }

    func loadHTML(_ html: String) {
        webView?.loadHTMLString(html, baseURL: nil)
    }
}
