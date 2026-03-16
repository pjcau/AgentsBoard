// MARK: - Config Routes
// REST endpoints for configuration and themes.

import Foundation
import Hummingbird
import AgentsBoardCore

enum ConfigRoutes {

    static func register(on router: Router<BasicRequestContext>, compositionRoot: ServerCompositionRoot) {
        let configGroup = router.group("api/v1/config")
        let themeGroup = router.group("api/v1/themes")
        let config = compositionRoot.configProvider
        let themes = compositionRoot.themeEngine

        // GET /api/v1/config
        configGroup.get { _, _ -> Response in
            let dto = ConfigDTO(from: config.current)
            return try jsonResponse(dto)
        }

        // GET /api/v1/themes
        themeGroup.get { _, _ -> Response in
            let dto = ThemesDTO(
                active: themes.currentTheme.name,
                available: themes.availableThemes
            )
            return try jsonResponse(dto)
        }

        // PUT /api/v1/themes
        themeGroup.put { request, _ -> Response in
            let body = try await request.body.collect(upTo: 65536)
            guard let dto = try? JSONDecoder().decode(ThemeSelectDTO.self, from: body) else {
                return badRequest("Invalid theme selection body")
            }
            do {
                try themes.loadTheme(named: dto.name)
                return Response(status: .ok, body: .init(byteBuffer: .init(string: "{\"status\":\"applied\"}")))
            } catch {
                return badRequest("Theme not found: \(dto.name)")
            }
        }
    }
}

struct ConfigDTO: Codable {
    let theme: String
    let fontFamily: String
    let fontSize: Double
    let notifications: Bool
    let scrollback: Int
    let layout: String
    let menuBarMode: Bool

    init(from config: AppConfig) {
        self.theme = config.theme
        self.fontFamily = config.fontFamily
        self.fontSize = Double(config.fontSize)
        self.notifications = config.notifications
        self.scrollback = config.scrollback
        self.layout = config.layout.rawValue
        self.menuBarMode = config.menuBarMode
    }
}

struct ThemesDTO: Codable {
    let active: String
    let available: [String]
}

struct ThemeSelectDTO: Codable {
    let name: String
}
