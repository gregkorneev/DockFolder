import Foundation
import Observation

@MainActor
@Observable
final class FolderStore {
    private(set) var folders: [DockFolder]
    private(set) var settings: AppSettings
    var errorMessage: String?

    private let persistence: FolderPersistenceService
    private var loadFailed = false

    init(persistence: FolderPersistenceService = FolderPersistenceService()) {
        self.persistence = persistence
        do {
            let document = try persistence.load()
            folders = document.folders
            settings = document.settings
        } catch {
            folders = []
            settings = AppSettings()
            loadFailed = true
            errorMessage = AppLocalization.format("Saved folders could not be read. The existing file was left untouched. %@", error.localizedDescription)
        }
    }

    func createFolder(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        update { $0.append(DockFolder(name: trimmedName)) }
    }

    func setLayoutPreset(_ preset: FolderLayoutPreset, for folderID: UUID) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
            folders[index].layoutPreset = preset
        }
    }

    func updateFolderLayout(_ folderID: UUID, change: (inout DockFolder) -> Void) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
            change(&folders[index])
        }
    }

    func renameFolder(id: UUID, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
            folders[index].name = trimmedName
        }
    }

    func customizeFolder(id: UUID, iconName: String, colorHex: String) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
            folders[index].iconName = iconName
            folders[index].colorHex = colorHex
        }
    }

    func setDockLauncherEnabled(_ enabled: Bool, for folderID: UUID) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
            folders[index].hasDockLauncher = enabled
        }
    }

    func moveFolders(from source: IndexSet, to destination: Int) {
        update { $0.move(fromOffsets: source, toOffset: destination) }
    }

    func moveFolder(id: UUID, before targetID: UUID) {
        update { folders in
            guard let sourceIndex = folders.firstIndex(where: { $0.id == id }),
                  let targetIndex = folders.firstIndex(where: { $0.id == targetID }),
                  sourceIndex != targetIndex else { return }
            let folder = folders.remove(at: sourceIndex)
            let adjustedTarget = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
            folders.insert(folder, at: adjustedTarget)
        }
    }

    func moveApplications(in folderID: UUID, from source: IndexSet, to destination: Int) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
            folders[index].applications.move(fromOffsets: source, toOffset: destination)
        }
    }

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        guard !loadFailed else { return }
        var nextSettings = settings
        change(&nextSettings)
        do {
            try persistence.save(FolderDocument(folders: folders, settings: nextSettings))
            settings = nextSettings
        } catch {
            errorMessage = AppLocalization.format("Settings could not be saved. Your previous settings are still available. %@", error.localizedDescription)
        }
    }

    func replaceConfiguration(with document: FolderDocument) {
        guard !loadFailed else { return }
        do {
            try persistence.save(FolderDocument(folders: document.folders, settings: document.settings))
            folders = document.folders
            settings = document.settings
        } catch {
            errorMessage = AppLocalization.format("Configuration could not be imported. Existing data was left unchanged. %@", error.localizedDescription)
        }
    }

    @discardableResult
    func deleteFolder(id: UUID) -> Bool {
        update { $0.removeAll { $0.id == id } }
    }

    func add(_ application: ApplicationItem, to folderID: UUID) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == folderID }),
                  !folders[index].applications.contains(where: { $0.matches(application) }) else { return }
            folders[index].applications.append(application)
            folders[index].layoutPreset = folders[index].layoutPreset.fitting(folders[index].applications.count)
        }
    }

    func removeApplication(id: UUID, from folderID: UUID) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
            folders[index].applications.removeAll { $0.id == id }
        }
    }

    func moveApplication(id: UUID, before targetID: UUID, in folderID: UUID) {
        update { folders in
            guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }),
                  let sourceIndex = folders[folderIndex].applications.firstIndex(where: { $0.id == id }),
                  let targetIndex = folders[folderIndex].applications.firstIndex(where: { $0.id == targetID }),
                  sourceIndex != targetIndex else { return }
            let application = folders[folderIndex].applications.remove(at: sourceIndex)
            let adjustedTarget = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
            folders[folderIndex].applications.insert(application, at: adjustedTarget)
        }
    }

    func replaceApplication(id: UUID, in folderID: UUID, with replacement: ApplicationItem) {
        update { folders in
            guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }),
                  let itemIndex = folders[folderIndex].applications.firstIndex(where: { $0.id == id }) else { return }
            var updated = replacement
            updated.id = id
            folders[folderIndex].applications[itemIndex] = updated
        }
    }

    func clearError() { errorMessage = nil }

    @discardableResult
    private func update(_ change: (inout [DockFolder]) -> Void) -> Bool {
        guard !loadFailed else { return false }
        var updatedFolders = folders
        change(&updatedFolders)
        do {
            try persistence.save(FolderDocument(folders: updatedFolders, settings: settings))
            folders = updatedFolders
            return true
        } catch {
            errorMessage = AppLocalization.format("Changes could not be saved. Your previous folders are still available. %@", error.localizedDescription)
            return false
        }
    }
}
