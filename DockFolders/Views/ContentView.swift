import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(FolderStore.self) private var folderStore
    @State private var selectedFolderID: UUID?
    @State private var showingCreateFolder = false
    @State private var showingRenameFolder = false
    @State private var showingAddApplications = false
    @State private var showingSettings = false
    @State private var showingDockLauncherHelp = false
    @State private var folderForAppearance: DockFolder?
    @State private var folderPendingDeletion: DockFolder?
    @State private var newFolderName = ""
    @State private var renamedFolder = ""
    @State private var searchText = ""

    private var selectedFolder: DockFolder? {
        folderStore.folders.first { $0.id == selectedFolderID }
    }

    private var colorScheme: ColorScheme? {
        switch folderStore.settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private var applicationGridColumns: [GridItem] {
        if folderStore.settings.gridColumns > 0 {
            return Array(repeating: GridItem(.flexible(), spacing: 18), count: folderStore.settings.gridColumns)
        }
        return [GridItem(.adaptive(minimum: 112), spacing: 18)]
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .background(.ultraThinMaterial)
        .preferredColorScheme(colorScheme)
        .onAppear {
            if selectedFolderID == nil { selectedFolderID = folderStore.folders.first?.id }
            if let pendingURL = DockIntegrationManager.consumePendingURL() { openFolderURL(pendingURL) }
            GlobalShortcutService.shared.onShortcut = {
                guard let firstFolderID = folderStore.folders.first?.id else { return }
                if PopupWindowManager.shared.isVisible { PopupWindowManager.shared.close() }
                else { PopupWindowManager.shared.present(folderID: firstFolderID, store: folderStore) }
            }
            if folderStore.settings.globalShortcutEnabled { try? GlobalShortcutService.shared.enable() }
        }
        .onReceive(NotificationCenter.default.publisher(for: DockIntegrationManager.folderLinkOpened)) { notification in
            if let url = notification.object as? URL { openFolderURL(url) }
        }
        .onChange(of: folderStore.folders) { _, folders in
            if !folders.contains(where: { $0.id == selectedFolderID }) {
                selectedFolderID = folders.first?.id
            }
        }
        .alert("Create Folder", isPresented: $showingCreateFolder) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") { folderStore.createFolder(named: newFolderName) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose a name for this folder.")
        }
        .alert("Rename Folder", isPresented: $showingRenameFolder) {
            TextField("Folder name", text: $renamedFolder)
            Button("Save") { renameSelectedFolder() }
            Button("Cancel", role: .cancel) { }
        }
        .alert("DockFolders", isPresented: Binding(
            get: { folderStore.errorMessage != nil },
            set: { if !$0 { folderStore.clearError() } }
        )) {
            Button("OK", role: .cancel) { folderStore.clearError() }
        } message: {
            Text(verbatim: folderStore.errorMessage ?? "An unexpected error occurred.")
        }
        .alert("Dock icon created", isPresented: $showingDockLauncherHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The launcher is selected in Finder. Drag it to the application area of the Dock to pin it. macOS does not allow DockFolders to pin icons automatically.")
        }
        .confirmationDialog("Delete folder?", isPresented: Binding(
            get: { folderPendingDeletion != nil },
            set: { if !$0 { folderPendingDeletion = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Folder", role: .destructive) {
                if let folderPendingDeletion { deleteFolder(folderPendingDeletion) }
                folderPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { folderPendingDeletion = nil }
        } message: {
            if folderPendingDeletion?.hasDockLauncher == true {
                Text("If this launcher is pinned in the Dock, remove its Dock item first. The launcher file will then be deleted.")
            } else {
                Text("The folder and its app list will be removed.")
            }
        }
        .sheet(isPresented: $showingAddApplications) {
            if let selectedFolderID {
                ApplicationPickerSheet(folderID: selectedFolderID)
                    .environment(folderStore)
                    .frame(minWidth: 560, minHeight: 480)
            }
        }
        .sheet(item: $folderForAppearance) { folder in
            FolderAppearanceSheet(folder: folder) { symbol, hex in
                folderStore.customizeFolder(id: folder.id, iconName: symbol, colorHex: hex)
                updateDockLauncherIfNeeded(folderID: folder.id)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView().environment(folderStore)
        }
    }

    private var sidebar: some View {
            VStack(spacing: 12) {
                HStack {
                    Label("My Folders", systemImage: "folder.fill")
                        .font(.headline)
                    Spacer()
                    Button {
                        newFolderName = ""
                        showingCreateFolder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .help("Create folder")
                    .accessibilityLabel("Create folder")
                }
                .padding(.horizontal, 14)
                .padding(.top, 18)

                if folderStore.folders.isEmpty {
                    ContentUnavailableView("No folders yet", systemImage: "folder.badge.plus", description: Text("Create a folder to start organizing your apps."))
                        .padding(.horizontal, 10)
                    Spacer()
                } else {
                    List(selection: $selectedFolderID) {
                        ForEach(folderStore.folders) { folder in
                            Label(folder.name, systemImage: folder.iconName)
                                .foregroundStyle(Color(hex: folder.colorHex))
                                .tag(folder.id)
                                .draggable(folder.id.uuidString)
                                .dropDestination(for: String.self) { values, _ in
                                    guard let value = values.first, let sourceID = UUID(uuidString: value) else { return false }
                                    folderStore.moveFolder(id: sourceID, before: folder.id)
                                    return true
                                }
                                .contextMenu {
                                    Button("Rename…", systemImage: "pencil") {
                                        selectedFolderID = folder.id
                                        renamedFolder = folder.name
                                        showingRenameFolder = true
                                    }
                                    Button(folder.hasDockLauncher ? "Update Dock Icon…" : "Create Dock Icon…", systemImage: "dock.rectangle") {
                                        createDockLauncher(for: folder)
                                    }
                                    Button("Customize Folder…", systemImage: "paintpalette") {
                                        folderForAppearance = folder
                                    }
                                    Button("Delete Folder", systemImage: "trash", role: .destructive) {
                                        folderPendingDeletion = folder
                                    }
                                }
                        }
                        .onMove(perform: folderStore.moveFolders)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 250, max: 320)
    }

    @ViewBuilder
    private var detailView: some View {
        if let folder = selectedFolder {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(folder.name)
                            .font(.largeTitle.bold())
                        .foregroundStyle(Color(hex: folder.colorHex))
                        Text("\(folder.applications.count) apps")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    TextField("Filter this folder", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                    Button("Add Apps", systemImage: "plus") { showingAddApplications = true }
                        .buttonStyle(.borderedProminent)
                }

                if folder.applications.isEmpty {
                    ContentUnavailableView("This folder is empty", systemImage: "square.grid.2x2", description: Text("Add applications to keep them together."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: applicationGridColumns, spacing: 18) {
                        ForEach(filteredApplications(in: folder)) { application in
                            ApplicationTile(application: application, iconSize: CGFloat(folderStore.settings.iconSize), onDrop: { id in
                                guard searchText.isEmpty else { return }
                                folderStore.moveApplication(id: id, before: application.id, in: folder.id)
                            }) {
                                Task {
                                    do {
                                        try await ApplicationLauncherService().launch(application)
                                    } catch {
                                        folderStore.errorMessage = "Could not open \(application.name). \(error.localizedDescription)"
                                    }
                                }
                            }
                            .contextMenu {
                                Button("Find Replacement…", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") {
                                    chooseReplacement(for: application, in: folder)
                                }
                                Button("Remove from Folder", systemImage: "minus.circle", role: .destructive) {
                                    folderStore.removeApplication(id: application.id, from: folder.id)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .padding(28)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack {
                        Button("Settings", systemImage: "gearshape") { showingSettings = true }
                            .help("Settings")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Rename Folder…", systemImage: "pencil") {
                            renamedFolder = folder.name
                            showingRenameFolder = true
                        }
                        Button(folder.hasDockLauncher ? "Update Dock Icon…" : "Create Dock Icon…", systemImage: "dock.rectangle") {
                            createDockLauncher(for: folder)
                        }
                        Button("Customize Folder…", systemImage: "paintpalette") {
                            folderForAppearance = folder
                        }
                        Button("Delete Folder", systemImage: "trash", role: .destructive) {
                            folderPendingDeletion = folder
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .help("Folder actions")
                }
            }
        } else {
            ContentUnavailableView("Select a folder", systemImage: "folder", description: Text("Choose a folder from the sidebar or create one."))
        }
    }

    private func filteredApplications(in folder: DockFolder) -> [ApplicationItem] {
        guard !searchText.isEmpty else { return folder.applications }
        return folder.applications.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func createDockLauncher(for folder: DockFolder) {
        do {
            let url = try FolderLauncherService().createOrUpdate(for: folder)
            folderStore.setDockLauncherEnabled(true, for: folder.id)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            showingDockLauncherHelp = true
        } catch {
            folderStore.errorMessage = error.localizedDescription
        }
    }

    private func renameSelectedFolder() {
        guard let selectedFolderID else { return }
        folderStore.renameFolder(id: selectedFolderID, to: renamedFolder)
        updateDockLauncherIfNeeded(folderID: selectedFolderID)
    }

    private func updateDockLauncherIfNeeded(folderID: UUID) {
        guard let folder = folderStore.folders.first(where: { $0.id == folderID }), folder.hasDockLauncher else { return }
        do { try FolderLauncherService().createOrUpdate(for: folder) }
        catch { folderStore.errorMessage = error.localizedDescription }
    }

    private func chooseReplacement(for application: ApplicationItem, in folder: DockFolder) {
        let panel = NSOpenPanel()
        panel.title = "Find \(application.name)"
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        folderStore.replaceApplication(id: application.id, in: folder.id, with: ApplicationItem(url: url))
    }

    private func deleteFolder(_ folder: DockFolder) {
        if folder.hasDockLauncher {
            do { try FolderLauncherService().remove(for: folder.id) }
            catch { folderStore.errorMessage = "The folder launcher could not be removed. \(error.localizedDescription)"; return }
        }
        folderStore.deleteFolder(id: folder.id)
    }

    private func openFolderURL(_ url: URL) {
        guard let id = DockFolderLink.folderID(from: url),
              folderStore.folders.contains(where: { $0.id == id }) else {
            folderStore.errorMessage = "This DockFolders link is invalid or its folder no longer exists."
            return
        }
        selectedFolderID = id
        PopupWindowManager.shared.present(folderID: id, store: folderStore)
    }
}

private struct FolderAppearanceSheet: View {
    let folder: DockFolder
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var symbol: String
    @State private var hex: String

    private let symbols = ["folder.fill", "briefcase.fill", "hammer.fill", "terminal.fill", "paintbrush.pointed.fill", "graduationcap.fill", "star.fill", "heart.fill", "leaf.fill", "gamecontroller.fill", "music.note", "photo.fill"]
    private let colors = ["#0A84FF", "#30D158", "#FF9F0A", "#FF375F", "#BF5AF2", "#64D2FF", "#8E8E93", "#FFD60A"]

    init(folder: DockFolder, onSave: @escaping (String, String) -> Void) {
        self.folder = folder
        self.onSave = onSave
        _symbol = State(initialValue: folder.iconName)
        _hex = State(initialValue: folder.colorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Customize \(folder.name)").font(.title2.bold())
            Text("Icon").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                ForEach(symbols, id: \.self) { item in
                    Button { symbol = item } label: {
                        Image(systemName: item).font(.title2).frame(maxWidth: .infinity, minHeight: 42)
                            .background(symbol == item ? Color.accentColor.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain).accessibilityLabel(item)
                }
            }
            Text("Color").font(.headline)
            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Button { hex = color } label: {
                        Circle().fill(Color(hex: color)).frame(width: 28, height: 28)
                            .overlay(Circle().stroke(hex == color ? Color.primary : .clear, lineWidth: 2).padding(-3))
                    }.buttonStyle(.plain).accessibilityLabel("Choose color \(color)")
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { onSave(symbol, hex); dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

private extension Color {
    init(hex: String) { self.init(nsColor: NSColor(hex: hex)) }
}

struct ApplicationTile: View {
    let application: ApplicationItem
    var iconSize: CGFloat = 56
    var onDrop: (UUID) -> Void = { _ in }
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                Text(application.name)
                    .font(.callout)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 34)
                if !FileManager.default.fileExists(atPath: application.path) {
                    Label("Unavailable", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
        .draggable(application.id.uuidString)
        .dropDestination(for: String.self) { values, _ in
            guard let value = values.first, let id = UUID(uuidString: value) else { return false }
            onDrop(id)
            return true
        }
        .help("Open \(application.name)")
    }
}

private struct ApplicationPickerSheet: View {
    @Environment(FolderStore.self) private var folderStore
    @Environment(\.dismiss) private var dismiss

    let folderID: UUID
    @State private var applications: [ApplicationItem] = []
    @State private var searchText = ""
    @State private var isLoading = true

    private var filteredApplications: [ApplicationItem] {
        guard !searchText.isEmpty else { return applications }
        return applications.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Applications")
                    .font(.title2.bold())
                Spacer()
                Button("Choose from Disk…", systemImage: "folder") { chooseFromDisk() }
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            TextField("Search installed apps", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.bottom, 8)

            if isLoading {
                ProgressView("Finding applications…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredApplications.isEmpty {
                ContentUnavailableView("No matching apps", systemImage: "magnifyingglass", description: Text("Try a different search or choose an app from disk."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredApplications) { application in
                    HStack(spacing: 12) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                            .resizable()
                            .frame(width: 32, height: 32)
                        Text(application.name)
                        Spacer()
                        if isInFolder(application) {
                            Label("Added", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Add") { folderStore.add(application, to: folderID) }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 3)
                }
                .listStyle(.inset)
            }
        }
        .task {
            applications = await ApplicationDiscoveryService().discoverApplications()
            isLoading = false
        }
    }

    private func isInFolder(_ application: ApplicationItem) -> Bool {
        folderStore.folders.first(where: { $0.id == folderID })?.applications.contains(where: { $0.matches(application) }) ?? false
    }

    private func chooseFromDisk() {
        let panel = NSOpenPanel()
        panel.title = "Choose an Application"
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            folderStore.add(ApplicationItem(url: url), to: folderID)
        }
    }
}
