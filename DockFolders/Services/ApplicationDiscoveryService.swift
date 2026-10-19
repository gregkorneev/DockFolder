import Foundation

struct ApplicationDiscoveryService: Sendable {
    let searchRoots: [URL]

    init(searchRoots: [URL] = ApplicationDiscoveryService.defaultRoots) {
        self.searchRoots = searchRoots
    }

    private static var defaultRoots: [URL] {
        let homeApplications = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
        return [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            homeApplications
        ]
    }

    func discoverApplications() async -> [ApplicationItem] {
        let roots = searchRoots
        return await Task.detached(priority: .userInitiated) {
            let fileManager = FileManager.default
            var results: [ApplicationItem] = []
            var paths = Set<String>()
            for root in roots where fileManager.fileExists(atPath: root.path) {
                guard let enumerator = fileManager.enumerator(
                    at: root,
                    includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants],
                    errorHandler: { _, _ in true }
                ) else { continue }

                while let url = enumerator.nextObject() as? URL {
                    if enumerator.level > 4 {
                        enumerator.skipDescendants()
                        continue
                    }
                    guard url.pathExtension.lowercased() == "app" else { continue }
                    let path = url.standardizedFileURL.path
                    if paths.insert(path).inserted { results.append(ApplicationItem(url: url)) }
                    enumerator.skipDescendants()
                }
            }
            return results.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }.value
    }
}
