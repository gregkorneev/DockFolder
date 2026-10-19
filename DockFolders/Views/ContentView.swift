import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(FolderStore.self) private var folderStore
    @State private var selectedFolderID: UUID?
    @State private var showingCreateFolder = false
    @State private var showingRenameFolder = false
    @State private var showingAddApplications = false
    @State private var newFolderName = ""
    @State private var renamedFolder = ""
    @State private var searchText = ""

    private var selectedFolder: DockFolder? {
        folderStore.folders.first { $0.id == selectedFolderID }
    }

    var body: some View {
        NavigationSplitView {
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
                            Label(folder.name, systemImage: "folder")
                                .tag(folder.id)
                                .contextMenu {
                                    Button("Rename…", systemImage: "pencil") {
                                        selectedFolderID = folder.id
                                        renamedFolder = folder.name
                                        showingRenameFolder = true
                                    }
                                    Button("Delete Folder", systemImage: "trash", role: .destructive) {
                                        folderStore.deleteFolder(id: folder.id)
                                    }
                                }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 250, max: 320)
        } detail: {
            detailView
        }
        .background(.ultraThinMaterial)
        .onAppear {
            if selectedFolderID == nil { selectedFolderID = folderStore.folders.first?.id }
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
            Button("Save") {
                if let selectedFolderID { folderStore.renameFolder(id: selectedFolderID, to: renamedFolder) }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("DockFolders", isPresented: Binding(
            get: { folderStore.errorMessage != nil },
            set: { if !$0 { folderStore.clearError() } }
        )) {
            Button("OK", role: .cancel) { folderStore.clearError() }
        } message: {
            Text(folderStore.errorMessage ?? "An unexpected error occurred.")
        }
        .sheet(isPresented: $showingAddApplications) {
            if let selectedFolderID {
                ApplicationPickerSheet(folderID: selectedFolderID)
                    .environment(folderStore)
                    .frame(minWidth: 560, minHeight: 480)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let folder = selectedFolder {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(folder.name)
                            .font(.largeTitle.bold())
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 18)], spacing: 18) {
                        ForEach(filteredApplications(in: folder)) { application in
                            ApplicationTile(application: application) {
                                Task {
                                    do {
                                        try await ApplicationLauncherService().launch(application)
                                    } catch {
                                        folderStore.errorMessage = "Could not open \(application.name). \(error.localizedDescription)"
                                    }
                                }
                            }
                            .contextMenu {
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
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Rename Folder…", systemImage: "pencil") {
                            renamedFolder = folder.name
                            showingRenameFolder = true
                        }
                        Button("Delete Folder", systemImage: "trash", role: .destructive) {
                            folderStore.deleteFolder(id: folder.id)
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
}

private struct ApplicationTile: View {
    let application: ApplicationItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                Text(application.name)
                    .font(.callout)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 34)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
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
