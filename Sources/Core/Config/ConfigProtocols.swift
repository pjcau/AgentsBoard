// MARK: - Config Protocols

import Foundation

/// Provides application configuration from multiple cascading sources.
public protocol ConfigProviding: AnyObject {
    var current: AppConfig { get }
    func reload() throws
    var onConfigChange: ((AppConfig) -> Void)? { get set }
}

/// Provides theme data.
public protocol ThemeProviding: AnyObject {
    var currentTheme: Theme { get }
    var availableThemes: [String] { get }
    func loadTheme(named name: String) throws
    var onThemeChange: ((Theme) -> Void)? { get set }
}

/// Parses YAML content (DIP wrapper around Yams).
public protocol YAMLParsing {
    func decode<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T
    func encode<T: Encodable>(_ value: T) throws -> String
}
