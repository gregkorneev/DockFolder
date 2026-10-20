import AppKit
import Foundation
import XCTest
@testable import DockFolders

@MainActor
final class DockFoldersTests: XCTestCase {
    func testFolderLinkOpensPopupWithoutCreatingMainWindow() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            PopupWindowManager.shared.close(animated: false)
            try? FileManager.default.removeItem(at: directory)
        }
        let delegate = DockIntegrationManager()
        delegate.folderStore = FolderStore(persistence: FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json")))
        delegate.folderStore.createFolder(named: "Route test")
        let folder = try XCTUnwrap(delegate.folderStore.folders.first)

        delegate.applicationDidFinishLaunching(Notification(
            name: NSApplication.didFinishLaunchingNotification,
            object: NSApp,
            userInfo: [NSApplication.launchIsDefaultUserInfoKey: false]
        ))
        XCTAssertNil(delegate.mainWindow)
        delegate.application(NSApp, open: [DockFolderLink.url(for: folder.id)])

        XCTAssertNil(delegate.mainWindow)
        XCTAssertTrue(PopupWindowManager.shared.isVisible)
        XCTAssertNil(delegate.folderStore.errorMessage)
    }

    func testExistingErrorDoesNotRedirectValidFolderLinkToMainWindow() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            PopupWindowManager.shared.close(animated: false)
            try? FileManager.default.removeItem(at: directory)
        }
        let delegate = DockIntegrationManager()
        delegate.folderStore = FolderStore(persistence: FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json")))
        delegate.folderStore.createFolder(named: "Route test")
        let folder = try XCTUnwrap(delegate.folderStore.folders.first)
        delegate.folderStore.errorMessage = "An earlier error"

        delegate.application(NSApp, open: [DockFolderLink.url(for: folder.id)])

        XCTAssertNil(delegate.mainWindow)
        XCTAssertTrue(PopupWindowManager.shared.isVisible)
        XCTAssertEqual(delegate.folderStore.errorMessage, "An earlier error")
    }

    func testFailedFolderDeletionPreservesFolderInMemory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let backup = root.appendingPathExtension("backup")
        defer {
            try? FileManager.default.removeItem(at: root)
            try? FileManager.default.removeItem(at: backup)
        }
        let store = FolderStore(persistence: FolderPersistenceService(fileURL: root.appendingPathComponent("folders.json")))
        store.createFolder(named: "Keep me")
        let folder = try XCTUnwrap(store.folders.first)
        try FileManager.default.moveItem(at: root, to: backup)
        try Data("not a directory".utf8).write(to: root)

        XCTAssertFalse(store.deleteFolder(id: folder.id))
        XCTAssertEqual(store.folders.first?.id, folder.id)
        XCTAssertNotNil(store.errorMessage)
    }

    func testOrdinaryOpenAndReopenReuseMainWindowEvenWithPopupVisible() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let delegate = DockIntegrationManager()
        delegate.showsWelcomeOnFirstLaunch = false
        let originalActivationPolicy = NSApp.activationPolicy()
        defer {
            delegate.mainWindow?.close()
            NSApp.setActivationPolicy(originalActivationPolicy)
            PopupWindowManager.shared.close(animated: false)
            try? FileManager.default.removeItem(at: directory)
        }
        delegate.folderStore = FolderStore(persistence: FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json")))
        delegate.folderStore.createFolder(named: "Route test")
        let folder = try XCTUnwrap(delegate.folderStore.folders.first)
        delegate.applicationDidFinishLaunching(Notification(
            name: NSApplication.didFinishLaunchingNotification,
            object: NSApp,
            userInfo: [NSApplication.launchIsDefaultUserInfoKey: true]
        ))
        let window = try XCTUnwrap(delegate.mainWindow)
        XCTAssertTrue(window.isVisible)
        XCTAssertEqual(NSApp.activationPolicy(), .regular)

        delegate.application(NSApp, open: [DockFolderLink.url(for: folder.id)])
        XCTAssertFalse(window.isVisible)
        XCTAssertEqual(NSApp.activationPolicy(), .accessory)
        XCTAssertFalse(delegate.applicationShouldHandleReopen(NSApp, hasVisibleWindows: true))
        XCTAssertTrue(delegate.mainWindow === window)
        XCTAssertTrue(window.isVisible)
        XCTAssertFalse(PopupWindowManager.shared.isVisible)

        window.close()
        XCTAssertEqual(NSApp.activationPolicy(), .accessory)
        XCTAssertFalse(delegate.applicationShouldHandleReopen(NSApp, hasVisibleWindows: false))
        XCTAssertTrue(delegate.mainWindow === window)
        XCTAssertTrue(window.isVisible)
        XCTAssertEqual(NSApp.activationPolicy(), .regular)
    }

    func testFolderManagerActionOpensMainWindowAndClosingHidesDockIcon() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let delegate = DockIntegrationManager()
        let originalActivationPolicy = NSApp.activationPolicy()
        defer {
            delegate.mainWindow?.close()
            NSApp.setActivationPolicy(originalActivationPolicy)
            PopupWindowManager.shared.onOpenMainWindow = nil
            try? FileManager.default.removeItem(at: directory)
        }
        delegate.folderStore = FolderStore(persistence: FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json")))
        delegate.applicationWillFinishLaunching(Notification(name: NSApplication.willFinishLaunchingNotification, object: NSApp))

        PopupWindowManager.shared.openMainWindow()

        let window = try XCTUnwrap(delegate.mainWindow)
        XCTAssertTrue(window.isVisible)
        XCTAssertEqual(NSApp.activationPolicy(), .regular)
        window.close()
        XCTAssertEqual(NSApp.activationPolicy(), .accessory)
    }

    func testWelcomeGuideOpensFromManagerAsOneSheet() throws {
        let delegate = DockIntegrationManager()
        let originalActivationPolicy = NSApp.activationPolicy()
        defer {
            if let welcomeWindow = delegate.welcomeWindow {
                delegate.mainWindow?.endSheet(welcomeWindow)
            }
            delegate.mainWindow?.close()
            NSApp.setActivationPolicy(originalActivationPolicy)
        }

        delegate.showWelcome()
        let firstWindow = try XCTUnwrap(delegate.welcomeWindow)
        XCTAssertTrue(delegate.mainWindow?.attachedSheet === firstWindow)
        delegate.showWelcome()
        XCTAssertTrue(delegate.welcomeWindow === firstWindow)
    }

    func testMissingFolderLinkShowsErrorInMainWindow() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let delegate = DockIntegrationManager()
        let originalActivationPolicy = NSApp.activationPolicy()
        defer {
            delegate.mainWindow?.close()
            NSApp.setActivationPolicy(originalActivationPolicy)
            try? FileManager.default.removeItem(at: directory)
        }
        delegate.folderStore = FolderStore(persistence: FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json")))

        delegate.application(NSApp, open: [DockFolderLink.url(for: UUID())])

        XCTAssertNotNil(delegate.folderStore.errorMessage)
        XCTAssertEqual(delegate.mainWindow?.isVisible, true)
    }

    func testInvalidLinkDoesNotReplaceDataLoadError() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let delegate = DockIntegrationManager()
        let originalActivationPolicy = NSApp.activationPolicy()
        defer {
            delegate.mainWindow?.close()
            NSApp.setActivationPolicy(originalActivationPolicy)
            try? FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("invalid JSON".utf8).write(to: directory.appendingPathComponent("folders.json"))
        delegate.folderStore = FolderStore(persistence: FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json")))
        let loadError = delegate.folderStore.errorMessage

        delegate.application(NSApp, open: [DockFolderLink.url(for: UUID())])

        XCTAssertNotNil(loadError)
        XCTAssertEqual(delegate.folderStore.errorMessage, loadError)
        XCTAssertEqual(delegate.mainWindow?.isVisible, true)
    }

    func testSystemSymbolCatalogContainsSF7NamesAndAppleDeviceSymbols() throws {
        let symbols = try SystemSymbolCatalog.load()

        XCTAssertEqual(symbols.count, 7_752)
        XCTAssertTrue(symbols.contains("iphone"))
        XCTAssertTrue(symbols.contains("visionpro"))
        XCTAssertEqual(symbols, symbols.sorted())
        XCTAssertTrue(symbols.allSatisfy { NSImage(systemSymbolName: $0, accessibilityDescription: nil) != nil })
    }

    func testSymbolCatalogAssignsEverySymbolToAVisibleCategory() throws {
        let symbols = try SystemSymbolCatalog.load()
        XCTAssertTrue(symbols.allSatisfy { SystemSymbolCatalog.category(for: $0) != .all })
        XCTAssertEqual(SystemSymbolCatalog.category(for: "iphone"), .devices)
        XCTAssertEqual(SystemSymbolCatalog.category(for: "figure.walk"), .people)
        XCTAssertEqual(SystemSymbolCatalog.category(for: "0.circle"), .numbers)
    }

    func testNewFoldersUseStandardLayout() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FolderStore(persistence: FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json")))
        store.createFolder(named: "New")
        XCTAssertEqual(try XCTUnwrap(store.folders.first).layoutPreset.id, FolderLayoutPreset.defaultID)
    }

    func testFolderPersistenceRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json"))
        let folder = DockFolder(name: "Work")

        try service.save(FolderDocument(folders: [folder]))

        XCTAssertEqual(try service.load().folders, [folder])
    }

    func testVersionOneFolderDataLoadsWithDefaultAppearanceAndSettings() throws {
        let data = Data("{\"version\":1,\"folders\":[{\"id\":\"8C1E54B7-4E13-4DF0-B9B7-E837C0ABCC0C\",\"name\":\"Old\",\"applications\":[]}]}".utf8)
        let document = try JSONDecoder().decode(FolderDocument.self, from: data)
        XCTAssertEqual(document.folders.first?.iconName, "folder.fill")
        XCTAssertEqual(document.folders.first?.colorHex, "#0A84FF")
        XCTAssertEqual(document.settings, AppSettings())
    }

    func testHoverSettingsDefaultToClickAndClampDelays() throws {
        let legacy = try JSONDecoder().decode(AppSettings.self, from: Data("{}".utf8))
        XCTAssertEqual(legacy.hoverSettings.mode, .click)
        XCTAssertEqual(legacy.hoverSettings.openDelayMilliseconds, 180)
        XCTAssertEqual(legacy.hoverSettings.closeDelayMilliseconds, 250)

        let settings = HoverSettings(mode: .both, openDelayMilliseconds: 20, closeDelayMilliseconds: 2_000)
        XCTAssertEqual(settings.openDelayMilliseconds, 80)
        XCTAssertEqual(settings.closeDelayMilliseconds, 1_000)
    }

    func testFolderLayoutAppearanceSettingsAreIndependentAndPersisted() throws {
        let folder = DockFolder(name: "Photo", iconSize: 92, gridColumns: 5, glassTransparency: 0.8)
        let otherFolder = DockFolder(name: "Work")
        let decoded = try JSONDecoder().decode(DockFolder.self, from: JSONEncoder().encode(folder))

        XCTAssertEqual(decoded.iconSize, 92)
        XCTAssertEqual(decoded.gridColumns, 5)
        XCTAssertEqual(decoded.glassTransparency, 0.8)
        XCTAssertEqual(otherFolder.iconSize, 68)
        XCTAssertEqual(otherFolder.gridColumns, 0)
        XCTAssertEqual(otherFolder.glassTransparency, 0.55)
        XCTAssertEqual(DockFolder(name: "Clamp", iconSize: 200, gridColumns: 20, glassTransparency: -1).iconSize, 128)
        XCTAssertEqual(DockFolder(name: "Clamp", iconSize: 200, gridColumns: 20, glassTransparency: -1).gridColumns, 12)
        XCTAssertEqual(DockFolder(name: "Clamp", iconSize: 200, gridColumns: 20, glassTransparency: -1).glassTransparency, 0)
    }

    func testDockFolderLinksValidateSchemePathAndIdentifier() throws {
        let id = UUID()
        let url = DockFolderLink.url(for: id)
        XCTAssertEqual(DockFolderLink.folderID(from: url), id)
        XCTAssertNil(DockFolderLink.folderID(from: URL(string: "https://folder/\(id)")!))
        XCTAssertNil(DockFolderLink.folderID(from: URL(string: "dockfolders://folder/not-a-uuid")!))
        XCTAssertNil(DockFolderLink.folderID(from: URL(string: "dockfolders://folder/\(id)/extra")!))
    }

    func testPopupPositioningAnchorsToBottomLeftAndRightDocks() {
        let screen = NSRect(x: 0, y: 0, width: 1_000, height: 800)
        let popup = NSSize(width: 360, height: 220)

        let bottom = DockPopupPositioning.origin(
            for: popup,
            anchor: NSPoint(x: 500, y: 30),
            screenFrame: screen,
            visibleFrame: NSRect(x: 0, y: 60, width: 1_000, height: 740)
        )
        XCTAssertEqual(bottom, NSPoint(x: 320, y: 72))

        let left = DockPopupPositioning.origin(
            for: popup,
            anchor: NSPoint(x: 30, y: 400),
            screenFrame: screen,
            visibleFrame: NSRect(x: 70, y: 0, width: 930, height: 800)
        )
        XCTAssertEqual(left, NSPoint(x: 82, y: 290))

        let right = DockPopupPositioning.origin(
            for: popup,
            anchor: NSPoint(x: 970, y: 400),
            screenFrame: screen,
            visibleFrame: NSRect(x: 0, y: 0, width: 930, height: 800)
        )
        XCTAssertEqual(right, NSPoint(x: 558, y: 290))
    }

    func testFolderLayoutPresetsOnlyFitWhenTheyHaveEnoughGridCells() {
        let oneByOne = FolderLayoutPreset.dynamicGrid(side: 1, showsAppLabels: true)
        let twoByTwo = FolderLayoutPreset.dynamicGrid(side: 2, showsAppLabels: true)
        let threeByThree = FolderLayoutPreset.defaults[1]
        let fourByFour = FolderLayoutPreset.defaults[0]

        XCTAssertTrue(oneByOne.fits(1))
        XCTAssertFalse(oneByOne.fits(2))
        XCTAssertTrue(twoByTwo.fits(4))
        XCTAssertFalse(twoByTwo.fits(5))
        XCTAssertFalse(threeByThree.fits(10))
        XCTAssertTrue(fourByFour.fits(10))
        XCTAssertEqual(fourByFour.fitting(17).columns, 5)
    }

    func testAvailableFolderLayoutsShowOnlyGridsWithEnoughCellsAndScalePastTen() {
        func squareColumns(for count: Int) -> [Int] {
            FolderLayoutPreset.availableChoices(
                applicationCount: count,
                presets: FolderLayoutPreset.defaults,
                showsAppLabels: true
            )
            .filter { !$0.isSingleRow && !$0.isSingleColumn }
            .map(\.columns)
        }

        XCTAssertEqual(squareColumns(for: 1), Array(1...10))
        XCTAssertEqual(squareColumns(for: 5), Array(3...10))
        XCTAssertEqual(squareColumns(for: 11), Array(4...10))
        XCTAssertEqual(squareColumns(for: 101), Array(11...13))

        let fiveApps = FolderLayoutPreset.availableChoices(
            applicationCount: 5,
            presets: FolderLayoutPreset.defaults,
            showsAppLabels: true
        )
        XCTAssertTrue(fiveApps.contains(where: \.isSingleRow))
        XCTAssertTrue(fiveApps.contains(where: \.isSingleColumn))
    }

    func testPopupLayoutSizesSingleColumnToItsContentsAndAvoidsScrollCapacityCaps() {
        let preset = FolderLayoutPreset.defaults.first { $0.isSingleColumn } ??
            FolderLayoutPreset(id: "single-column", name: "Single column", columns: FolderLayoutPreset.columnColumns)
        let twoApps = DockPopupLayout.calculate(applicationCount: 2, preset: preset, availableSize: NSSize(width: 1_200, height: 800))
        XCTAssertEqual(twoApps.columns, 1)
        XCTAssertEqual(twoApps.iconSize, 56)
        XCTAssertGreaterThan(twoApps.size.height, 200)
        XCTAssertGreaterThanOrEqual(twoApps.size.width, 360)

        let manyApps = DockPopupLayout.calculate(
            applicationCount: 24,
            preset: preset,
            availableSize: NSSize(width: 900, height: 600)
        )
        XCTAssertGreaterThan(manyApps.columns, 1)
        XCTAssertLessThanOrEqual(manyApps.size.width, 900)
        XCTAssertLessThanOrEqual(manyApps.size.height, 600)
        XCTAssertGreaterThanOrEqual(manyApps.columns * Int(ceil(Double(24) / Double(manyApps.columns))), 24)
    }

    func testPopupLayoutRespectsPerFolderIconSizeAndGridColumns() {
        let result = DockPopupLayout.calculate(
            applicationCount: 6,
            preset: FolderLayoutPreset.defaults[0],
            availableSize: NSSize(width: 1_200, height: 800),
            preferredIconSize: 92,
            preferredColumns: 2
        )

        XCTAssertEqual(result.iconSize, 92)
        XCTAssertEqual(result.columns, 2)
    }

    func testGridSpacingShrinksWithIconSize() {
        XCTAssertEqual(DockPopupLayout.spacing(for: 68), 12, accuracy: 0.001)
        XCTAssertEqual(DockPopupLayout.spacing(for: 34), 6, accuracy: 0.001)
        XCTAssertLessThan(DockPopupLayout.spacing(for: 24), DockPopupLayout.spacing(for: 34))
        XCTAssertEqual(DockPopupLayout.spacing(for: 10), 4, accuracy: 0.001)
    }

    func testCustomGridKeepsIndependentRowsAndColumnsAndScrollsOverflow() throws {
        let preset = FolderLayoutPreset.customGrid(rows: 2, columns: 3, showsAppLabels: true)
        let folder = DockFolder(name: "Code", applications: (1...8).map {
            ApplicationItem(url: URL(fileURLWithPath: "/Applications/Test \($0).app"))
        }, layoutPreset: preset)
        let decoded = try JSONDecoder().decode(DockFolder.self, from: JSONEncoder().encode(folder))

        XCTAssertEqual(decoded.layoutPreset.rows, 2)
        XCTAssertEqual(decoded.layoutPreset.columns, 3)
        XCTAssertEqual(decoded.layoutPreset.fitting(8), preset)

        let layout = DockPopupLayout.calculate(
            applicationCount: 8,
            preset: decoded.layoutPreset,
            availableSize: NSSize(width: 1_000, height: 700),
            preferredIconSize: 68
        )
        XCTAssertEqual(layout.columns, 3)
        XCTAssertEqual(layout.size.height, 100 + 2 * (68 + DockPopupLayout.labelHeight(for: 68) + DockPopupLayout.labelSpacing(for: 68)) + 12)
        XCTAssertEqual(FolderLayoutPreset.customGrid(rows: 0, columns: 11, showsAppLabels: true).rows, 1)
        XCTAssertEqual(FolderLayoutPreset.customGrid(rows: 0, columns: 11, showsAppLabels: true).columns, 10)

        let compact = DockPopupLayout.calculate(
            applicationCount: 8,
            preset: .customGrid(rows: 1, columns: 6, showsAppLabels: true),
            availableSize: NSSize(width: 1_000, height: 700),
            preferredIconSize: 36
        )
        let enlarged = DockPopupLayout.calculate(
            applicationCount: 8,
            preset: .customGrid(rows: 1, columns: 6, showsAppLabels: true),
            availableSize: NSSize(width: 1_000, height: 700),
            preferredIconSize: 96
        )
        XCTAssertLessThan(compact.size.width, enlarged.size.width)
        XCTAssertLessThan(compact.size.height, enlarged.size.height)
    }

    func testCustomGridFitsSelectedCellsWithinAvailableDisplay() {
        let layout = DockPopupLayout.calculate(
            applicationCount: 4,
            preset: .customGrid(rows: 2, columns: 2, showsAppLabels: false),
            availableSize: NSSize(width: 800, height: 500),
            preferredIconSize: 68
        )

        XCTAssertEqual(layout.columns, 2)
        XCTAssertEqual(layout.iconSize, 68)
        XCTAssertEqual(layout.size.width, 360)
        XCTAssertEqual(layout.size.height, 100 + 2 * 68 + 12)

        let constrained = DockPopupLayout.calculate(
            applicationCount: 100,
            preset: .customGrid(rows: 10, columns: 10, showsAppLabels: true),
            availableSize: NSSize(width: 500, height: 400),
            preferredIconSize: 128
        )
        XCTAssertLessThan(constrained.iconSize, 128)
        XCTAssertLessThanOrEqual(constrained.size.width, 500)
        XCTAssertLessThanOrEqual(constrained.size.height, 400)
    }

    func testHoverPopupStaysOpenWhileLayoutOptionsArePresented() throws {
        let manager = PopupWindowManager.shared
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = FolderStore(persistence: FolderPersistenceService(fileURL: directory.appendingPathComponent("folders.json")))
        store.createFolder(named: "Hover options")
        let folder = try XCTUnwrap(store.folders.first)
        defer {
            manager.close(animated: false)
            try? FileManager.default.removeItem(at: directory)
        }

        manager.present(folderID: folder.id, store: store, source: .hover, anchor: NSPoint(x: 500, y: 500))
        manager.layoutOptionsDidChange(isPresented: true)
        let frame = try XCTUnwrap(manager.panelFrame)
        let outsidePoint = NSPoint(x: frame.minX - 100, y: frame.minY - 100)

        XCTAssertFalse(manager.shouldDismissHoverPopup(at: outsidePoint))
        manager.layoutOptionsDidChange(isPresented: false)
        XCTAssertTrue(manager.shouldDismissHoverPopup(at: outsidePoint))
    }

    func testAddingAppsAutomaticallyGrowsFolderLayoutWhenGridIsTooSmall() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("folders.json")
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = FolderStore(persistence: FolderPersistenceService(fileURL: fileURL))
        store.createFolder(named: "Code")
        let folderID = try XCTUnwrap(store.folders.first?.id)
        store.setLayoutPreset(.dynamicGrid(side: 2, showsAppLabels: true), for: folderID)

        for index in 1...5 {
            store.add(ApplicationItem(url: URL(fileURLWithPath: "/Applications/Test \(index).app")), to: folderID)
        }

        XCTAssertEqual(store.folders.first?.layoutPreset.columns, 3)
    }

    func testPopupCollapsedTransformMovesPanelCenterToDockAnchor() {
        let center = NSPoint(x: 180, y: 120)
        let anchor = NSPoint(x: 24, y: 18)

        let transform = DockPopupAnimation.collapsedTransform(scale: 0.035, anchor: anchor, center: center)

        XCTAssertEqual(transform.m11, 0.035, accuracy: 0.0001)
        XCTAssertEqual(transform.m22, 0.035, accuracy: 0.0001)
        XCTAssertEqual(transform.m41, anchor.x - center.x, accuracy: 0.0001)
        XCTAssertEqual(transform.m42, anchor.y - center.y, accuracy: 0.0001)
    }

    func testPopupPositioningUsesPointerWhenDockInsetIsUnavailable() {
        let screen = NSRect(x: 0, y: 0, width: 1_000, height: 800)
        let popup = NSSize(width: 360, height: 220)

        let bottom = DockPopupPositioning.origin(
            for: popup,
            anchor: NSPoint(x: 500, y: 30),
            screenFrame: screen,
            visibleFrame: screen
        )
        XCTAssertEqual(bottom, NSPoint(x: 320, y: 74))

        let left = DockPopupPositioning.origin(
            for: popup,
            anchor: NSPoint(x: 30, y: 400),
            screenFrame: screen,
            visibleFrame: screen
        )
        XCTAssertEqual(left, NSPoint(x: 74, y: 290))

        let right = DockPopupPositioning.origin(
            for: popup,
            anchor: NSPoint(x: 970, y: 400),
            screenFrame: screen,
            visibleFrame: screen
        )
        XCTAssertEqual(right, NSPoint(x: 566, y: 290))
    }

    func testPopupPositioningRespectsScreenInsetsWithAutoHideDock() {
        let screen = NSRect(x: 0, y: 0, width: 1_000, height: 800)
        let popup = NSSize(width: 360, height: 220)
        let bottom = DockPopupPositioning.origin(
            for: popup,
            anchor: NSPoint(x: 500, y: 30),
            screenFrame: screen,
            visibleFrame: NSRect(x: 0, y: 60, width: 1_000, height: 740)
        )
        XCTAssertEqual(bottom, NSPoint(x: 320, y: 72))

        let left = DockPopupPositioning.origin(
            for: popup,
            anchor: NSPoint(x: 30, y: 400),
            screenFrame: screen,
            visibleFrame: NSRect(x: 70, y: 0, width: 930, height: 800)
        )
        XCTAssertEqual(left, NSPoint(x: 82, y: 290))
    }

    func testLauncherBundleContainsStableFolderRoute() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let id = UUID()
        let folder = DockFolder(id: id, name: "Code")
        let service = FolderLauncherService(rootURL: root)

        let launcher = try service.createOrUpdate(for: folder)

        XCTAssertEqual(launcher.lastPathComponent, "Code.app")
        let plist = try XCTUnwrap(NSDictionary(contentsOf: launcher.appendingPathComponent("Contents/Info.plist")) as? [String: Any])
        XCTAssertEqual(plist["CFBundleDisplayName"] as? String, "Code")
        XCTAssertEqual(plist["CFBundleIconFile"] as? String, "AppIcon.icns")
        let iconURL = launcher.appendingPathComponent("Contents/Resources/AppIcon.icns")
        XCTAssertTrue(FileManager.default.fileExists(atPath: iconURL.path))
        let icon = try XCTUnwrap(NSImage(contentsOf: iconURL))
        XCTAssertTrue(icon.representations.contains { $0.pixelsWide >= 1_024 && $0.pixelsHigh >= 1_024 })
        XCTAssertEqual(plist["CFBundleIdentifier"] as? String, "com.gregkorneev.DockFolders.launcher.\(id.uuidString.lowercased())")
        let script = try String(contentsOf: launcher.appendingPathComponent("Contents/MacOS/launch"), encoding: .utf8)
        XCTAssertTrue(script.contains(DockFolderLink.url(for: id).absoluteString))
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: launcher.appendingPathComponent("Contents/MacOS/launch").path))
    }

    func testGeneratedFolderIconUsesStandard1024SquareCanvas() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let image = FolderLauncherService(rootURL: root).makeIcon(symbol: "folder.fill", color: .systemBlue)
        let bitmap = try XCTUnwrap(image.representations.compactMap { $0 as? NSBitmapImageRep }.first)

        XCTAssertEqual(bitmap.pixelsWide, 1_024)
        XCTAssertEqual(bitmap.pixelsHigh, 1_024)
        XCTAssertEqual(bitmap.size.width, 512)
        XCTAssertEqual(bitmap.size.height, 512)
    }

    func testLauncherNamesTrackFolderRename() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let folderID = UUID()
        let service = FolderLauncherService(rootURL: root)

        let first = try service.createOrUpdate(for: DockFolder(id: folderID, name: "Code"))
        let renamed = try service.createOrUpdate(for: DockFolder(id: folderID, name: "Разработка"))

        XCTAssertEqual(renamed.lastPathComponent, "Разработка.app")
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamed.path))
    }

    func testDuplicateFolderNamesGetReadableNumberedLauncherNames() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let service = FolderLauncherService(rootURL: root)

        let first = try service.createOrUpdate(for: DockFolder(name: "Work"))
        let second = try service.createOrUpdate(for: DockFolder(name: "Work"))

        XCTAssertEqual(first.lastPathComponent, "Work.app")
        XCTAssertEqual(second.lastPathComponent, "Work 2.app")
        let firstInfo = try XCTUnwrap(NSDictionary(contentsOf: first.appendingPathComponent("Contents/Info.plist")) as? [String: Any])
        let secondInfo = try XCTUnwrap(NSDictionary(contentsOf: second.appendingPathComponent("Contents/Info.plist")) as? [String: Any])
        XCTAssertNotEqual(firstInfo["CFBundleIdentifier"] as? String, secondInfo["CFBundleIdentifier"] as? String)
    }

    func testStoreCreatesAndReloadsFolder() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("folders.json")
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let store = FolderStore(persistence: FolderPersistenceService(fileURL: fileURL))
        store.createFolder(named: "  Work  ")
        store.createFolder(named: "   ")

        let reloadedStore = FolderStore(persistence: FolderPersistenceService(fileURL: fileURL))
        XCTAssertEqual(store.folders.map(\.name), ["Work"])
        XCTAssertEqual(reloadedStore.folders, store.folders)
    }

    func testStoreRenamesAndDeletesFolder() {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("folders.json")
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = FolderStore(persistence: FolderPersistenceService(fileURL: fileURL))
        store.createFolder(named: "Work")
        let id = store.folders[0].id

        store.renameFolder(id: id, to: "Office")
        XCTAssertEqual(store.folders.first?.name, "Office")
        store.deleteFolder(id: id)
        XCTAssertTrue(store.folders.isEmpty)
        XCTAssertTrue(FolderStore(persistence: FolderPersistenceService(fileURL: fileURL)).folders.isEmpty)
    }

    func testFolderAndApplicationOrderingPersists() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true).appendingPathComponent("folders.json")
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let store = FolderStore(persistence: FolderPersistenceService(fileURL: fileURL))
        store.createFolder(named: "First")
        store.createFolder(named: "Second")
        let firstID = try XCTUnwrap(store.folders.first?.id)
        let secondID = try XCTUnwrap(store.folders.last?.id)
        store.moveFolder(id: secondID, before: firstID)
        XCTAssertEqual(store.folders.map(\.name), ["Second", "First"])

        let one = ApplicationItem(url: URL(fileURLWithPath: "/Applications/One.app"))
        let two = ApplicationItem(url: URL(fileURLWithPath: "/Applications/Two.app"))
        store.add(one, to: firstID)
        store.add(two, to: firstID)
        store.moveApplication(id: try XCTUnwrap(store.folders.first(where: { $0.id == firstID })?.applications.last?.id), before: one.id, in: firstID)
        XCTAssertEqual(store.folders.first(where: { $0.id == firstID })?.applications.map(\.name), ["Two", "One"])
        XCTAssertEqual(FolderStore(persistence: FolderPersistenceService(fileURL: fileURL)).folders.first?.id, secondID)
    }

    func testConfigurationTransferRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("settings.json")
        let document = FolderDocument(
            folders: [DockFolder(name: "Dark", iconName: "moon.fill", colorHex: "#222222", iconSize: 92, gridColumns: 5, glassTransparency: 0.8)],
            settings: AppSettings(appearance: .dark, launchAtLogin: true, globalShortcutEnabled: true)
        )

        try ConfigurationTransferService().export(document, to: url)

        XCTAssertEqual(try ConfigurationTransferService().import(from: url).folders, document.folders)
        XCTAssertEqual(try ConfigurationTransferService().import(from: url).settings, document.settings)
    }

    func testCorruptSavedFileIsNotOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("folders.json")
        let corruptData = Data("{ invalid json".utf8)
        try corruptData.write(to: fileURL)

        let store = FolderStore(persistence: FolderPersistenceService(fileURL: fileURL))
        store.createFolder(named: "Work")

        XCTAssertEqual(try Data(contentsOf: fileURL), corruptData)
        XCTAssertTrue(store.folders.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    func testUnsupportedDocumentVersionIsNotOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("folders.json")
        let futureData = Data("{\"version\":2,\"folders\":[]}".utf8)
        try futureData.write(to: fileURL)

        let store = FolderStore(persistence: FolderPersistenceService(fileURL: fileURL))
        store.createFolder(named: "Work")

        XCTAssertEqual(try Data(contentsOf: fileURL), futureData)
        XCTAssertTrue(store.folders.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    func testDuplicateApplicationIsNotAddedTwice() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("folders.json")
        let store = FolderStore(persistence: FolderPersistenceService(fileURL: fileURL))
        store.createFolder(named: "Work")
        let folderID = try XCTUnwrap(store.folders.first?.id)
        let appURL = URL(fileURLWithPath: "/Applications/Utilities/Terminal.app")
        let app = ApplicationItem(url: appURL)

        store.add(app, to: folderID)
        store.add(app, to: folderID)

        XCTAssertEqual(store.folders.first?.applications.count, 1)
    }

    func testDiscoveryFindsNestedAppsWithoutEnteringAppBundles() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let terminal = root.appendingPathComponent("Utilities/Terminal.app", isDirectory: true)
        let nestedHelper = terminal.appendingPathComponent("Contents/Helpers/Helper.app", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedHelper, withIntermediateDirectories: true)

        let applications = await ApplicationDiscoveryService(searchRoots: [root]).discoverApplications()

        XCTAssertEqual(applications.map(\.name), ["Terminal"])
    }

    func testLauncherReportsRemovedApplication() async {
        let application = ApplicationItem(url: FileManager.default.temporaryDirectory.appendingPathComponent("Missing.app"))
        do {
            try await ApplicationLauncherService().launch(application)
            XCTFail("Expected missing app to throw")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing.app"))
        }
    }
}
