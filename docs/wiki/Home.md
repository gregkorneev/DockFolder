# DockFolders Wiki

Русская версия Wiki: [Home.ru.md](Home.ru.md).
Русская версия: [Home.ru.md](Home.ru.md)


DockFolders is a native macOS application for grouping installed apps into user-defined folders and opening them from macOS Dock launchers.

## Languages

The interface is available in English and Russian. DockFolders follows the preferred language configured in macOS. Russian folder app counts use the correct plural forms.

## Current status

- **Implemented:** core version 1.0 feature scope: folder CRUD/customization/order, app discovery/search/add/remove/launch/order, Dock-aware popup, generated per-folder launchers, configurable grid/theme, hotkey preference, login-start preference, and import/export.
- **Verified:** 23 unit tests; manual launcher test through Finder successfully opened the Code folder while DockFolders was running and after cold-start.
- **Unverified:** multi-display and all Dock-edge behavior, accessibility/reduced motion, actual login-start registration, hotkey conflicts, signing/notarization/sandbox/distribution, and user pinning flow on a clean install.
- **Dock pinning:** each generated launcher must be added by the user through macOS Dock controls. DockFolders will not edit Dock preferences or use private APIs.
- **Launcher icon sizing:** per-folder launchers use a standard multi-resolution `.icns` app icon; macOS controls Dock tile size and magnification globally in Desktop & Dock settings.

## Pages

- [Architecture](Architecture.md)
- [Project structure](Project-Structure.md)
- [Development guide](Development-Guide.md)
- [Components](Components.md)
- [Dock integration](Dock-Integration.md)
- [UI design](UI-Design.md)
- [SF Symbols catalog and usage](SF-Symbols.md)
- [App icon](App-Icon.md)
- [Data models](Data-Models.md)
- [Testing](Testing.md)
- [Git workflow](Git-Workflow.md)
- [Roadmap](Roadmap.md)
- [Known issues](Known-Issues.md)
- [Decisions](Decisions.md)
- [Changelog](Changelog.md)
- [Environment](Environment.md)
- [Implementation plan and acceptance criteria](Implementation-Plan.md)

The source of truth for project documentation is `docs/wiki/` in this repository. The GitHub Wiki, if published, is a copy of these files.
