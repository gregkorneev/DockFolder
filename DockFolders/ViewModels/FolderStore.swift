import Foundation
import Observation

@MainActor
@Observable
final class FolderStore {
    private(set) var folders: [DockFolder]
    var errorMessage: String?

    private let persistence: FolderPersistenceService
    private var loadFailed = false

    init(persistence: FolderPersistenceService = FolderPersistenceService()) {
        self.persistence = persistence
        do {
            folders = try persistence.load().folders
        } catch {
            folders = []
            loadFailed = true
            errorMessage = "Saved folders could not be read. The existing file was left untouched. \(error.localizedDescription)"
        }
    }

    func createFolder(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        update { $0.append(DockFolder(name: trimmedName)) }
    }

    func renameFolder(id: UUID, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
            folders[index].name = trimmedName
        }
    }

    func deleteFolder(id: UUID) {
        update { $0.removeAll { $0.id == id } }
    }

    func add(_ application: ApplicationItem, to folderID: UUID) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == folderID }),
                  !folders[index].applications.contains(where: { $0.matches(application) }) else { return }
            folders[index].applications.append(application)
        }
    }

    func removeApplication(id: UUID, from folderID: UUID) {
        update { folders in
            guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
            folders[index].applications.removeAll { $0.id == id }
        }
    }

    func clearError() { errorMessage = nil }

    private func update(_ change: (inout [DockFolder]) -> Void) {
        guard !loadFailed else { return }
        var updatedFolders = folders
        change(&updatedFolders)
        do {
            try persistence.save(FolderDocument(folders: updatedFolders))
            folders = updatedFolders
        } catch {
            errorMessage = "Changes could not be saved. Your previous folders are still available. \(error.localizedDescription)"
        }
    }
}
