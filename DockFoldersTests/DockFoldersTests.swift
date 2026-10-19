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
