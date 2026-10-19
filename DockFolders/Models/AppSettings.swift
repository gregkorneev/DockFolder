import Foundation

struct AppSettings: Codable, Hashable, Sendable {
    var iconSize: Double
    var gridColumns: Int
    var appearance: AppearanceMode
    var launchAtLogin: Bool
    var globalShortcutEnabled: Bool

    init(iconSize: Double = 68, gridColumns: Int = 0, appearance: AppearanceMode = .system, launchAtLogin: Bool = false, globalShortcutEnabled: Bool = false) {
        self.iconSize = min(max(iconSize, 36), 128)
        self.gridColumns = min(max(gridColumns, 0), 12)
        self.appearance = appearance
        self.launchAtLogin = launchAtLogin
        self.globalShortcutEnabled = globalShortcutEnabled
    }

    private enum CodingKeys: String, CodingKey { case iconSize, gridColumns, appearance, launchAtLogin, globalShortcutEnabled }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            iconSize: try values.decodeIfPresent(Double.self, forKey: .iconSize) ?? 68,
            gridColumns: try values.decodeIfPresent(Int.self, forKey: .gridColumns) ?? 0,
            appearance: try values.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? .system,
            launchAtLogin: try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false,
            globalShortcutEnabled: try values.decodeIfPresent(Bool.self, forKey: .globalShortcutEnabled) ?? false
        )
    }
}

enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}
