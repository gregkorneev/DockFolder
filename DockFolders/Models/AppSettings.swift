import Foundation

struct AppSettings: Codable, Hashable, Sendable {
    var appearance: AppearanceMode
    var launchAtLogin: Bool
    var globalShortcutEnabled: Bool
    var layoutPresets: [FolderLayoutPreset]
    var hoverSettings: HoverSettings

    init(appearance: AppearanceMode = .system, launchAtLogin: Bool = false, globalShortcutEnabled: Bool = false, layoutPresets: [FolderLayoutPreset] = FolderLayoutPreset.defaults, hoverSettings: HoverSettings = HoverSettings()) {
        self.appearance = appearance
        self.launchAtLogin = launchAtLogin
        self.globalShortcutEnabled = globalShortcutEnabled
        let presets = layoutPresets.isEmpty ? FolderLayoutPreset.defaults : layoutPresets
        self.layoutPresets = presets
        self.hoverSettings = hoverSettings
    }

    private enum CodingKeys: String, CodingKey { case appearance, launchAtLogin, globalShortcutEnabled, layoutPresets, hoverSettings }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let presets = try values.decodeIfPresent([FolderLayoutPreset].self, forKey: .layoutPresets) ?? FolderLayoutPreset.defaults
        self.init(
            appearance: try values.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? .system,
            launchAtLogin: try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false,
            globalShortcutEnabled: try values.decodeIfPresent(Bool.self, forKey: .globalShortcutEnabled) ?? false,
            layoutPresets: presets,
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
    var rows: Int?
    var showsAppLabels: Bool

    private enum CodingKeys: String, CodingKey { case id, name, columns, rows, showsAppLabels }

    var isSingleRow: Bool { columns == Self.rowColumns }
    var isSingleColumn: Bool { columns == Self.columnColumns }
    var isCustomGrid: Bool { rows != nil }

    func gridColumns(for applicationCount: Int) -> Int {
        if isSingleColumn { return 1 }
        if isSingleRow { return max(1, applicationCount) }
        return columns
    }

    func fits(_ applicationCount: Int) -> Bool {
        isCustomGrid || isSingleRow || isSingleColumn || columns >= max(1, Int(ceil(sqrt(Double(applicationCount)))))
    }

    func fitting(_ applicationCount: Int) -> Self {
        guard !fits(applicationCount) else { return self }
        let side = max(1, Int(ceil(sqrt(Double(applicationCount)))))
        return Self.dynamicGrid(side: side, showsAppLabels: showsAppLabels)
    }

    static func dynamicGrid(side: Int, showsAppLabels: Bool) -> Self {
        let size = min(max(side, 1), 64)
        return FolderLayoutPreset(id: "dynamic-grid-\(size)", name: "\(size) × \(size)", columns: size, showsAppLabels: showsAppLabels)
    }

    static func customGrid(rows: Int, columns: Int, showsAppLabels: Bool) -> Self {
        let rows = min(max(rows, 1), 10)
        let columns = min(max(columns, 1), 10)
        return Self(id: "custom-grid", name: "\(rows) × \(columns)", columns: columns, rows: rows, showsAppLabels: showsAppLabels)
    }

    static func availableChoices(applicationCount: Int, presets: [Self], showsAppLabels: Bool) -> [Self] {
        let requiredSide = max(1, Int(ceil(sqrt(Double(applicationCount)))))
        let maximumSide = requiredSide <= 10 ? 10 : min(requiredSide + 2, 64)
        let fittingPresets = presets.filter { $0.fits(applicationCount) }
        var squaresBySide: [Int: Self] = [:]
        for preset in fittingPresets where !preset.isSingleRow && !preset.isSingleColumn && preset.columns <= maximumSide {
            squaresBySide[preset.columns] = preset
        }

        if requiredSide <= maximumSide {
            for side in requiredSide...maximumSide where squaresBySide[side] == nil {
                squaresBySide[side] = .dynamicGrid(side: side, showsAppLabels: showsAppLabels)
            }
        }

        let squares = squaresBySide.keys.sorted().compactMap { squaresBySide[$0] }
        let specialLayouts = fittingPresets
            .filter { $0.isSingleRow || $0.isSingleColumn }
            .sorted { $0.isSingleRow && $1.isSingleColumn }
        return squares + specialLayouts
    }

    init(id: String = UUID().uuidString, name: String, columns: Int, rows: Int? = nil, showsAppLabels: Bool = true) {
        self.id = id
        self.name = name
        self.rows = rows.map { min(max($0, 1), 10) }
        self.columns = columns == Self.rowColumns || columns == Self.columnColumns ? columns : min(max(columns, 1), rows == nil ? 64 : 10)
        self.showsAppLabels = showsAppLabels
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try values.decode(String.self, forKey: .id),
            name: try values.decode(String.self, forKey: .name),
            columns: try values.decodeIfPresent(Int.self, forKey: .columns) ?? 4,
            rows: try values.decodeIfPresent(Int.self, forKey: .rows),
            showsAppLabels: try values.decodeIfPresent(Bool.self, forKey: .showsAppLabels) ?? true
        )
    }
}

enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}
