import SwiftUI

@main
struct DockFoldersApp: App {
    @NSApplicationDelegateAdaptor(DockIntegrationManager.self) private var dockIntegration
    @State private var folderStore = FolderStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(folderStore)
                .frame(minWidth: 760, minHeight: 520)
        }
        .windowStyle(.automatic)
        .restorationBehavior(.disabled)
    }
}
