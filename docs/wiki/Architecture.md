# Architecture
Русская версия: [Architecture.ru.md](Architecture.ru.md)


## Current implementation

- **Platform:** macOS 27.0+, Apple Silicon, Swift 6, Xcode 27.1 / SDK 27.
- **App shape:** main foreground application plus a generated app bundle named after each folder under `/Applications/DockFolders` (a numeric suffix resolves duplicate names). Renaming updates the bundle name while preserving its validated `dockfolders://folder/<UUID>` route. The user, not DockFolders, pins each launcher in Dock.
- **UI:** SwiftUI owns folder management/settings and app-grid state. AppKit `NSPanel` provides a Dock-aware popup which dismisses on Escape, focus loss, and successful app launch. AppKit also handles the lifecycle and app launching.
- **Data:** Codable folder records and settings are stored locally as versioned JSON. Writes are atomic. Version 0.1 folder JSON migrates to the expanded model; decode/import errors preserve the user's existing data.
- **Application entries:** store stable IDs, display names, bundle identifiers when available, and a path fallback. Do not serialize `NSImage` or other transient framework objects.
- **Discovery:** scan common app folders (`/Applications`, `/System/Applications`, `~/Applications`) off the main thread, recursively through four directory levels, and provide an explicit app picker. Skip hidden paths and package descendants; filter `.app` bundles and deduplicate by standardized URL. Deeper folders and removable volumes are not scanned.
- **Launch:** use public `NSWorkspace` app-opening APIs and report failure when an app was removed or moved.
- **Preferences:** folder icon/color/order, app order and each folder's layout, grid columns, icon size, and glass transparency are persisted per folder. Theme, named layout presets, hotkey preference, and login-start preference remain app-wide. OS registration status is distinct from saved preference.
- **Integrations:** generated launchers route through validated custom URL links; global hotkey uses Carbon Control–Option–Space; login startup uses `SMAppService`. Collision and actual OS registration cases remain unverified.
- **Persistence:** a narrow repository protocol keeps JSON I/O replaceable in unit tests. Other protocols are introduced only at OS seams that need test doubles.
- **Distribution:** MVP is a local development build without App Sandbox so it can discover and open installed applications. App Store sandboxing, security-scoped bookmarks, and signing/distribution policy require a separate decision before any release.
- **Liquid Glass:** `.glassEffect` compiles against the selected macOS 27 SDK and is used in the popup/app grid.

## Remaining validation and work

- Validate popup geometry across multiple displays and every Dock edge, including hidden/repositioned Dock and display changes.
- Verify VoiceOver, keyboard-only use, reduced motion, and contrast.
- Verify ServiceManagement login-start registration and removal on the target host; verify hotkey conflict behavior.
- Decide signing, notarization, sandboxing, and distribution. The current local development build is not a verified release package.
- Verify unavailable app repair/relink behavior and launcher cleanup/stale Dock shortcut messaging.

## Main components

- `DockFoldersApp`: app entry and reopen lifecycle.
- `Models`: folder and application-entry values.
- `ViewModels`: observable folder state and application search.
- `Views`: folder list, folder contents, app picker/grid, popup, and settings surfaces.
- `Services`: application discovery/launch, persistence, generated launcher, and configuration transfer.
- `Managers`: popup/Dock activation, global hotkey, and login-start integrations.
- `Utilities`: shared small helpers, not a general-purpose framework.
- `DockFoldersTests`: model, persistence, and view-model/service tests.

## Dock integration

See [Dock-Integration.md](Dock-Integration.md) for the user-action constraint and launcher plan.

## Verification

- macOS build succeeds with Xcode 27.1 / SDK 27.0.
- Twenty-five unit tests pass, including adaptive popup sizing and popup placement calculations for bottom/left/right Dock layouts and fallback placement when no Dock inset is reported.
- Manual smoke check opened a generated launcher through Finder, verified it opened the selected Code folder while DockFolders was already open and after cold-start.
- Actual popup placement on multiple physical displays, accessibility/reduced motion, ServiceManagement registration, hotkey collision, production signing, and sandbox distribution remain unverified.

## Hover to Open

`DockHoverMonitor` listens to global and local `NSEvent.mouseMoved` notifications, then uses the public Accessibility hit-test API to identify the Dock item. It maps the item's bundle identifier to the folder UUID and reuses `PopupWindowManager`; no Dock preferences or private APIs are used. Settings default to click-only. Hover modes have adjustable open/close delays and request Accessibility permission only; the monitor caps hit-testing to about 30 Hz during pointer movement and provides an adaptive slow-at-rest fallback only if event monitors cannot be installed. On macOS 27, the pinned Code launcher was manually verified end to end: hover opens the folder, pointer transfer keeps it open, and leaving closes it. Multi-display and alternate Dock configurations still need host verification.
