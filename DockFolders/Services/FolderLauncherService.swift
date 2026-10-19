import AppKit
import Foundation

enum FolderLauncherError: LocalizedError {
    case iconCouldNotBeApplied

    var errorDescription: String? {
        switch self {
        case .iconCouldNotBeApplied: "The folder launcher was created, but its custom Dock icon could not be applied."
        }
    }
}

@MainActor
struct FolderLauncherService {
    let rootURL: URL

    init(rootURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications", isDirectory: true)
        .appendingPathComponent("DockFolders", isDirectory: true)) {
        self.rootURL = rootURL
    }

    func launcherURL(for folderID: UUID) -> URL {
        rootURL.appendingPathComponent("\(folderID.uuidString).app", isDirectory: true)
    }

    @discardableResult
    func createOrUpdate(for folder: DockFolder) throws -> URL {
        let appURL = launcherURL(for: folder.id)
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
        return appURL
    }

    func remove(for folderID: UUID) throws {
        let appURL = launcherURL(for: folderID)
        guard FileManager.default.fileExists(atPath: appURL.path) else { return }
        try FileManager.default.removeItem(at: appURL)
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
