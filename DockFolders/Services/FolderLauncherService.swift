import AppKit
import Foundation

enum FolderLauncherError: LocalizedError {
    case iconCouldNotBeApplied

    var errorDescription: String? {
        switch self {
        case .iconCouldNotBeApplied: NSLocalizedString("The folder launcher was created, but its custom Dock icon could not be applied.", comment: "")
        }
    }
}

@MainActor
struct FolderLauncherService {
    let rootURL: URL
    private let legacyRootURL: URL?

    init(rootURL: URL? = nil) {
        let fileManager = FileManager.default
        self.rootURL = rootURL ?? URL(fileURLWithPath: "/Applications", isDirectory: true)
            .appendingPathComponent("DockFolders", isDirectory: true)
        self.legacyRootURL = rootURL == nil
            ? fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
                .appendingPathComponent("DockFolders", isDirectory: true)
            : nil
    }

    func launcherURL(for folder: DockFolder) -> URL {
        rootURL.appendingPathComponent("\(safeFilename(for: folder.name)).app", isDirectory: true)
    }

    func migrateLegacyLauncherIfNeeded(for folder: DockFolder) throws {
        guard let legacyRootURL else { return }
        let oldLauncherURL = legacyRootURL.appendingPathComponent("\(folder.id.uuidString).app", isDirectory: true)
        let oldCurrentLauncherURL = rootURL.appendingPathComponent("\(folder.id.uuidString).app", isDirectory: true)
        let currentLauncher = launcherURL(for: folder)
        guard FileManager.default.fileExists(atPath: oldLauncherURL.path)
                || FileManager.default.fileExists(atPath: oldCurrentLauncherURL.path)
                || FileManager.default.fileExists(atPath: currentLauncher.path)
                || FileManager.default.fileExists(atPath: legacyRootURL.path) else { return }
        _ = try createOrUpdate(for: folder)
    }

    @discardableResult
    func createOrUpdate(for folder: DockFolder) throws -> URL {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let oldURL = existingLauncherURL(for: folder.id)
        let appURL = try uniqueLauncherURL(for: folder, preserving: oldURL)
        let isExisting = oldURL == appURL
        if !isExisting, FileManager.default.fileExists(atPath: appURL.path) {
            throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: appURL.path])
        }
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

        let info: [String: Any] = [
            "CFBundleDevelopmentRegion": "en",
            "CFBundleDisplayName": folder.name,
            "CFBundleExecutable": "launch",
            "CFBundleIdentifier": "com.gregkorneev.DockFolders.launcher.\(folder.id.uuidString.lowercased())",
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleName": folder.name,
            "CFBundlePackageType": "APPL",
            "CFBundleVersion": "1",
            "LSUIElement": true
        ]
        let plist = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try plist.write(to: contentsURL.appendingPathComponent("Info.plist"), options: .atomic)
        try Data("APPL????".utf8).write(to: contentsURL.appendingPathComponent("PkgInfo"), options: .atomic)

        let url = DockFolderLink.url(for: folder.id)
        let command = "#!/bin/sh\nexec /usr/bin/open '\(url.absoluteString)'\n"
        let executableURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true).appendingPathComponent("launch")
        try FileManager.default.createDirectory(at: executableURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(command.utf8).write(to: executableURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableURL.path)

        let icon = makeIcon(symbol: folder.iconName, color: NSColor(hex: folder.colorHex))
        guard NSWorkspace.shared.setIcon(icon, forFile: appURL.path, options: []) else {
            throw FolderLauncherError.iconCouldNotBeApplied
        }
        if let oldURL, oldURL != appURL, FileManager.default.fileExists(atPath: oldURL.path) {
            try FileManager.default.removeItem(at: oldURL)
        }
        if let legacyRootURL {
            let legacyLauncherURL = legacyRootURL.appendingPathComponent("\(folder.id.uuidString).app", isDirectory: true)
            if FileManager.default.fileExists(atPath: legacyLauncherURL.path) {
                try? FileManager.default.removeItem(at: legacyLauncherURL)
            }
        }
        return appURL
    }

    func remove(for folderID: UUID) throws {
        for appURL in launcherRoots().flatMap(appBundles(in:)) where bundleID(at: appURL) == bundleIdentifier(for: folderID) {
            try FileManager.default.removeItem(at: appURL)
        }
        let oldURL = rootURL.appendingPathComponent("\(folderID.uuidString).app", isDirectory: true)
        if FileManager.default.fileExists(atPath: oldURL.path) {
            try FileManager.default.removeItem(at: oldURL)
        }
    }

    private func makeIcon(symbol: String, color: NSColor) -> NSImage {
        let canvasSize = NSSize(width: 512, height: 512)
        let image = NSImage(size: canvasSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        let inset: CGFloat = 18
        let background = NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: 476, height: 476), xRadius: 112, yRadius: 112)
        color.setFill()
        background.fill()

        let configuration = NSImage.SymbolConfiguration(pointSize: 260, weight: .medium)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: .white))
        let glyph = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(configuration)
        glyph?.draw(in: NSRect(x: 110, y: 110, width: 292, height: 292))
        return image
    }

    private func safeFilename(for name: String) -> String {
        let filename = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return filename.isEmpty ? "Folder" : filename
    }

    private func uniqueLauncherURL(for folder: DockFolder, preserving oldURL: URL?) throws -> URL {
        let baseName = safeFilename(for: folder.name)
        let preferred = rootURL.appendingPathComponent("\(baseName).app", isDirectory: true)
        if preferred == oldURL || !FileManager.default.fileExists(atPath: preferred.path) {
            return preferred
        }
        if bundleID(at: preferred) == bundleIdentifier(for: folder.id) { return preferred }

        var suffix = 2
        while true {
            let candidate = rootURL.appendingPathComponent("\(baseName) \(suffix).app", isDirectory: true)
            if candidate == oldURL || !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            if bundleID(at: candidate) == bundleIdentifier(for: folder.id) { return candidate }
            suffix += 1
        }
    }

    private func existingLauncherURL(for folderID: UUID) -> URL? {
        if let matchingLauncher = launcherRoots().flatMap(appBundles(in:)).first(where: {
            bundleID(at: $0) == bundleIdentifier(for: folderID)
        }) {
            return matchingLauncher
        }
        let legacyNameURL = rootURL.appendingPathComponent("\(folderID.uuidString).app", isDirectory: true)
        return FileManager.default.fileExists(atPath: legacyNameURL.path) ? legacyNameURL : nil
    }

    private func launcherRoots() -> [URL] {
        [rootURL] + (legacyRootURL.map { [$0] } ?? [])
    }

    private func appBundles(in root: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey]))?
            .filter { $0.pathExtension == "app" } ?? []
    }

    private func bundleID(at appURL: URL) -> String? {
        guard let info = NSDictionary(contentsOf: appURL.appendingPathComponent("Contents/Info.plist")) as? [String: Any] else { return nil }
        return info["CFBundleIdentifier"] as? String
    }

    private func bundleIdentifier(for folderID: UUID) -> String {
        "com.gregkorneev.DockFolders.launcher.\(folderID.uuidString.lowercased())"
    }
}

extension NSColor {
    convenience init(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(digits, radix: 16) ?? 0x0A84FF
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
