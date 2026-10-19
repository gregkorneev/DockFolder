import Foundation

enum FolderPersistenceError: LocalizedError {
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version): AppLocalization.format("Folder data version %d is not supported.", version)
        }
    }
}

struct FolderPersistenceService {
    let fileURL: URL

    init(fileURL: URL = FolderPersistenceService.defaultFileURL) {
        self.fileURL = fileURL
    }

    static var defaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("DockFolders", isDirectory: true)
            .appendingPathComponent("folders.json")
    }

    func load() throws -> FolderDocument {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return FolderDocument() }
        let data = try Data(contentsOf: fileURL)
        let document = try JSONDecoder().decode(FolderDocument.self, from: data)
        guard document.version == 1 else { throw FolderPersistenceError.unsupportedVersion(document.version) }
        return document
    }

    func save(_ document: FolderDocument) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: fileURL, options: .atomic)
    }
}
