import Foundation

struct DockFolder: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var applications: [ApplicationItem]

    init(id: UUID = UUID(), name: String, applications: [ApplicationItem] = []) {
        self.id = id
        self.name = name
        self.applications = applications
    }
}

struct FolderDocument: Codable, Sendable {
    var version: Int = 1
    var folders: [DockFolder] = []
}
