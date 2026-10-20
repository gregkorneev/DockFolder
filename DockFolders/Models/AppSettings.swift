import Foundation

struct AppSettings: Codable, Hashable, Sendable {
    var iconSize: Double
    var gridColumns: Int
    var appearance: AppearanceMode
    var glassTransparency: Double
    var launchAtLogin: Bool
    var globalShortcutEnabled: Bool
    var layoutPresets: [FolderLayoutPreset]
    var defaultLayoutPresetID: String
    var hoverSettings: HoverSettings

    init(iconSize: Double = 68, gridColumns: Int = 0, appearance: AppearanceMode = .system, glassTransparency: Double = 0.55, launchAtLogin: Bool = false, globalShortcutEnabled: Bool = false, layoutPresets: [FolderLayoutPreset] = FolderLayoutPreset.defaults, defaultLayoutPresetID: String = FolderLayoutPreset.defaultID, hoverSettings: HoverSettings = HoverSettings()) {
        self.iconSize = min(max(iconSize, 36), 128)
        self.gridColumns = min(max(gridColumns, 0), 12)
        self.appearance = appearance
        self.glassTransparency = min(max(glassTransparency, 0), 1)
        self.launchAtLogin = launchAtLogin
        self.globalShortcutEnabled = globalShortcutEnabled
        let presets = layoutPresets.isEmpty ? FolderLayoutPreset.defaults : layoutPresets
        self.layoutPresets = presets
        self.defaultLayoutPresetID = presets.first(where: { $0.id == defaultLayoutPresetID })?.id ?? presets[0].id
        self.hoverSettings = hoverSettings
    }

    private enum CodingKeys: String, CodingKey { case iconSize, gridColumns, appearance, glassTransparency, launchAtLogin, globalShortcutEnabled, layoutPresets, defaultLayoutPresetID, hoverSettings }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let presets = try values.decodeIfPresent([FolderLayoutPreset].self, forKey: .layoutPresets) ?? FolderLayoutPreset.defaults
        self.init(
            iconSize: try values.decodeIfPresent(Double.self, forKey: .iconSize) ?? 68,
            gridColumns: try values.decodeIfPresent(Int.self, forKey: .gridColumns) ?? 0,
            appearance: try values.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? .system,
            glassTransparency: try values.decodeIfPresent(Double.self, forKey: .glassTransparency) ?? 0.55,
            launchAtLogin: try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false,
            globalShortcutEnabled: try values.decodeIfPresent(Bool.self, forKey: .globalShortcutEnabled) ?? false,
            layoutPresets: presets,
            defaultLayoutPresetID: try values.decodeIfPresent(String.self, forKey: .defaultLayoutPresetID) ?? FolderLayoutPreset.defaultID,
            hoverSettings: try values.decodeIfPresent(HoverSettings.self, forKey: .hoverSettings) ?? HoverSettings()
        )
    }
}

struct HoverSettings: Codable, Hashable, Sendable {
    var mode: DockFolderOpeningMode
    var openDelayMilliseconds: Int
    var closeDelayMilliseconds: Int

    init(mode: DockFolderOpeningMode = .click, openDelayMilliseconds: Int = 180, closeDelayMilliseconds: Int = 250) {
        self.mode = mode
        self.openDelayMilliseconds = min(max(openDelayMilliseconds, 80), 1_000)
        self.closeDelayMilliseconds = min(max(closeDelayMilliseconds, 80), 1_000)
    }

    private enum CodingKeys: String, CodingKey { case mode, openDelayMilliseconds, closeDelayMilliseconds }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            mode: try values.decodeIfPresent(DockFolderOpeningMode.self, forKey: .mode) ?? .click,
            openDelayMilliseconds: try values.decodeIfPresent(Int.self, forKey: .openDelayMilliseconds) ?? 180,
            closeDelayMilliseconds: try values.decodeIfPresent(Int.self, forKey: .closeDelayMilliseconds) ?? 250
        )
    }
}

enum DockFolderOpeningMode: String, Codable, CaseIterable, Sendable {
    case click
    case hover
    case both

    var enablesHover: Bool { self == .hover || self == .both }
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

    func fits(_ applicationCount: Int) -> Bool {
        isSingleRow || isSingleColumn || columns >= max(2, Int(ceil(sqrt(Double(applicationCount)))))
    }

    func fitting(_ applicationCount: Int) -> Self {
        guard !fits(applicationCount) else { return self }
        let side = max(2, Int(ceil(sqrt(Double(applicationCount)))))
        return Self.dynamicGrid(side: side, showsAppLabels: showsAppLabels)
    }

    static func dynamicGrid(side: Int, showsAppLabels: Bool) -> Self {
        let size = min(max(side, 2), 64)
        return FolderLayoutPreset(id: "dynamic-grid-\(size)", name: "\(size) × \(size)", columns: size, showsAppLabels: showsAppLabels)
    }

    init(id: String = UUID().uuidString, name: String, columns: Int, showsAppLabels: Bool = true) {
        self.id = id
        self.name = name
        self.columns = columns == Self.rowColumns || columns == Self.columnColumns ? columns : min(max(columns, 2), 64)
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
