---
sidebar_position: 1
---

# Core Protocols

All major interfaces in AgentsBoard defined as protocols for DIP compliance.

## Configuration

```swift
public protocol ConfigProviding: AnyObject {
    var current: AppConfig { get }
    var onConfigChange: ((AppConfig) -> Void)? { get set }
    func reload() throws
}

public protocol ThemeProviding: AnyObject {
    var currentTheme: Theme { get }
    var availableThemes: [String] { get }
    var onThemeChange: ((Theme) -> Void)? { get set }
    func loadTheme(named name: String) throws
}

public protocol YAMLParsing {
    func decode<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T
    func encode<T: Encodable>(_ value: T) throws -> String
}
```

## Persistence

```swift
public protocol PersistenceProviding {
    func save<T: Codable & Identifiable>(_ record: T, in table: String) throws
    func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T?
    func fetchAll<T: Codable & Identifiable>(from table: String) throws -> [T]
    func delete(from table: String, id: String) throws
    func deleteAll(from table: String) throws
    func query<T: Codable>(sql: String, arguments: [Any]) throws -> [T]
}
```

## Terminal

```swift
public protocol TerminalSessionManaging {
    var sessionId: String { get }
    var isRunning: Bool { get }
    var terminalSize: TerminalSize { get }
    var dataDelegate: TerminalDataReceiving? { get set }
    func launch(command: String, workingDirectory: String?, environment: [String: String]?) throws
    func sendInput(_ data: Data)
    func resize(columns: Int, rows: Int)
    func terminate()
}

public protocol TerminalDataReceiving: AnyObject {
    func terminalSession(_ session: any TerminalSessionManaging, didReceiveData data: Data)
    func terminalSession(_ session: any TerminalSessionManaging, didExitWithCode code: Int32)
}
```

## Recording

```swift
public protocol SessionRecordable {
    var isRecording: Bool { get }
    func startRecording(sessionId: String) throws
    func stopRecording(sessionId: String) throws -> URL
    func recordData(_ data: Data, forSession sessionId: String)
}
```

## Rendering

```swift
public protocol TerminalRenderable {
    func render(viewports: [TerminalViewportData])
    func updateGlyphAtlas(fontFamily: String, fontSize: CGFloat)
    func invalidate()
}
```
