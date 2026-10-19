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
            "CFBundleIconFile": "AppIcon.icns",
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
        try writeBundleIcon(icon, contentsURL: contentsURL)
        // Remove legacy Finder custom-icon metadata so Dock reads the standard app-bundle icon.
        guard NSWorkspace.shared.setIcon(nil, forFile: appURL.path, options: []) else {
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

    func makeIcon(symbol: String, color: NSColor) -> NSImage {
        let pixelSize = 1_024
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return NSImage(size: NSSize(width: pixelSize, height: pixelSize))
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high

        // Supply a square, unmasked 1024 px (@2x) image in the standard
        // 512 pt maximum icon slot. macOS scales it for system surfaces.
        color.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)).fill()

        let configuration = NSImage.SymbolConfiguration(pointSize: 560, weight: .medium)
            .applying(NSImage.SymbolConfiguration(hierarchicalColor: .white))
        let glyph = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
        glyph?.withSymbolConfiguration(configuration)?.draw(in: NSRect(x: 240, y: 240, width: 544, height: 544))

        NSGraphicsContext.restoreGraphicsState()
        bitmap.size = NSSize(width: pixelSize / 2, height: pixelSize / 2)
        let image = NSImage(size: bitmap.size)
        image.addRepresentation(bitmap)
        return image
    }

    private func writeBundleIcon(_ image: NSImage, contentsURL: URL) throws {
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)
        let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
        let iconURL = resourcesURL.appendingPathComponent("AppIcon.icns")
        try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: iconsetURL) }

        for points in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let pixels = points * scale
                guard let bitmap = NSBitmapImageRep(
                    bitmapDataPlanes: nil,
                    pixelsWide: pixels,
                    pixelsHigh: pixels,
                    bitsPerSample: 8,
                    samplesPerPixel: 4,
                    hasAlpha: true,
                    isPlanar: false,
                    colorSpaceName: .deviceRGB,
                    bytesPerRow: 0,
                    bitsPerPixel: 0
                ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
                    throw FolderLauncherError.iconCouldNotBeApplied
                }
                bitmap.size = NSSize(width: pixels, height: pixels)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = context
                context.imageInterpolation = .high
                image.draw(
                    in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
                    from: NSRect(origin: .zero, size: image.size),
                    operation: .copy,
                    fraction: 1
                )
                NSGraphicsContext.restoreGraphicsState()

                guard let png = bitmap.representation(using: .png, properties: [:]) else {
                    throw FolderLauncherError.iconCouldNotBeApplied
                }
                let suffix = scale == 2 ? "@2x" : ""
                let fileURL = iconsetURL.appendingPathComponent("icon_\(points)x\(points)\(suffix).png")
                try png.write(to: fileURL, options: .atomic)
            }
        }

        let iconutil = Process()
        iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        iconutil.arguments = ["-c", "icns", "-o", iconURL.path, iconsetURL.path]
        try iconutil.run()
        iconutil.waitUntilExit()
        guard iconutil.terminationStatus == 0 else {
            throw FolderLauncherError.iconCouldNotBeApplied
        }
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
