import AppKit

@MainActor
final class DockIntegrationManager: NSObject, NSApplicationDelegate {
    static var pendingURL: URL?
    static let folderLinkOpened = Notification.Name("DockFolders.folderLinkOpened")

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if hasVisibleWindows {
            sender.windows.first(where: \.isVisible)?.makeKeyAndOrderFront(nil)
            sender.activate()
            return false
        }
        return true
    }

    func applicationDidResignActive(_ notification: Notification) {
        PopupWindowManager.shared.close()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let folderURL = urls.first(where: { DockFolderLink.folderID(from: $0) != nil }) else { return }
        Self.pendingURL = folderURL
        NotificationCenter.default.post(name: Self.folderLinkOpened, object: folderURL)
    }

    static func consumePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }
}
