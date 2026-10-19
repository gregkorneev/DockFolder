import Foundation

struct ApplicationItem: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var path: String
    var bundleIdentifier: String?

    init(url: URL, name: String? = nil) {
        let standardizedURL = url.standardizedFileURL
        self.id = UUID()
        self.name = name ?? standardizedURL.deletingPathExtension().lastPathComponent
        self.path = standardizedURL.path
        self.bundleIdentifier = Bundle(url: standardizedURL)?.bundleIdentifier
    }

    var url: URL { URL(fileURLWithPath: path) }

    func matches(_ other: ApplicationItem) -> Bool {
        if let bundleIdentifier, let otherIdentifier = other.bundleIdentifier {
            return bundleIdentifier == otherIdentifier
        }
        return url.standardizedFileURL.path == other.url.standardizedFileURL.path
    }
}
