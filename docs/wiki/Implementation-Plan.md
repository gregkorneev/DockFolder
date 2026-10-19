# Implementation status and acceptance
Русская версия: [Implementation-Plan.ru.md](Implementation-Plan.ru.md)


Last reconciled: 2026-10-20 using the current implementation and recorded verification report.

## Implemented feature scope

- Version 0.1 foundation: native macOS app, folder CRUD, installed-app discovery/search/add/remove/launch, and versioned local persistence.
- Version 0.2 Dock integration: per-folder launcher `.app` bundles in `/Applications/DockFolders`, validated `dockfolders://folder/<UUID>` routing, and folder selection from the launcher.
- Version 1.0 features: folder SF Symbol/color customization; searchable symbol categories, custom and preset backgrounds for Dock icons, and a square 1024 × 1024 px launcher icon source at 2× resolution (512 pt); folder and app drag ordering; Dock-aware Liquid Glass panel; Escape/focus-loss/successful-launch dismissal; grid, icon size and theme settings; Control–Option–Space hotkey; login-start setting using `SMAppService`; configuration import/export.
- Data migration from the former JSON shape, launcher bundle creation, URL validation, ordering, and configuration transfer have unit coverage.

## Recorded verification

- 20 unit tests pass.
- A generated launcher was opened through Finder. It opened the Code folder while DockFolders was running and after a cold start.
- See [Testing](Testing.md) for the detailed scope and verification gaps.

## Remaining acceptance checks

### Platform and popup

- Verify popup placement and screen clamping on multiple displays, all Dock edges, hidden/auto-hide Dock, and display attach/detach or resolution changes.
- Verify VoiceOver, keyboard-only operation, Dynamic Type/text sizing, contrast, and reduced motion.
- Verify repeated main-app Dock activation and popup behavior after app termination/reopen.

### System integrations

- Confirm login-start registration and removal actually succeed on the target host and survive restart; check permission/error reporting.
- Confirm global hotkey collision behavior and unregister/re-register flows.
- Test generated launcher refresh/removal, renamed/deleted folders, stale Dock shortcuts, and a clean user install.
- Dock pinning is intentionally a user step: open the generated app and choose **Options → Keep in Dock**. Confirm the setup instructions are clear on a clean install.

### Distribution

- Choose and verify signing/notarization and sandbox policy for the distribution route.
- Test install/upgrade/uninstall of the packaged main app and generated launchers outside Xcode.
- Validate application discovery/launch permissions and IPC under the chosen distribution configuration.

## Completion rule

Core requested features are implemented, but release readiness is not claimed until the remaining checks above are completed and documented. Report implementation status separately from host-specific or distribution verification.
