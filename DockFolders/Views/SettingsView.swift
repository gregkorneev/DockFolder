import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(FolderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var transferError: String?
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { store.settings.appearance },
                    set: { value in store.updateSettings { $0.appearance = value } }
                )) {
                    Text("System").tag(AppearanceMode.system)
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                }
                Slider(value: Binding(
                    get: { store.settings.iconSize },
                    set: { value in store.updateSettings { $0.iconSize = value } }
                ), in: 36...128, step: 4) {
                    Text("App icon size")
                } minimumValueLabel: { Text("Small") } maximumValueLabel: { Text("Large") }
                Stepper(value: Binding(
                    get: { store.settings.gridColumns },
                    set: { value in store.updateSettings { $0.gridColumns = value } }
                ), in: 0...12) {
                    Text(verbatim: AppLocalization.gridColumns(store.settings.gridColumns))
                }
            }

            Section("Startup") {
                Toggle("Launch DockFolders at login", isOn: Binding(
                    get: { LaunchAtLoginService().isEnabled },
                    set: { enabled in
                        do {
                            try LaunchAtLoginService().setEnabled(enabled)
                            store.updateSettings { $0.launchAtLogin = enabled }
                            loginError = nil
                        } catch {
                            loginError = error.localizedDescription
                        }
                    }
                ))
                if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }
                Toggle("Global shortcut (Control–Option–Space)", isOn: Binding(
                    get: { store.settings.globalShortcutEnabled },
                    set: { enabled in
                        do {
                            if enabled { try GlobalShortcutService.shared.enable() }
                            else { GlobalShortcutService.shared.disable() }
                            store.updateSettings { $0.globalShortcutEnabled = enabled }
                            loginError = nil
                        } catch { loginError = error.localizedDescription }
                    }
                ))
            }

            Section("Configuration") {
                HStack {
                    Button("Export…", systemImage: "square.and.arrow.up") { exportConfiguration() }
                    Button("Import…", systemImage: "square.and.arrow.down") { importConfiguration() }
                }
                Text("Import replaces the current folders and settings after the file is validated.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let transferError {
                Section { Text(transferError).foregroundStyle(.red) }
            }

            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .padding(18)
        .frame(width: 480, height: 510)
    }

    private func exportConfiguration() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "DockFolders-configuration.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ConfigurationTransferService().export(FolderDocument(folders: store.folders, settings: store.settings), to: url)
            transferError = nil
        } catch { transferError = error.localizedDescription }
    }

    private func importConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let document = try ConfigurationTransferService().import(from: url)
            store.replaceConfiguration(with: document)
            guard store.errorMessage == nil else {
                transferError = store.errorMessage
                return
            }
            try LaunchAtLoginService().setEnabled(document.settings.launchAtLogin)
            if document.settings.globalShortcutEnabled { try GlobalShortcutService.shared.enable() }
            else { GlobalShortcutService.shared.disable() }
            for folder in store.folders where folder.hasDockLauncher {
                try FolderLauncherService().createOrUpdate(for: folder)
            }
            transferError = nil
        } catch { transferError = error.localizedDescription }
    }
}
