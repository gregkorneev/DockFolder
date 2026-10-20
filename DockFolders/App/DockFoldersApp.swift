import SwiftUI

@main
struct DockFoldersApp: App {
    @NSApplicationDelegateAdaptor(DockIntegrationManager.self) private var dockIntegration

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(dockIntegration.folderStore)
        }
    }
}
