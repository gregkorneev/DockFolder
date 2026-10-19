import AppKit

@MainActor
final class DockIntegrationManager: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if hasVisibleWindows {
            sender.windows.first(where: \.isVisible)?.makeKeyAndOrderFront(nil)
            sender.activate()
            return false
        }
        return true
    }
}
