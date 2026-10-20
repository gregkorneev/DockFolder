import AppKit
import ApplicationServices
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(FolderStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var transferError: String?
    @State private var loginError: String?
    @State private var draftPresetName = ""
    @State private var draftColumns = 4
    @State private var draftShowsAppLabels = true
    @State private var showingAccessibilityAlert = false

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

            Section("Folder layout presets") {
                Picker("Default for new folders", selection: Binding(
                    get: { store.settings.defaultLayoutPresetID },
                    set: { id in store.updateSettings { $0.defaultLayoutPresetID = id } }
                )) {
                    ForEach(store.settings.layoutPresets) { preset in
                        Text(AppLocalization.layoutPresetName(preset)).tag(preset.id)
                    }
                }
                TextField("Preset name", text: $draftPresetName)
                Picker("Arrangement", selection: $draftColumns) {
                    ForEach(2...12, id: \.self) { columns in
                        Text("\(columns) × \(columns)").tag(columns)
                    }
                    Text("All in one row").tag(FolderLayoutPreset.rowColumns)
                    Text("All in one column").tag(FolderLayoutPreset.columnColumns)
                }
                Toggle("Show app names", isOn: $draftShowsAppLabels)
                Button("Save preset and use for new folders") {
                    let name = draftPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let preset = FolderLayoutPreset(name: name, columns: draftColumns, showsAppLabels: draftShowsAppLabels)
                    store.updateSettings {
                        $0.layoutPresets.append(preset)
                        $0.defaultLayoutPresetID = preset.id
                    }
                    draftPresetName = ""
                }
                .disabled(draftPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Hover to Open") {
                Picker("Open folders", selection: Binding(
                    get: { store.settings.hoverSettings.mode },
                    set: { mode in
                        store.updateSettings { $0.hoverSettings.mode = mode }
                        DockHoverMonitor.shared.settingsDidChange(store: store)
                        if mode.enablesHover { requestAccessibilityIfNeeded() }
                    }
                )) {
                    Text("On click").tag(DockFolderOpeningMode.click)
                    Text("On hover").tag(DockFolderOpeningMode.hover)
                    Text("On click and hover").tag(DockFolderOpeningMode.both)
                }
                Stepper(value: Binding(
                    get: { store.settings.hoverSettings.openDelayMilliseconds },
                    set: { value in store.updateSettings { $0.hoverSettings.openDelayMilliseconds = value } }
                ), in: 80...1_000, step: 20) {
                    Text(verbatim: AppLocalization.format("Open delay: %d ms", store.settings.hoverSettings.openDelayMilliseconds))
                }
                Stepper(value: Binding(
                    get: { store.settings.hoverSettings.closeDelayMilliseconds },
                    set: { value in store.updateSettings { $0.hoverSettings.closeDelayMilliseconds = value } }
                ), in: 80...1_000, step: 20) {
                    Text(verbatim: AppLocalization.format("Close delay: %d ms", store.settings.hoverSettings.closeDelayMilliseconds))
                }
                Text("Hover opening requires Accessibility access so DockFolders can identify its launcher under the pointer. Click opening works without it.")
                    .font(.caption).foregroundStyle(.secondary)
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
        .frame(width: 480, height: 760)
        .alert("Accessibility access needed", isPresented: $showingAccessibilityAlert) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("Allow DockFolders in System Settings → Privacy & Security → Accessibility, then restart DockFolders. The app needs this permission to identify its Dock icon under the pointer. No screen recording or input monitoring permission is used.")
        }
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

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        showingAccessibilityAlert = true
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
