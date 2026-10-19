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

    func testLauncherBundleContainsStableFolderRoute() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let id = UUID()
        let folder = DockFolder(id: id, name: "Code")
        let service = FolderLauncherService(rootURL: root)

        let launcher = try service.createOrUpdate(for: folder)

        let plist = try XCTUnwrap(NSDictionary(contentsOf: launcher.appendingPathComponent("Contents/Info.plist")) as? [String: Any])
        XCTAssertEqual(plist["CFBundleDisplayName"] as? String, "Code")
        XCTAssertEqual(plist["CFBundleIdentifier"] as? String, "com.gregkorneev.DockFolders.launcher.\(id.uuidString.lowercased())")
        let script = try String(contentsOf: launcher.appendingPathComponent("Contents/MacOS/launch"), encoding: .utf8)
        XCTAssertTrue(script.contains(DockFolderLink.url(for: id).absoluteString))
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: launcher.appendingPathComponent("Contents/MacOS/launch").path))
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
