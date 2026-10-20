import AppKit
import ApplicationServices
import Darwin
import Foundation

/// Event-driven Dock hover detection. Accessibility is used only to identify the
/// Dock item under the pointer; a folder opens through its existing stable UUID.
@MainActor
final class DockHoverMonitor {
    static let shared = DockHoverMonitor()

    private weak var store: FolderStore?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var activationObserver: NSObjectProtocol?
    private var fallbackTimer: Timer?
    private var fallbackInterval: TimeInterval = 0.8
    private var dockProcessID: pid_t = 0
    private var dockElement: AXUIElement?
    private var openTask: Task<Void, Never>?
    private var closeTask: Task<Void, Never>?
    private var candidateFolderID: UUID?
    private var lastPointer = NSPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
    private var lastHitTest = Date.distantPast

    private init() {}

    func configure(store: FolderStore) {
        self.store = store
        if activationObserver == nil {
            activationObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: NSApp,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let store = self.store else { return }
                    self.configure(store: store)
                }
            }
        }
        guard store.settings.hoverSettings.mode.enablesHover, AXIsProcessTrusted() else {
            stopMonitoring()
            return
        }
        guard globalMouseMonitor == nil else { return }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            Task { @MainActor in self?.inspectPointer() }
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            Task { @MainActor in self?.inspectPointer() }
            return event
        }
        if globalMouseMonitor == nil { startAdaptiveFallback() }
    }

    func settingsDidChange(store: FolderStore) {
        configure(store: store)
    }

    func stopMonitoring() {
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        globalMouseMonitor = nil
        localMouseMonitor = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        dockElement = nil
        dockProcessID = 0
        candidateFolderID = nil
        openTask?.cancel()
        openTask = nil
        closeTask?.cancel()
        closeTask = nil
        if PopupWindowManager.shared.isVisible, PopupWindowManager.shared.isHoverPresentation {
            PopupWindowManager.shared.close()
        }
    }

    private func inspectPointer() {
        guard let store, store.settings.hoverSettings.mode.enablesHover, AXIsProcessTrusted() else {
            if store?.settings.hoverSettings.mode.enablesHover == true { stopMonitoring() }
            return
        }
        let point = NSEvent.mouseLocation
        let now = Date()
        // Mouse movement can arrive at very high rates. Skip duplicate/nearby
        // points and cap AX queries at about 30 Hz while the pointer is moving.
        guard hypot(point.x - lastPointer.x, point.y - lastPointer.y) >= 2,
              now.timeIntervalSince(lastHitTest) >= 1.0 / 30.0 else { return }
        lastPointer = point
        lastHitTest = now

        guard let dock = currentDockElement(), let axPoint = accessibilityPoint(from: point) else {
            updateCandidate(nil, at: point, store: store)
            return
        }
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(dock, Float(axPoint.x), Float(axPoint.y), &hit) == .success,
              let hit,
              let folderID = folderID(for: hit, folders: store.folders) else {
            updateCandidate(nil, at: point, store: store)
            return
        }
        updateCandidate(folderID, at: point, store: store)
    }

    private func currentDockElement() -> AXUIElement? {
        if dockProcessID != 0, kill(dockProcessID, 0) == 0, let dockElement { return dockElement }
        guard let process = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            dockProcessID = 0
            dockElement = nil
            return nil
        }
        dockProcessID = process.processIdentifier
        dockElement = AXUIElementCreateApplication(dockProcessID)
        return dockElement
    }

    private func startAdaptiveFallback() {
        guard fallbackTimer == nil else { return }
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: fallbackInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let nearDock = self.pointerIsNearDock(NSEvent.mouseLocation)
                let nextInterval: TimeInterval = nearDock ? 0.07 : 0.8
                if nextInterval != self.fallbackInterval {
                    self.fallbackInterval = nextInterval
                    self.fallbackTimer?.invalidate()
                    self.fallbackTimer = nil
                    self.startAdaptiveFallback()
                } else if nearDock {
                    self.inspectPointer()
                }
            }
        }
    }

    private func pointerIsNearDock(_ point: NSPoint) -> Bool {
        guard let dock = currentDockElement() else { return false }
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(dock, kAXChildrenAttribute as CFString, &children) == .success,
              let list = (children as? [AXUIElement])?.first else { return false }
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(list, kAXPositionAttribute as CFString, &value) == .success,
              let frameValue = value,
              CFGetTypeID(frameValue) == AXValueGetTypeID(),
              let axPoint = accessibilityPoint(from: point) else { return false }
        let positionValue = frameValue as! AXValue
        guard AXValueGetType(positionValue) == .cgPoint else { return false }
        var axOrigin = CGPoint.zero
        guard AXValueGetValue(positionValue, .cgPoint, &axOrigin) else { return false }
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(list, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let sizeValue, CFGetTypeID(sizeValue) == AXValueGetTypeID() else { return false }
        let axSizeValue = sizeValue as! AXValue
        guard AXValueGetType(axSizeValue) == .cgSize else { return false }
        var axSize = CGSize.zero
        guard AXValueGetValue(axSizeValue, .cgSize, &axSize) else { return false }
        let axFrame = CGRect(origin: axOrigin, size: axSize)
        return axFrame.insetBy(dx: -48, dy: -48).contains(axPoint)
    }

    private func accessibilityPoint(from point: NSPoint) -> NSPoint? {
        // AX coordinates use a top-left origin for the primary display. AppKit's
        // global coordinates use bottom-left origins; keeping the primary frame
        // as the transform reference also preserves negative secondary-screen
        // coordinates instead of assuming that the Dock is at screen origin.
        guard let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.main else { return nil }
        return NSPoint(x: point.x - primary.frame.minX, y: primary.frame.maxY - point.y)
    }

    private func folderID(for element: AXUIElement, folders: [DockFolder]) -> UUID? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXURLAttribute as CFString, &value) == .success,
              let url = (value as? URL)?.standardizedFileURL,
              url.path.hasPrefix("/Applications/DockFolders/"),
              url.pathExtension == "app",
              let bundle = Bundle(url: url),
              let identifier = bundle.bundleIdentifier,
              identifier.hasPrefix("com.gregkorneev.DockFolders.launcher."),
              let folderID = UUID(uuidString: String(identifier.dropFirst("com.gregkorneev.DockFolders.launcher.".count))),
              folders.contains(where: { $0.id == folderID && $0.hasDockLauncher }) else { return nil }
        return folderID
    }

    private func updateCandidate(_ folderID: UUID?, at point: NSPoint, store: FolderStore) {
        if let folderID {
            closeTask?.cancel()
            closeTask = nil
            guard candidateFolderID != folderID else { return }
            candidateFolderID = folderID
            openTask?.cancel()
            openTask = Task { @MainActor [weak self, weak store] in
                guard let self, let store else { return }
                try? await Task.sleep(for: .milliseconds(store.settings.hoverSettings.openDelayMilliseconds))
                guard !Task.isCancelled, self.candidateFolderID == folderID else { return }
                PopupWindowManager.shared.present(folderID: folderID, store: store, source: .hover, anchor: point)
                self.openTask = nil
            }
            return
        }

        openTask?.cancel()
        openTask = nil
        let previouslyHovering = candidateFolderID != nil
        candidateFolderID = nil
        guard PopupWindowManager.shared.isHoverPresentation else { return }
        let popupContainsPointer = PopupWindowManager.shared.panelFrame?.insetBy(dx: -12, dy: -12).contains(point) == true
        if popupContainsPointer {
            closeTask?.cancel()
            closeTask = nil
            return
        }
        guard previouslyHovering || closeTask == nil else { return }
        closeTask?.cancel()
        closeTask = Task { @MainActor [weak self, weak store] in
            guard let self, let store else { return }
            try? await Task.sleep(for: .milliseconds(store.settings.hoverSettings.closeDelayMilliseconds))
            guard !Task.isCancelled, self.candidateFolderID == nil,
                  PopupWindowManager.shared.isHoverPresentation else { return }
            let currentPoint = NSEvent.mouseLocation
            if PopupWindowManager.shared.panelFrame?.insetBy(dx: -12, dy: -12).contains(currentPoint) != true {
                PopupWindowManager.shared.close()
            }
            self.closeTask = nil
        }
    }
}
