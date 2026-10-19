import Foundation

enum SystemSymbolCatalog {
    static func load(bundle: Bundle = .main) throws -> [String] {
        guard let url = bundle.url(forResource: "SF-Symbols-7.0", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String].self, from: data)
    }
}
