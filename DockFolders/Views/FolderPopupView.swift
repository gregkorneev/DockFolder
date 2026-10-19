import AppKit
import SwiftUI

struct FolderPopupView: View {
    @Bindable var store: FolderStore
    let folderID: UUID
    @State private var searchText = ""

    private var folder: DockFolder? { store.folders.first(where: { $0.id == folderID }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let folder {
                HStack(spacing: 7) {
                    Image(systemName: folder.iconName)
                        .foregroundStyle(Color(nsColor: NSColor(hex: folder.colorHex)))
                    Text(folder.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    TextField("Search apps", text: $searchText)
                        .font(.caption)
                        .textFieldStyle(.plain)
                        .frame(width: 104)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())
                    Spacer(minLength: 8)
                    Button { PopupWindowManager.shared.close() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close folder popup")
                    .keyboardShortcut(.cancelAction)
                }

                let columns = min(max(1, store.settings.gridColumns > 0 ? store.settings.gridColumns : 4), 4)
                let visibleApplications = folder.applications.filter {
                    searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                }
                if visibleApplications.isEmpty {
                    Text("No matching apps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
                            ForEach(visibleApplications) { application in
                            Button {
                                Task {
                                    do {
                                        try await ApplicationLauncherService().launch(application)
                                        PopupWindowManager.shared.close()
                                    } catch {
                                        store.errorMessage = AppLocalization.format("Could not open %@. %@", application.name, error.localizedDescription)
                                    }
                                }
                            } label: {
                                VStack(spacing: 5) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 56, height: 56)
                                    Text(application.name)
                                        .font(.system(size: 11))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, minHeight: 27, alignment: .top)
                                }
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help(AppLocalization.format("Open %@", application.name))
                            .accessibilityLabel(application.name)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
        .onExitCommand { PopupWindowManager.shared.close() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
