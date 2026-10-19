import AppKit
import SwiftUI

@MainActor
final class PopupWindowManager: NSObject, NSWindowDelegate {
    static let shared = PopupWindowManager()

    private var panel: NSPanel?
    private var escapeMonitor: Any?
    private var deactivationObserver: NSObjectProtocol?

    var isVisible: Bool { panel?.isVisible == true }

    func present(folderID: UUID, store: FolderStore) {
        guard let folder = store.folders.first(where: { $0.id == folderID }) else { return }
        close()
        let width: CGFloat = 430
        let rows = max(1, Int(ceil(Double(folder.applications.count) / 4)))
        let height = min(max(190, CGFloat(150 + rows * 96)), 560)
        let panel = FolderPopupPanel(
            contentRect: NSRect(origin: .zero, size: NSSize(width: width, height: height)),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = folder.name
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.delegate = self
        panel.standardWindowButton(.closeButton)?.isHidden = true
        let colorScheme: ColorScheme? = switch store.settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
        panel.contentView = NSHostingView(rootView: FolderPopupView(store: store, folderID: folderID).preferredColorScheme(colorScheme))
        panel.setFrameOrigin(origin(for: panel.frame.size))
        self.panel = panel
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            Task { @MainActor in self?.close() }
            return nil
        }
        deactivationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }

        for window in NSApp.windows where window !== panel && window.isVisible {
            window.orderOut(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }
        if let deactivationObserver {
            NotificationCenter.default.removeObserver(deactivationObserver)
            self.deactivationObserver = nil
        }
        guard let panel else { return }
        self.panel = nil
        panel.delegate = nil
        panel.orderOut(nil)
        panel.close()
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }

    private func origin(for size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.frame
        let visible = screen.visibleFrame
        let margin: CGFloat = 12

        if visible.minX > frame.minX + 1 {
            return NSPoint(x: visible.minX + margin, y: min(max(mouse.y - size.height / 2, visible.minY + margin), visible.maxY - size.height - margin))
        }
        if visible.maxX < frame.maxX - 1 {
            return NSPoint(x: visible.maxX - size.width - margin, y: min(max(mouse.y - size.height / 2, visible.minY + margin), visible.maxY - size.height - margin))
        }
        return NSPoint(x: min(max(mouse.x - size.width / 2, visible.minX + margin), visible.maxX - size.width - margin), y: visible.minY + margin)
    }
}

@MainActor
private final class FolderPopupPanel: NSPanel {
    override func cancelOperation(_ sender: Any?) {
        PopupWindowManager.shared.close()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            PopupWindowManager.shared.close()
            return
        }
        super.keyDown(with: event)
    }
}
