# Components
Русская версия: [Components.ru.md]


This page describes the delivered implementation and remaining verification gaps.

## Implemented

- `DockFoldersApp`: creates the app and injects folder/settings state.
- `DockFolder` and `ApplicationItem`: Codable folder and app values with customization and ordering metadata.
- `FolderStore`: main-actor state, folder/app CRUD and reorder operations, persistence, migration, and surfaced errors.
- `FolderPersistenceService`: versioned JSON document in Application Support, atomic writes, guarded unsupported/corrupt-data handling.
- `ApplicationDiscoveryService`: asynchronous discovery in common app locations and app-picker support.
- `ApplicationLauncherService`: launches an app through `NSWorkspace` and reports failures.
- `ContentView`: folder customization, ordering, app search/add/remove/reorder, grid/theme settings, popup, and import/export flows.
- `PopupWindowManager`: Dock-aware panel presentation and dismissal on Escape, focus loss, and successful launch.
- Launcher generation and URL routing: one `.app` per folder in `/Applications/DockFolders`, with validated `dockfolders://folder/<UUID>` requests.
- `HotkeyManager`: global Control–Option–Space shortcut.
- Login startup integration: `SMAppService`.
- Configuration transfer: import/export with validation.

## Remaining verification

The code paths exist; behavior still requiring machine-level verification includes popup positioning on multiple monitors and all Dock edges, accessibility/reduced motion, successful ServiceManagement registration, global hotkey collision handling, and packaged distribution.
