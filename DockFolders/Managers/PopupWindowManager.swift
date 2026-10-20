import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class PopupWindowManager: NSObject, NSWindowDelegate {
    static let shared = PopupWindowManager()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var dockAnchor = NSPoint.zero
    private var presentedFolderID: UUID?
    private(set) var isHoverPresentation = false
    var panelFrame: NSRect? { panel?.frame }
    private var escapeMonitor: Any?
    private var deactivationObserver: NSObjectProtocol?
    private var isLayoutOptionsPresented = false
    var onOpenMainWindow: (() -> Void)?

    var isVisible: Bool { panel?.isVisible == true }

    func layoutOptionsDidChange(isPresented: Bool) {
        isLayoutOptionsPresented = isPresented
    }

    func openMainWindow() {
        onOpenMainWindow?()
    }

    func shouldDismissHoverPopup(at point: NSPoint) -> Bool {
        guard isHoverPresentation, !isLayoutOptionsPresented else { return false }
        return panel?.frame.insetBy(dx: -12, dy: -12).contains(point) != true
    }

    func refreshLayout(folderID: UUID, store: FolderStore, animated: Bool = true) {
        guard let panel, let hostingView, presentedFolderID == folderID,
              let folder = store.folders.first(where: { $0.id == folderID }) else { return }
        let layout = popupLayout(for: folder, anchor: dockAnchor)
        let colorScheme: ColorScheme? = switch store.settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
        hostingView.rootView = AnyView(FolderPopupView(store: store, folderID: folderID, columns: layout.columns, iconSize: layout.iconSize).preferredColorScheme(colorScheme))
        panel.setFrame(NSRect(origin: origin(for: layout.size, anchor: dockAnchor), size: layout.size), display: true, animate: animated)
    }

    func present(folderID: UUID, store: FolderStore, source: Source = .click, anchor: NSPoint? = nil) {
        guard let folder = store.folders.first(where: { $0.id == folderID }) else { return }
        isLayoutOptionsPresented = false
        let anchor = anchor ?? NSEvent.mouseLocation
        if source == .hover, let panel, let hostingView {
            presentedFolderID = folderID
            dockAnchor = anchor
            panel.title = folder.name
            let colorScheme: ColorScheme? = switch store.settings.appearance {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
            let layout = popupLayout(for: folder, anchor: anchor)
            hostingView.rootView = AnyView(FolderPopupView(store: store, folderID: folderID, columns: layout.columns, iconSize: layout.iconSize).preferredColorScheme(colorScheme))
            let size = layout.size
            let frame = NSRect(origin: origin(for: size, anchor: anchor), size: size)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                panel.animator().setFrame(frame, display: true)
            }
            isHoverPresentation = true
            return
        }
        close(animated: false)
        presentedFolderID = folderID
        dockAnchor = anchor
        isHoverPresentation = source == .hover
        let layout = popupLayout(for: folder, anchor: anchor)
        let size = layout.size
        let width = size.width
        let height = size.height
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
        let content = NSHostingView(rootView: AnyView(FolderPopupView(store: store, folderID: folderID, columns: layout.columns, iconSize: layout.iconSize).preferredColorScheme(colorScheme)))
        hostingView = content
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
        isLayoutOptionsPresented = false
        presentedFolderID = nil
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
        hostingView = nil
        isHoverPresentation = false
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
        if !isHoverPresentation && !isLayoutOptionsPresented { close() }
    }

    enum Source { case click, hover }

    private func popupLayout(for folder: DockFolder, anchor: NSPoint) -> DockPopupLayout.Result {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor) }) ?? NSScreen.main
        let available = NSSize(width: (screen?.visibleFrame.width ?? 1_000) - 24, height: (screen?.visibleFrame.height ?? 700) - 24)
        return DockPopupLayout.calculate(
            applicationCount: folder.applications.count,
            preset: folder.layoutPreset,
            availableSize: available,
            preferredIconSize: CGFloat(folder.iconSize),
            preferredColumns: folder.gridColumns
        )
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

enum DockPopupLayout {
    struct Result: Equatable {
        var columns: Int
        var iconSize: CGFloat
        var size: NSSize
    }

    static func calculate(applicationCount: Int, preset: FolderLayoutPreset, availableSize: NSSize, preferredIconSize: CGFloat = 56, preferredColumns: Int = 0) -> Result {
        let count = max(1, applicationCount)
        let labels = preset.showsAppLabels
        let outerWidth: CGFloat = 28
        let outerHeight: CGFloat = 84
        let minimumWidth: CGFloat = 360
        let columnSpacing: CGFloat = 12
        let rowSpacing: CGFloat = 12
        let availableWidth = max(1, availableSize.width)
        let availableHeight = max(72, availableSize.height)
        if let requestedRows = preset.rows {
            let requestedIconSize = min(max(preferredIconSize, 24), 128)
            let widthFitIconSize = (availableWidth - outerWidth - CGFloat(preset.columns - 1) * columnSpacing) / CGFloat(preset.columns) - 16
            let maximumIconSize = max(1, min(requestedIconSize, widthFitIconSize))
            let iconSize: CGFloat
            if customGridHeight(rows: requestedRows, iconSize: maximumIconSize, showsLabels: labels, rowSpacing: rowSpacing, outerHeight: outerHeight) <= availableHeight {
                iconSize = maximumIconSize
            } else {
                var lowerBound: CGFloat = 1
                var upperBound = maximumIconSize
                for _ in 0..<20 {
                    let candidate = (lowerBound + upperBound) / 2
                    let candidateHeight = customGridHeight(rows: requestedRows, iconSize: candidate, showsLabels: labels, rowSpacing: rowSpacing, outerHeight: outerHeight)
                    if candidateHeight <= availableHeight {
                        lowerBound = candidate
                    } else {
                        upperBound = candidate
                    }
                }
                iconSize = lowerBound
            }
            let cellWidth = iconSize + 16
            let contentWidth = outerWidth + CGFloat(preset.columns) * cellWidth + CGFloat(preset.columns - 1) * columnSpacing
            let contentHeight = customGridHeight(rows: requestedRows, iconSize: iconSize, showsLabels: labels, rowSpacing: rowSpacing, outerHeight: outerHeight)
            return Result(
                columns: preset.columns,
                iconSize: iconSize,
                size: NSSize(width: min(availableWidth, max(minimumWidth, contentWidth)), height: min(availableHeight, contentHeight))
            )
        }
        let targetColumns = preferredColumns > 0
            ? min(count, preferredColumns)
            : (preset.isSingleColumn ? 1 : (preset.isSingleRow ? count : preset.columns))
        let startIconSize = min(max(preferredIconSize, 24), 128)

        for iconSize in stride(from: startIconSize, through: CGFloat(24), by: -2) {
            let cellWidth = iconSize + 16
            let maxColumns = max(1, min(count, Int((availableWidth - outerWidth + columnSpacing) / (cellWidth + columnSpacing))))
            let rowHeight = iconSize + (labels ? 37 : 0)
            let maxRows = max(1, Int((availableHeight - outerHeight + rowSpacing) / (rowHeight + rowSpacing)))
            let minimumColumns = max(1, Int(ceil(Double(count) / Double(maxRows))))
            let columns = min(maxColumns, max(min(max(targetColumns, 1), maxColumns), minimumColumns))
            let rows = Int(ceil(Double(count) / Double(columns)))
            let width = min(availableWidth, max(minimumWidth, outerWidth + CGFloat(columns) * cellWidth + CGFloat(max(0, columns - 1)) * columnSpacing))
            let height = outerHeight + CGFloat(rows) * rowHeight + CGFloat(max(0, rows - 1)) * rowSpacing
            if width <= availableWidth, height <= availableHeight {
                return Result(columns: columns, iconSize: iconSize, size: NSSize(width: width, height: height))
            }
        }

        let columns = max(1, min(count, Int((availableWidth - outerWidth + columnSpacing) / (40 + columnSpacing))))
        return Result(columns: columns, iconSize: 24, size: NSSize(width: availableWidth, height: availableHeight))
    }

    static func labelFontSize(for iconSize: CGFloat) -> CGFloat {
        iconSize >= 24 ? 11 : max(5, 11 * iconSize / 24)
    }

    static func labelHeight(for iconSize: CGFloat) -> CGFloat {
        iconSize >= 24 ? 27 : max(10, labelFontSize(for: iconSize) * 2.5)
    }

    static func labelSpacing(for iconSize: CGFloat) -> CGFloat {
        iconSize >= 24 ? 5 : iconSize * 0.2
    }

    private static func customGridHeight(rows: Int, iconSize: CGFloat, showsLabels: Bool, rowSpacing: CGFloat, outerHeight: CGFloat) -> CGFloat {
        let labelHeight = showsLabels ? labelHeight(for: iconSize) : 0
        let labelSpacing = showsLabels ? labelSpacing(for: iconSize) : 0
        return outerHeight + CGFloat(rows) * (iconSize + labelHeight + labelSpacing) + CGFloat(rows - 1) * rowSpacing
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
