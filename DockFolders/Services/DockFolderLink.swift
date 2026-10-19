import Foundation

enum DockFolderLink {
    static let scheme = "dockfolders"

    static func url(for folderID: UUID) -> URL {
        URL(string: "\(scheme)://folder/\(folderID.uuidString)")!
    }

    static func folderID(from url: URL) -> UUID? {
        guard url.scheme?.lowercased() == scheme,
              url.host?.lowercased() == "folder",
              url.query == nil,
              url.fragment == nil,
              url.pathComponents.count == 2 else { return nil }
        return UUID(uuidString: url.pathComponents[1])
    }
}
