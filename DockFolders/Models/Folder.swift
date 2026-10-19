import Foundation

struct DockFolder: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var applications: [ApplicationItem]
    var iconName: String
    var colorHex: String
    var hasDockLauncher: Bool
    var layoutPreset: FolderLayoutPreset

    init(id: UUID = UUID(), name: String, applications: [ApplicationItem] = [], iconName: String = "folder.fill", colorHex: String = "#0A84FF", hasDockLauncher: Bool = false, layoutPreset: FolderLayoutPreset = FolderLayoutPreset.defaults[0]) {
        self.id = id
        self.name = name
        self.applications = applications
        self.iconName = iconName
        self.colorHex = colorHex
        self.hasDockLauncher = hasDockLauncher
        self.layoutPreset = layoutPreset
    }

    private enum CodingKeys: String, CodingKey { case id, name, applications, iconName, colorHex, hasDockLauncher, layoutPreset }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        applications = try values.decodeIfPresent([ApplicationItem].self, forKey: .applications) ?? []
        iconName = try values.decodeIfPresent(String.self, forKey: .iconName) ?? "folder.fill"
        colorHex = try values.decodeIfPresent(String.self, forKey: .colorHex) ?? "#0A84FF"
        hasDockLauncher = try values.decodeIfPresent(Bool.self, forKey: .hasDockLauncher) ?? false
        layoutPreset = try values.decodeIfPresent(FolderLayoutPreset.self, forKey: .layoutPreset) ?? FolderLayoutPreset.defaults[0]
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
