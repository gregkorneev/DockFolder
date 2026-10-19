# MVP implementation plan

## Stage 0 — Environment audit (complete)

- Confirm macOS 27.0.1, arm64, Xcode 27.1, SDK 27.0, Swift 6.4, Git/GitHub access, available space, and development tools.
- Keep beta toolchains out of the project.
- Record audit in `ENVIRONMENT_AUDIT.md` and this Wiki.

## Stage 1 — Project foundation (complete)

- Create the native Xcode project, scheme, app target, and test target.
- Set macOS 27.0 minimum, arm64, and Swift 6.
- Add contributor instructions, README, changelog, and architecture notes.
- Verify project listing and a clean baseline build.

## Stage 2 — Folder model and persistence (complete)

- Codable folder and app-entry models with stable identifiers.
- Atomic JSON persistence under Application Support, with safe error handling.
- Create/rename/delete folders. Drag reordering is deferred.
- Unit tests cover serialization, persistence reload, corrupt data, and unsupported schema versions.

## Stage 3 — Discover, add, and launch apps (complete)

- Find `.app` bundles in common app directories off the main thread.
- Search the discovered list; offer a file picker for apps the scan misses.
- Add/remove applications from folders and persist changes.
- Launch through `NSWorkspace`; show recoverable launch errors.
- Test discovery filtering, duplicate membership, persistence, and launch seam.

## Stage 4 — Main interface and activation (MVP complete)

- SwiftUI folder navigation and application tiles with native icons.
- Verify the exact Liquid Glass API in the selected SDK and retain a contrast fallback.
- Implement `applicationShouldHandleReopen` to restore the main window on repeat activation from the Dock.
- Smoke-test on the local macOS 27 host, including app relaunch and app launch. Repeat Dock activation has not been manually checked.

## MVP release gate

- `xcodebuild -list` reports the app and test schemes.
- macOS scheme builds and test suite passes.
- `xcodebuild -list` reports the app and test targets; macOS build succeeds; all eight unit tests pass.
- UI smoke check verified folder creation, app search/add, Calculator launch, and persistence after relaunch.
- Document unverified repeated Dock activation, multiple-monitor, accessibility, signing, and sandbox behavior.

Stages 0–4 are complete for the MVP scope. Drag reordering and separate per-folder Dock launchers remain follow-up work.
