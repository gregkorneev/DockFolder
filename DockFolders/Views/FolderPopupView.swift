import AppKit
import SwiftUI

struct FolderPopupView: View {
    @Bindable var store: FolderStore
    let folderID: UUID
    let columns: Int
    let iconSize: CGFloat
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
                    Menu {
                        Picker("Folder layout", selection: Binding(
                            get: { folder.layoutPreset.id },
                            set: { id in
                                guard let preset = store.settings.layoutPresets.first(where: { $0.id == id }) else { return }
                                store.setLayoutPreset(preset, for: folderID)
                            }
                        )) {
                            ForEach(layoutChoices(for: folder)) { preset in
                                Text(AppLocalization.layoutPresetName(preset)).tag(preset.id)
                            }
                        }
                        Toggle("Show app names", isOn: Binding(
                            get: { folder.layoutPreset.showsAppLabels },
                            set: { show in
                                var preset = folder.layoutPreset
                                preset.showsAppLabels = show
                                store.setLayoutPreset(preset, for: folderID)
                            }
                        ))
                    } label: {
                        Image(systemName: "rectangle.grid.2x2")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .accessibilityLabel("Folder layout options")
                    Button { PopupWindowManager.shared.close() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close folder popup")
                    .keyboardShortcut(.cancelAction)
                }

                let preset = folder.layoutPreset
                let visibleApplications = folder.applications.filter {
                    searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                }
                if visibleApplications.isEmpty {
                    Text("No matching apps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
                        ForEach(visibleApplications) { application in
                            applicationButton(application, showsLabel: preset.showsAppLabels)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity((1 - store.settings.glassTransparency) * 0.7))
        }
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 22))
        .onExitCommand { PopupWindowManager.shared.close() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func applicationButton(_ application: ApplicationItem, showsLabel: Bool) -> some View {
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
            VStack(spacing: showsLabel ? 5 : 0) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                if showsLabel {
                    Text(application.name)
                        .font(.system(size: 11))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 27, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(AppLocalization.format("Open %@", application.name))
        .accessibilityLabel(application.name)
    }

    private func layoutChoices(for folder: DockFolder) -> [FolderLayoutPreset] {
        var choices = store.settings.layoutPresets.filter { $0.fits(folder.applications.count) }
        let requiredSide = max(2, Int(ceil(sqrt(Double(folder.applications.count)))))
        for side in requiredSide...(requiredSide + 2) where !choices.contains(where: { !$0.isSingleRow && !$0.isSingleColumn && $0.columns == side }) {
            choices.append(.dynamicGrid(side: side, showsAppLabels: folder.layoutPreset.showsAppLabels))
        }
        return choices.sorted { lhs, rhs in
            if lhs.isSingleRow || lhs.isSingleColumn { return false }
            if rhs.isSingleRow || rhs.isSingleColumn { return true }
            return lhs.columns < rhs.columns
        }
    }
}
