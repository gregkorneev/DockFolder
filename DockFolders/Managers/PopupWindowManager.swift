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
        let columns = min(max(1, store.settings.gridColumns > 0 ? store.settings.gridColumns : 4), 4)
        let rows = max(1, Int(ceil(Double(folder.applications.count) / Double(columns))))
        let width = max(250, CGFloat(columns) * 84 + 36)
        let height = min(max(162, CGFloat(74 + rows * 88)), 500)
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
        let anchor = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor) }) ?? NSScreen.main else {
            return NSPoint(x: anchor.x - size.width / 2, y: anchor.y + 44)
        }
        return DockPopupPositioning.origin(
            for: size,
            anchor: anchor,
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame
        )
    }
}

enum DockPopupPositioning {
    private enum Edge {
        case bottom, left, right
    }

    static func origin(for size: NSSize, anchor: NSPoint, screenFrame: NSRect, visibleFrame: NSRect) -> NSPoint {
        let margin: CGFloat = 12
        let dockInset = CGFloat(1)
        let insets: (left: CGFloat, right: CGFloat, bottom: CGFloat) = (
            visibleFrame.minX - screenFrame.minX,
            screenFrame.maxX - visibleFrame.maxX,
            visibleFrame.minY - screenFrame.minY
        )
        let edge: Edge
        let dockEdgeIsReserved: Bool
        if insets.left > dockInset {
            edge = .left
            dockEdgeIsReserved = true
        } else if insets.right > dockInset {
            edge = .right
            dockEdgeIsReserved = true
        } else if insets.bottom > dockInset {
            edge = .bottom
            dockEdgeIsReserved = true
        } else {
            let distances: [(Edge, CGFloat)] = [
                (.left, anchor.x - screenFrame.minX),
                (.right, screenFrame.maxX - anchor.x),
                (.bottom, anchor.y - screenFrame.minY)
            ]
            let nearest = distances.min(by: { $0.1 < $1.1 }) ?? (.bottom, 0)
            edge = nearest.1 < 140 ? nearest.0 : .bottom
            dockEdgeIsReserved = false
        }

        let x: CGFloat
        let y: CGFloat
        switch edge {
        case .bottom:
            x = clamp(anchor.x - size.width / 2, screenFrame.minX + margin, screenFrame.maxX - size.width - margin)
            y = dockEdgeIsReserved ? visibleFrame.minY + margin : anchor.y + 44
        case .left:
            x = dockEdgeIsReserved ? visibleFrame.minX + margin : anchor.x + 44
            y = clamp(anchor.y - size.height / 2, visibleFrame.minY + margin, visibleFrame.maxY - size.height - margin)
        case .right:
            x = dockEdgeIsReserved ? visibleFrame.maxX - size.width - margin : anchor.x - size.width - 44
            y = clamp(anchor.y - size.height / 2, visibleFrame.minY + margin, visibleFrame.maxY - size.height - margin)
        }

        return NSPoint(
            x: clamp(x, screenFrame.minX + margin, screenFrame.maxX - size.width - margin),
            y: clamp(y, visibleFrame.minY + margin, visibleFrame.maxY - size.height - margin)
        )
    }

    private static func clamp(_ value: CGFloat, _ minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
        min(max(value, minimum), maximum)
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
