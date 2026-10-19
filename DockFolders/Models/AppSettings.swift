import Foundation

struct AppSettings: Codable, Hashable, Sendable {
    var iconSize: Double
    var gridColumns: Int
    var appearance: AppearanceMode
    var launchAtLogin: Bool
    var globalShortcutEnabled: Bool
    var layoutPresets: [FolderLayoutPreset]
    var defaultLayoutPresetID: String

    init(iconSize: Double = 68, gridColumns: Int = 0, appearance: AppearanceMode = .system, launchAtLogin: Bool = false, globalShortcutEnabled: Bool = false, layoutPresets: [FolderLayoutPreset] = FolderLayoutPreset.defaults, defaultLayoutPresetID: String = FolderLayoutPreset.defaultID) {
        self.iconSize = min(max(iconSize, 36), 128)
        self.gridColumns = min(max(gridColumns, 0), 12)
        self.appearance = appearance
        self.launchAtLogin = launchAtLogin
        self.globalShortcutEnabled = globalShortcutEnabled
        let presets = layoutPresets.isEmpty ? FolderLayoutPreset.defaults : layoutPresets
        self.layoutPresets = presets
        self.defaultLayoutPresetID = presets.first(where: { $0.id == defaultLayoutPresetID })?.id ?? presets[0].id
    }

    private enum CodingKeys: String, CodingKey { case iconSize, gridColumns, appearance, launchAtLogin, globalShortcutEnabled, layoutPresets, defaultLayoutPresetID }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let presets = try values.decodeIfPresent([FolderLayoutPreset].self, forKey: .layoutPresets) ?? FolderLayoutPreset.defaults
        self.init(
            iconSize: try values.decodeIfPresent(Double.self, forKey: .iconSize) ?? 68,
            gridColumns: try values.decodeIfPresent(Int.self, forKey: .gridColumns) ?? 0,
            appearance: try values.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? .system,
            launchAtLogin: try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false,
            globalShortcutEnabled: try values.decodeIfPresent(Bool.self, forKey: .globalShortcutEnabled) ?? false,
            layoutPresets: presets,
            defaultLayoutPresetID: try values.decodeIfPresent(String.self, forKey: .defaultLayoutPresetID) ?? FolderLayoutPreset.defaultID
        )
    }
}

struct FolderLayoutPreset: Codable, Hashable, Identifiable, Sendable {
    static let defaultID = "grid-4"
    static let rowColumns = -1
    static let columnColumns = -2
    static let defaults = [
        FolderLayoutPreset(id: defaultID, name: "4 × 4", columns: 4),
        FolderLayoutPreset(id: "grid-3", name: "3 × 3", columns: 3),
        FolderLayoutPreset(id: "single-row", name: "Single row", columns: rowColumns),
        FolderLayoutPreset(id: "single-column", name: "Single column", columns: columnColumns)
    ]

    var id: String
    var name: String
    var columns: Int
    var showsAppLabels: Bool

    private enum CodingKeys: String, CodingKey { case id, name, columns, showsAppLabels }

    var isSingleRow: Bool { columns == Self.rowColumns }
    var isSingleColumn: Bool { columns == Self.columnColumns }

    func gridColumns(for applicationCount: Int) -> Int {
        if isSingleColumn { return 1 }
        if isSingleRow { return max(1, applicationCount) }
        return columns
    }

    init(id: String = UUID().uuidString, name: String, columns: Int, showsAppLabels: Bool = true) {
        self.id = id
        self.name = name
        self.columns = columns == Self.rowColumns || columns == Self.columnColumns ? columns : min(max(columns, 1), 12)
        self.showsAppLabels = showsAppLabels
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try values.decode(String.self, forKey: .id),
            name: try values.decode(String.self, forKey: .name),
            columns: try values.decodeIfPresent(Int.self, forKey: .columns) ?? 4,
            showsAppLabels: try values.decodeIfPresent(Bool.self, forKey: .showsAppLabels) ?? true
        )
    }
}

enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}
