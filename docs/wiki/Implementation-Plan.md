# MVP implementation plan

## Stage 0 — Environment audit (complete)

- Confirm macOS 27.0.1, arm64, Xcode 27.1, SDK 27.0, Swift 6.4, Git/GitHub access, available space, and development tools.
- Keep beta toolchains out of the project.
- Record audit in `ENVIRONMENT_AUDIT.md` and this Wiki.

## Stage 1 — Project foundation (in progress)

- Create the native Xcode project, scheme, app target, and test target.
- Set macOS 27.0 minimum, arm64, and Swift 6.
- Add contributor instructions, README, changelog, and architecture notes.
- Verify project listing and a clean baseline build.

## Stage 2 — Folder model and persistence

- Codable folder and app-entry models with stable identifiers.
- Atomic JSON persistence under Application Support, with safe error handling.
- Create/rename/delete and reorder folders.
- Unit tests for serialization, ordering, and persistence reload/error paths.

## Stage 3 — Discover, add, and launch apps

- Find `.app` bundles in common app directories off the main thread.
- Search the discovered list; offer a file picker for apps the scan misses.
- Add/remove applications from folders and persist changes.
- Launch through `NSWorkspace`; show recoverable launch errors.
- Test discovery filtering, duplicate membership, persistence, and launch seam.

## Stage 4 — Main interface and activation

- SwiftUI folder navigation and application tiles with native icons.
- Verify the exact Liquid Glass API in the selected SDK and retain a contrast fallback.
- Reopen the main window on repeat activation from the Dock.
- Smoke-test on the local macOS 27 host, including relaunch and app launch.

## MVP release gate

- `xcodebuild -list` reports the app and test schemes.
- macOS scheme builds and test suite passes.
- Manually verify create folder → add app → quit/reopen → launch app.
- Document any unverified multiple-monitor, accessibility, signing, and sandbox behavior.

Stages 2–4 remain incomplete until their code and checks exist. Each completed stage gets a Wiki update, commit, and push.
