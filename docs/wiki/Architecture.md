# Architecture

## MVP decisions

- **Platform:** macOS 27.0+, Apple Silicon, Swift 6, Xcode 27.1 / SDK 27.
- **App shape:** one regular foreground application with one Dock icon (integration Stage A). The first version opens a standard app window; it does not insert controls into or alter the system Dock.
- **UI:** SwiftUI owns folder management and application-grid state. AppKit is kept at the lifecycle boundary for Dock reopen behavior and application launching.
- **Data:** Codable folder records are stored as a versioned JSON document in the user's Application Support directory. Writes are atomic. Decode and file errors must be surfaced without replacing the user's existing data.
- **Application entries:** store stable IDs, display names, bundle identifiers when available, and a path fallback. Do not serialize `NSImage` or other transient framework objects.
- **Discovery:** scan common app folders (`/Applications`, `/System/Applications`, `~/Applications`) off the main thread, recursively through four directory levels, and provide an explicit app picker. Skip hidden paths and package descendants; filter `.app` bundles and deduplicate by standardized URL. Deeper folders and removable volumes are not scanned.
- **Launch:** use public `NSWorkspace` app-opening APIs and report failure when an app was removed or moved.
- **Persistence:** a narrow repository protocol keeps JSON I/O replaceable in unit tests. Other protocols are introduced only at OS seams that need test doubles.
- **Distribution:** MVP is a local development build without App Sandbox so it can discover and open installed applications. App Store sandboxing, security-scoped bookmarks, and signing/distribution policy require a separate decision before any release.
- **Liquid Glass:** `.glassEffect` compiles against the selected macOS 27 SDK; retain readable system materials and contrast fallback.

## Main components

- `DockFoldersApp`: app entry and reopen lifecycle.
- `Models`: folder and application-entry values.
- `ViewModels`: observable folder state and application search.
- `Views`: folder list, folder contents, add-app flow, and settings entry point.
- `Services`: application discovery, launching, and folder persistence.
- `Managers`: only app/window lifecycle coordination that cannot live in a view model.
- `Utilities`: shared small helpers, not a general-purpose framework.
- `DockFoldersTests`: model, persistence, and view-model/service tests.

## Later Dock integration

Separate per-folder launcher apps and XPC/URL-scheme messaging are out of MVP scope. See [Dock-Integration.md](Dock-Integration.md).

## Verification

- macOS build succeeds with Xcode 27.1 / SDK 27.0.
- Eight unit tests pass for persistence, folder operations, corrupt/unsupported data preservation, app discovery, duplicate prevention, and launch errors.
- Local UI smoke check passed: create folder, find and add apps, launch Calculator, and confirm the folder survives app relaunch.
- Repeated Dock activation, multiple displays, production signing, and sandbox distribution remain unverified.
