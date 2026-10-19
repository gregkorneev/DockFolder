import Foundation

struct ConfigurationTransferService {
    func export(_ document: FolderDocument, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: url, options: .atomic)
    }

    func `import`(from url: URL) throws -> FolderDocument {
        let data = try Data(contentsOf: url)
        let document = try JSONDecoder().decode(FolderDocument.self, from: data)
        guard document.version == 1 else { throw FolderPersistenceError.unsupportedVersion(document.version) }
        return document
    }
}
