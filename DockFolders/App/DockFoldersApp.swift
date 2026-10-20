import SwiftUI

@main
struct DockFoldersApp: App {
    @NSApplicationDelegateAdaptor(DockIntegrationManager.self) private var dockIntegration

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(dockIntegration.folderStore)
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("Show Welcome Guide…") {
                    dockIntegration.showWelcome()
                }
            }
        }
    }
}

struct WelcomeView: View {
    let onComplete: () -> Void
    @State private var page = 0

    private let pages: [(symbol: String, title: LocalizedStringKey, detail: LocalizedStringKey)] = [
        ("square.grid.2x2.fill", "Welcome to DockFolders", "Keep your favorite apps together in folders you can open from the Dock."),
        ("folder.badge.plus", "Create your first folder", "Create a folder in the manager, add apps, and arrange them in the order you want."),
        ("dock.rectangle", "Pin its launcher", "Create a launcher for the folder, then drag that launcher to the Dock. macOS keeps it there when DockFolders is closed."),
        ("hand.point.up.left.fill", "Open and customize", "Click the Dock launcher to open your folder. Enable hover opening in Settings if you prefer. Use the grid button to adjust the layout and the gear to return to the manager.")
    ]

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: pages[page].symbol)
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(.tint)
                .frame(height: 80)
                .accessibilityHidden(true)
            Text(pages[page].title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(pages[page].detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
                .frame(minHeight: 70, alignment: .top)
            Text(verbatim: "\(page + 1) / \(pages.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                }
                Spacer()
                Button(page == pages.count - 1 ? "Get Started" : "Next") {
                    if page == pages.count - 1 { onComplete() }
                    else { page += 1 }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .frame(width: 520, height: 390)
    }
}
