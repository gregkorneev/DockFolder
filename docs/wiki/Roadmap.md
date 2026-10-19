# Roadmap
Русская версия: [Roadmap.ru.md](Roadmap.ru.md)


Status: core implementation includes the requested 0.1, 0.2 and 1.0 feature scope. Remaining work is host-specific verification and distribution readiness, not the core feature backlog.

## Version 0.1 — Foundation (implemented)

- Main app, folder CRUD, installed app discovery/search/add/remove/launch.
- Versioned local JSON persistence and error handling.

## Version 0.2 — Dock integration (implemented)

- One launcher `.app` per folder under `/Applications/DockFolders`.
- Validated `dockfolders://folder/<UUID>` routing opens the requested folder.
- Manual Finder smoke check covered running and cold-start cases.
- User manually adds each launcher to Dock through macOS UI; no Dock preference editing.

## Version 1.0 — Core features implemented

- Folder SF Symbol/color customization and folder/app drag ordering.
- Dock-aware Liquid Glass popup with Escape, focus-loss and successful-launch dismissal.
- Grid/icon/theme settings, Control–Option–Space hotkey, `SMAppService` login-start integration, and import/export.
- 16 unit tests pass, including migration, URL validation, launcher bundle, ordering and configuration transfer.

## Remaining release validation

- Multi-display behavior, every Dock edge, hidden Dock and screen changes.
- Accessibility, VoiceOver, keyboard-only workflows, contrast and reduced motion.
- Actual login-start registration, hotkey collisions, and clean-install Dock pin instructions.
- Signing, notarization, sandbox policy, and packaged install/upgrade/uninstall.

See [Implementation Plan](Implementation-Plan.md) and [Testing](Testing.md) for details. Do not mark distribution as release-ready until these checks pass.
