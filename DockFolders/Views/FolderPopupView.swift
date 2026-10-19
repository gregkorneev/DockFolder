import AppKit
import SwiftUI

struct FolderPopupView: View {
    @Bindable var store: FolderStore
    let folderID: UUID
    @State private var searchText = ""

    private var folder: DockFolder? { store.folders.first(where: { $0.id == folderID }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                if let folder {
                    Image(systemName: folder.iconName).foregroundStyle(Color(nsColor: NSColor(hex: folder.colorHex)))
                    Text(folder.name).font(.title3.bold()).lineLimit(1)
                }
                Spacer()
                Button { PopupWindowManager.shared.close() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close folder popup")
                .keyboardShortcut(.cancelAction)
            }

            TextField("Search apps", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if let folder, visibleApplications(in: folder).isEmpty {
                ContentUnavailableView("No matching apps", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if let folder {
                let columns = store.settings.gridColumns > 0 ? store.settings.gridColumns : 4
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 64), spacing: 10), count: columns), spacing: 12) {
                    ForEach(visibleApplications(in: folder)) { application in
                        ApplicationTile(application: application, iconSize: CGFloat(store.settings.iconSize)) {
                            Task {
                                do {
                                    try await ApplicationLauncherService().launch(application)
                                    PopupWindowManager.shared.close()
                                } catch {
                                    store.errorMessage = AppLocalization.format("Could not open %@. %@", application.name, error.localizedDescription)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        .onExitCommand { PopupWindowManager.shared.close() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func visibleApplications(in folder: DockFolder) -> [ApplicationItem] {
        guard !searchText.isEmpty else { return folder.applications }
        return folder.applications.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}
