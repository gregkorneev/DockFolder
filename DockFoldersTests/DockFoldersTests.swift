import AppKit
import Foundation
import XCTest
@testable import DockFolders

@MainActor
final class DockFoldersTests: XCTestCase {
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
        let twoByTwo = FolderLayoutPreset.dynamicGrid(side: 2, showsAppLabels: true)
        let threeByThree = FolderLayoutPreset.defaults[1]
        let fourByFour = FolderLayoutPreset.defaults[0]

        XCTAssertTrue(twoByTwo.fits(4))
        XCTAssertFalse(twoByTwo.fits(5))
        XCTAssertFalse(threeByThree.fits(10))
        XCTAssertTrue(fourByFour.fits(10))
        XCTAssertEqual(fourByFour.fitting(17).columns, 5)
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
            folders: [DockFolder(name: "Dark", iconName: "moon.fill", colorHex: "#222222")],
            settings: AppSettings(iconSize: 92, gridColumns: 5, appearance: .dark, launchAtLogin: true, globalShortcutEnabled: true)
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
