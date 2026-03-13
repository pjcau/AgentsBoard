// MARK: - Config Manager (Step 1.3)
// Implements ConfigProviding with 3-level cascade: defaults → user → project

import Foundation
import Observation

@Observable
public final class ConfigManager: ConfigProviding {

    // MARK: - Properties

    public private(set) var current: AppConfig = .default
    public var onConfigChange: ((AppConfig) -> Void)?

    private let yamlParser: any YAMLParsing
    private let userConfigPath: String
    private var projectConfigPath: String?
    private var fileWatchers: [DispatchSourceFileSystemObject] = []

    // MARK: - Config Paths

    public static let userConfigDir = "\(NSHomeDirectory())/.config/agentsboard"
    public static let userConfigFile = "\(userConfigDir)/config.yml"
    public static let appSupportDir = "\(NSHomeDirectory())/Library/Application Support/AgentsBoard"
    public static let themesDir = "\(appSupportDir)/themes"

    // MARK: - Init (DIP: depends on YAMLParsing protocol, not Yams)

    public init(yamlParser: any YAMLParsing, userConfigPath: String? = nil) {
        self.yamlParser = yamlParser
        self.userConfigPath = userConfigPath ?? Self.userConfigFile
        ensureDirectories()
    }

    // MARK: - ConfigProviding

    public func reload() throws {
        var config = AppConfig.default

        // Layer 1: User config
        if let userYAML = try? String(contentsOfFile: userConfigPath, encoding: .utf8) {
            if let userConfig = try? yamlParser.decode(AppConfig.self, from: userYAML) {
                config = merge(base: config, overlay: userConfig)
            }
        }

        // Layer 2: Project config (if set)
        if let projectPath = projectConfigPath,
           let projectYAML = try? String(contentsOfFile: projectPath, encoding: .utf8),
           let projectConfig = try? yamlParser.decode(AppConfig.self, from: projectYAML) {
            config = merge(base: config, overlay: projectConfig)
        }

        let oldConfig = current
        current = config

        if oldConfig != config {
            onConfigChange?(config)
        }
    }

    // MARK: - Project Config

    public func setProjectConfig(path: String) {
        projectConfigPath = path
        try? reload()
        watchFile(at: path)
    }

    // MARK: - Hot Reload

    public func startWatching() {
        watchFile(at: userConfigPath)
        if let projectPath = projectConfigPath {
            watchFile(at: projectPath)
        }
    }

    public func stopWatching() {
        fileWatchers.forEach { $0.cancel() }
        fileWatchers.removeAll()
    }

    // MARK: - Private

    private func ensureDirectories() {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: Self.userConfigDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: Self.appSupportDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: Self.themesDir, withIntermediateDirectories: true)
    }

    private func merge(base: AppConfig, overlay: AppConfig) -> AppConfig {
        // Overlay non-default values onto base
        var result = base
        if overlay.theme != AppConfig.default.theme { result.theme = overlay.theme }
        if overlay.fontFamily != AppConfig.default.fontFamily { result.fontFamily = overlay.fontFamily }
        if overlay.fontSize != AppConfig.default.fontSize { result.fontSize = overlay.fontSize }
        if overlay.notifications != AppConfig.default.notifications { result.notifications = overlay.notifications }
        if overlay.scrollback != AppConfig.default.scrollback { result.scrollback = overlay.scrollback }
        if overlay.layout != AppConfig.default.layout { result.layout = overlay.layout }
        if overlay.menuBarMode != AppConfig.default.menuBarMode { result.menuBarMode = overlay.menuBarMode }
        return result
    }

    private func watchFile(at path: String) {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            try? self?.reload()
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileWatchers.append(source)
    }
}
