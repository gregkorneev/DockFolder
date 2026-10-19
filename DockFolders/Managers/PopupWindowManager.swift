import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class PopupWindowManager: NSObject, NSWindowDelegate {
    static let shared = PopupWindowManager()

    private var panel: NSPanel?
    private var dockAnchor = NSPoint.zero
    private var escapeMonitor: Any?
    private var deactivationObserver: NSObjectProtocol?

    var isVisible: Bool { panel?.isVisible == true }

    func present(folderID: UUID, store: FolderStore) {
        guard let folder = store.folders.first(where: { $0.id == folderID }) else { return }
        close(animated: false)
        let anchor = NSEvent.mouseLocation
        dockAnchor = anchor
        let preset = folder.layoutPreset
        let columns = preset.gridColumns(for: folder.applications.count)
        let rows = max(1, Int(ceil(Double(folder.applications.count) / Double(columns))))
        let width: CGFloat = preset.isSingleColumn ? 170 : (preset.isSingleRow ? 370 : min(900, max(250, CGFloat(columns) * 84 + 36)))
        let rowHeight = preset.showsAppLabels ? 88 : 68
        let height: CGFloat = preset.isSingleRow ? 160 : min(max(162, CGFloat(74 + min(rows, 5) * rowHeight)), 500)
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
        panel.hidesOnDeactivate = false
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
        let content = NSHostingView(rootView: FolderPopupView(store: store, folderID: folderID).preferredColorScheme(colorScheme))
        content.frame = NSRect(origin: .zero, size: panel.contentView?.bounds.size ?? NSSize(width: width, height: height))
        let animatedContent = NSView(frame: content.frame)
        animatedContent.wantsLayer = true
        animatedContent.autoresizingMask = [.width, .height]
        content.autoresizingMask = [.width, .height]
        animatedContent.addSubview(content)
        panel.contentView = animatedContent
        let finalFrame = NSRect(origin: origin(for: panel.frame.size, anchor: anchor), size: panel.frame.size)
        panel.setFrameOrigin(finalFrame.origin)
        let shouldAnimate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if shouldAnimate {
            setCollapsedTransform(on: animatedContent, in: panel, anchor: anchor)
            panel.alphaValue = 0
        }
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
        if shouldAnimate {
            animateOpen(panel: panel, content: animatedContent)
        }
    }

    func close(animated: Bool = true) {
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
        guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
              let content = panel.contentView, let layer = content.layer else {
            panel.orderOut(nil)
            panel.close()
            return
        }

        panel.ignoresMouseEvents = true
        let startingTransform = layer.presentation()?.transform ?? layer.transform
        let collapsedTransform = DockPopupAnimation.collapsedTransform(
            scale: 0.035,
            anchor: anchorInContent(dockAnchor, panel: panel, content: content),
            center: NSPoint(x: content.bounds.midX, y: content.bounds.midY)
        )
        addTransformAnimation(to: layer, from: startingTransform, to: collapsedTransform, easing: .easeIn)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DockPopupAnimation.duration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(DockPopupAnimation.duration))
            panel.orderOut(nil)
            panel.close()
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }

    private func origin(for size: NSSize, anchor: NSPoint) -> NSPoint {
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

    private func setCollapsedTransform(on content: NSView, in panel: NSWindow, anchor: NSPoint) {
        guard let layer = content.layer else { return }
        let anchorPoint = anchorInContent(anchor, panel: panel, content: content)
        layer.transform = DockPopupAnimation.collapsedTransform(
            scale: 0.035,
            anchor: anchorPoint,
            center: NSPoint(x: content.bounds.midX, y: content.bounds.midY)
        )
    }

    private func animateOpen(panel: NSWindow, content: NSView) {
        guard let layer = content.layer else {
            panel.alphaValue = 1
            return
        }
        let collapsed = layer.transform
        layer.transform = CATransform3DIdentity
        addTransformAnimation(to: layer, from: collapsed, to: CATransform3DIdentity, easing: .easeOut)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DockPopupAnimation.duration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    private func addTransformAnimation(
        to layer: CALayer,
        from start: CATransform3D,
        to end: CATransform3D,
        easing: CAMediaTimingFunctionName
    ) {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(caTransform3D: start)
        animation.toValue = NSValue(caTransform3D: end)
        animation.duration = DockPopupAnimation.duration
        animation.timingFunction = CAMediaTimingFunction(name: easing)
        layer.add(animation, forKey: "DockFolders.popup.transform")
    }

    private func anchorInContent(_ screenPoint: NSPoint, panel: NSWindow, content: NSView) -> NSPoint {
        content.convert(panel.convertPoint(fromScreen: screenPoint), from: nil)
    }
}

enum DockPopupAnimation {
    static let duration: TimeInterval = 0.24

    static func collapsedTransform(scale: CGFloat, anchor: NSPoint, center: NSPoint) -> CATransform3D {
        var transform = CATransform3DIdentity
        transform.m11 = scale
        transform.m22 = scale
        // A layer transform is applied around its anchorPoint (the center by default),
        // so translation moves that center directly to the Dock icon's local point.
        transform.m41 = anchor.x - center.x
        transform.m42 = anchor.y - center.y
        return transform
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
