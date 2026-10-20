import AppKit
import SwiftUI

struct FolderPopupView: View {
    @Bindable var store: FolderStore
    let folderID: UUID
    let columns: Int
    let iconSize: CGFloat
    @State private var searchText = ""
    @State private var showingLayoutOptions = false

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
                    Button {
                        showingLayoutOptions.toggle()
                    } label: {
                        Image(systemName: "rectangle.grid.2x2")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Folder layout options")
                    .popover(isPresented: $showingLayoutOptions, arrowEdge: .top) {
                        FolderLayoutOptions(store: store, folderID: folderID)
                    }
                    .onChange(of: showingLayoutOptions) { _, isPresented in
                        PopupWindowManager.shared.layoutOptionsDidChange(isPresented: isPresented)
                    }
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
                    if preset.isCustomGrid {
                        let cellWidth = max(84, iconSize + 16)
                        let contentWidth = CGFloat(preset.columns) * cellWidth + CGFloat(preset.columns - 1) * 12
                        ScrollView([.horizontal, .vertical]) {
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: 12), count: preset.columns), spacing: 12) {
                                ForEach(visibleApplications) { application in
                                    applicationButton(application, showsLabel: preset.showsAppLabels)
                                }
                            }
                            .frame(width: contentWidth)
                        }
                    } else {
                        let activeColumns = folder.gridColumns > 0 ? min(folder.gridColumns, visibleApplications.count) : columns
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: max(activeColumns, 1)), spacing: 12) {
                            ForEach(visibleApplications) { application in
                                applicationButton(application, showsLabel: preset.showsAppLabels)
                            }
                        }
                    }
                }
            }
        }
        .padding(.init(top: 14, leading: 14, bottom: 30, trailing: 14))
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity((1 - (folder?.glassTransparency ?? 0.55)) * 0.7))
        }
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 22))
        .onExitCommand { PopupWindowManager.shared.close() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("DockFolders", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.clearError() } }
        )) {
            Button("OK", role: .cancel) { store.clearError() }
        } message: {
            Text(verbatim: store.errorMessage ?? NSLocalizedString("An unexpected error occurred.", comment: ""))
        }
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
                    .frame(width: min(iconSize, CGFloat(folder?.iconSize ?? 68)), height: min(iconSize, CGFloat(folder?.iconSize ?? 68)))
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

}

private struct FolderLayoutOptions: View {
    @Bindable var store: FolderStore
    let folderID: UUID

    private var folder: DockFolder? { store.folders.first(where: { $0.id == folderID }) }

    var body: some View {
        if let folder {
            Form {
                HStack {
                    Text("Folder layout")
                    Spacer()
                    TextField("Rows", value: Binding(
                        get: { self.folder.map(displayedRows) ?? 1 },
                        set: { updateCustomGrid(rows: $0) }
                    ), format: .number)
                    .frame(width: 48)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Rows")
                    Text("×")
                    TextField("Columns", value: Binding(
                        get: { self.folder.map(displayedColumns) ?? 1 },
                        set: { updateCustomGrid(columns: $0) }
                    ), format: .number)
                    .frame(width: 48)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Columns")
                }
                Text("Enter 1–10 rows and columns. Extra apps scroll within the folder.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Show app names", isOn: Binding(
                    get: { folder.layoutPreset.showsAppLabels },
                    set: { show in store.updateFolderLayout(folderID) { $0.layoutPreset.showsAppLabels = show } }
                ))
                Slider(value: Binding(
                    get: { folder.iconSize },
                    set: { value in store.updateFolderLayout(folderID) { $0.iconSize = value } }
                ), in: 36...128, step: 4) {
                    Text("App icon size")
                } minimumValueLabel: { Text("Small") } maximumValueLabel: { Text("Large") }
                Slider(value: Binding(
                    get: { folder.glassTransparency },
                    set: { value in store.updateFolderLayout(folderID) { $0.glassTransparency = value } }
                ), in: 0...1, step: 0.05) {
                    Text("Glass transparency")
                } minimumValueLabel: { Text("Matte") } maximumValueLabel: { Text("Clear") }
            }
            .formStyle(.grouped)
            .padding(12)
            .frame(width: 360)
        }
    }

    private func displayedRows(_ folder: DockFolder) -> Int {
        if let rows = folder.layoutPreset.rows { return rows }
        if folder.layoutPreset.isSingleRow { return 1 }
        if folder.layoutPreset.isSingleColumn { return min(max(folder.applications.count, 1), 10) }
        return min(max(folder.layoutPreset.columns, 1), 10)
    }

    private func displayedColumns(_ folder: DockFolder) -> Int {
        if folder.gridColumns > 0 { return min(folder.gridColumns, 10) }
        if folder.layoutPreset.isSingleColumn { return 1 }
        if folder.layoutPreset.isSingleRow { return min(max(folder.applications.count, 1), 10) }
        return min(max(folder.layoutPreset.columns, 1), 10)
    }

    private func updateCustomGrid(rows: Int? = nil, columns: Int? = nil) {
        guard let folder else { return }
        let newRows = rows ?? displayedRows(folder)
        let newColumns = columns ?? displayedColumns(folder)
        store.updateFolderLayout(folderID) { folder in
            folder.layoutPreset = .customGrid(rows: newRows, columns: newColumns, showsAppLabels: folder.layoutPreset.showsAppLabels)
            folder.gridColumns = 0
        }
        PopupWindowManager.shared.refreshLayout(folderID: folderID, store: store)
    }
}
