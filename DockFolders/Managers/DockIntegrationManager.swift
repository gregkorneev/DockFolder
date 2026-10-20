import AppKit
import SwiftUI

@MainActor
final class DockIntegrationManager: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var folderStore = FolderStore()
    private(set) var mainWindow: NSWindow?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        PopupWindowManager.shared.onOpenMainWindow = { [weak self] in
            self?.showMainWindow()
        }
        let service = FolderLauncherService()
        for folder in folderStore.folders where folder.hasDockLauncher {
            do { try service.migrateLegacyLauncherIfNeeded(for: folder) }
            catch { folderStore.errorMessage = error.localizedDescription }
        }
        DockHoverMonitor.shared.configure(store: folderStore)
        GlobalShortcutService.shared.onShortcut = { [weak self] in
            guard let self, let firstFolderID = folderStore.folders.first?.id else { return }
            if PopupWindowManager.shared.isVisible { PopupWindowManager.shared.close() }
            else { PopupWindowManager.shared.present(folderID: firstFolderID, store: folderStore) }
        }
        if folderStore.settings.globalShortcutEnabled {
            do { try GlobalShortcutService.shared.enable() }
            catch { folderStore.errorMessage = error.localizedDescription }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool == true {
            showMainWindow()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showMainWindow()
        return false
    }

    func applicationDidResignActive(_ notification: Notification) {
        PopupWindowManager.shared.close()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let id = urls.compactMap({ DockFolderLink.folderID(from: $0) }).first,
              folderStore.folders.contains(where: { $0.id == id }) else {
            if folderStore.errorMessage == nil {
                folderStore.errorMessage = NSLocalizedString("This DockFolders link is invalid or its folder no longer exists.", comment: "")
            }
            showMainWindow()
            return
        }
        PopupWindowManager.shared.present(folderID: id, store: folderStore)
    }

    private func showMainWindow() {
        PopupWindowManager.shared.close(animated: false)
        NSApp.setActivationPolicy(.regular)
        if mainWindow == nil {
            // Keep window creation explicit: URL launches must never show the manager first.
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "DockFolders"
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.contentView = NSHostingView(rootView: ContentView()
                .environment(folderStore)
                .frame(minWidth: 760, minHeight: 520))
            window.contentMinSize = NSSize(width: 760, height: 520)
            window.center()
            mainWindow = window
        }
        mainWindow?.deminiaturize(nil)
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === mainWindow else { return }
        NSApp.setActivationPolicy(.accessory)
    }
}
