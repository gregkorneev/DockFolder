import Foundation

struct DockFolder: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var applications: [ApplicationItem]
    var iconName: String
    var colorHex: String
    var hasDockLauncher: Bool
    var layoutPreset: FolderLayoutPreset
    var iconSize: Double
    var gridColumns: Int
    var glassTransparency: Double

    init(id: UUID = UUID(), name: String, applications: [ApplicationItem] = [], iconName: String = "folder.fill", colorHex: String = "#0A84FF", hasDockLauncher: Bool = false, layoutPreset: FolderLayoutPreset = FolderLayoutPreset.defaults[0], iconSize: Double = 68, gridColumns: Int = 0, glassTransparency: Double = 0.55) {
        self.id = id
        self.name = name
        self.applications = applications
        self.iconName = iconName
        self.colorHex = colorHex
        self.hasDockLauncher = hasDockLauncher
        self.layoutPreset = layoutPreset.fitting(applications.count)
        self.iconSize = min(max(iconSize, 36), 128)
        self.gridColumns = min(max(gridColumns, 0), 12)
        self.glassTransparency = min(max(glassTransparency, 0), 1)
    }

    private enum CodingKeys: String, CodingKey { case id, name, applications, iconName, colorHex, hasDockLauncher, layoutPreset, iconSize, gridColumns, glassTransparency }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        applications = try values.decodeIfPresent([ApplicationItem].self, forKey: .applications) ?? []
        iconName = try values.decodeIfPresent(String.self, forKey: .iconName) ?? "folder.fill"
        colorHex = try values.decodeIfPresent(String.self, forKey: .colorHex) ?? "#0A84FF"
        hasDockLauncher = try values.decodeIfPresent(Bool.self, forKey: .hasDockLauncher) ?? false
        let decodedPreset = try values.decodeIfPresent(FolderLayoutPreset.self, forKey: .layoutPreset) ?? FolderLayoutPreset.defaults[0]
        layoutPreset = decodedPreset.fitting(applications.count)
        iconSize = min(max(try values.decodeIfPresent(Double.self, forKey: .iconSize) ?? 68, 36), 128)
        gridColumns = min(max(try values.decodeIfPresent(Int.self, forKey: .gridColumns) ?? 0, 0), 12)
        glassTransparency = min(max(try values.decodeIfPresent(Double.self, forKey: .glassTransparency) ?? 0.55, 0), 1)
    }
}

struct FolderDocument: Codable, Sendable {
    var version: Int = 1
    var folders: [DockFolder] = []
    var settings: AppSettings = AppSettings()

    private enum CodingKeys: String, CodingKey { case version, folders, settings }

    init(version: Int = 1, folders: [DockFolder] = [], settings: AppSettings = AppSettings()) {
        self.version = version
        self.folders = folders
        self.settings = settings
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decodeIfPresent(Int.self, forKey: .version) ?? 1
        folders = try values.decodeIfPresent([DockFolder].self, forKey: .folders) ?? []
        settings = try values.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
    }
}
