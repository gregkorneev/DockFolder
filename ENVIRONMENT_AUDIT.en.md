# Environment audit

**Date:** 2026-10-20 (Europe/Moscow)  
**Project:** DockFolders  
**Overall status:** **READY**

The audit used diagnostic commands only. No software or dependencies were installed or updated, and no system configuration or source code was changed.

## Version summary

| Component | Installed version | Latest stable version | Compatibility / status |
|---|---|---|---|
| macOS | 27.0.1 (26A434), arm64 | 27.0.1 | Meets the macOS 27 target; up to date |
| Xcode | 27.1 (27A9275), `/Applications/Xcode.app` | Xcode 27.1; 27.2 beta 3 is prerelease | Launches, macOS 27 SDK available, license accepted; up to date |
| Xcode Command Line Tools | 27.0.0.0.1788430756 | 27.0.x (latest stable patch not separately verified) | Available, but not a substitute for full Xcode for this app; version not verified |
| macOS SDK | 27.0 from Xcode | SDK 27 bundled with Xcode 27.1 | Confirmed by `xcodebuild -showsdks` and `xcrun`; up to date |
| Swift | Apple Swift 6.4 (swiftlang-6.4.0.34.1), from Xcode 27.1 | Swift 6.4 stable toolchain bundled with Xcode 27.1 | Swift 6 and arm64 macOS 27 are available; up to date |
| Swift Package Manager | 6.4.0-dev (bundled SwiftPM) | SwiftPM bundled with Xcode 27.1 | Available; SwiftPM reports a dev version, while the bundled Apple compiler is 6.4; ready |
| Git | 2.54.0 (Apple Git-157) | 2.56.0 | Local Git works; a newer stable release is available; update available |
| GitHub CLI | 2.96.0 | 2.102.0 | github.com authentication succeeded, Git uses SSH; update available |
| Homebrew | 7.0.9 | 7.0.10 | Installed; update available, optional |
| Codex CLI | 0.142.5 | rust-v0.163.0 (latest official release) | Installed; work is performed in Codex Desktop, so CLI update is not required for this audit |
| `codesign` | `/usr/bin/codesign` (version not separately reported) | Apple system tool; no separate release number applies | Present; app signing was not checked |
| GitHub remote | `git@github.com:gregkorneev/DockFolder.git` | N/A | Read and push were verified during the audit; remote state is historical |
| Git state | At audit time, base commit was in `main` and work was in `codex/dockfolders-mvp` | N/A | GitHub Wiki enabled; see current repository state before relying on this snapshot |
| Xcode test tooling | `xcodebuild` from Xcode 27.1 | Bundled with Xcode 27.1 | Available after first launch; Simulator runtime absent, but macOS-host builds/tests work |
| Multi-agent tooling | Codex Desktop and delegation tools | N/A | Availability confirmed; delegation was not used for that audit |
| Free disk space | 112 GiB of 460 GiB (repeat measurement on 2026-10-20) | N/A | Sufficient for Xcode and build artifacts |

Swift.org reports the Swift 6.4 stable line, and its official install catalog lists 6.4.1 as the current stable release (as of 2026-10-20). For macOS development, prefer the Swift toolchain bundled with Xcode rather than installing a separate toolchain.

## Critical findings

- Xcode 27.1 is installed at `/Applications/Xcode.app` and selected as the active Developer Directory at `/Applications/Xcode.app/Contents/Developer`.
- Xcode 27.1, SDK 27.0, and `xcodebuild` were confirmed after first launch and license acceptance.
- Local and remote `main` contained the base audit commit at the time of the audit.

## Non-critical findings

- Git, GitHub CLI, Homebrew, and Codex CLI were behind the latest stable releases found. They do not block local app builds.
- The computer runs macOS 27.0.1 on Apple Silicon, matching the macOS 27 / arm64 minimum target.
- `/usr/bin/codesign` is present, but signing certificates, entitlements, and App Sandbox permissions were not checked.
- Liquid Glass, `NSPanel`, `NSWindow`, `NSWorkspace`, ServiceManagement, and IPC APIs had not yet been validated against the local Xcode SDK at the time; API availability was not inferred from symbol names.

## Tools and repository

- `sw_vers`: macOS 27.0.1, build 26A434.
- `uname -m`: arm64.
- `xcode-select -p`: `/Applications/Xcode.app/Contents/Developer`.
- `xcodebuild -version`: Xcode 27.1 (27A9275).
- `xcodebuild -showsdks`: macOS SDK 27.0 available.
- `xcrun --sdk macosx --show-sdk-version`: 27.0.
- `swift --version`: Apple Swift 6.4.0-dev, target `arm64-apple-macosx27.0.0`.
- `swift package --version`: Swift Package Manager 6.4.0-dev.
- `git status`: clean `main` branch synchronized with `origin/main` at the time of the audit.
- `git remote -v`: SSH remote `gregkorneev/DockFolder`; audit push completed.
- `gh auth status`: authenticated to `github.com` as `gregkorneev`, Git over SSH, `repo` scope.
- GitHub reported that Wiki was enabled. CI/CD and remote Wiki contents were not inspected at that time.
- Free space was 112 GiB after Xcode installation; the pre-installation measurement was 84 GiB.

## Latest versions checked online

| Component | Latest stable version | Source |
|---|---|---|
| macOS | 27.0.1 | [Apple Developer Releases](https://developer.apple.com/news/releases/) |
| Xcode | 27.1 (27A9275), 2026-10-15; latest beta Xcode 27.2 beta 3 | [Xcode 27.1 release](https://developer.apple.com/news/releases/?id=10152026a), [Xcode Release Notes](https://developer.apple.com/documentation/xcode-release-notes) |
| Swift | 6.4.1 stable (official release catalog); 6.4 announced as stable | [Swift 6.4 announcement](https://www.swift.org/blog/swift-6.4-released/), [Swift install for macOS](https://www.swift.org/install/macos/) |
| Git | 2.56.0 | [git-scm.com](https://git-scm.com/) |
| GitHub CLI | v2.102.0 (2026-09-30) | [GitHub CLI releases](https://github.com/cli/cli/releases) |
| Homebrew | 7.0.10 (2026-10-19) | [Homebrew release](https://github.com/Homebrew/brew/releases/tag/7.0.10) |
| Codex CLI | rust-v0.163.0 (2026-10-15) | [OpenAI Codex releases](https://github.com/openai/codex/releases) |

Apple's release page listed Xcode 27.2 beta 3 as a newer prerelease; it was not recommended for production use under the project requirements. No installation or update commands were run.

## Recommended actions

1. Recheck Xcode and SDK compatibility before moving to the next platform version and before release.
2. Use the Swift toolchain bundled with Xcode; do not install a separate toolchain.
3. Do not install a separate Swift toolchain while the Xcode bundle meets project requirements.

## MVP implementation and checks recorded in the audit

- The project and Xcode scheme were configured; `xcodebuild -list` found app and test targets.
- macOS build succeeded with Xcode 27.1 / SDK 27.0.
- All 8 unit tests passed at that audit stage: folder operations, JSON persistence and data preservation on error, application search, duplicates, and launch errors.
- Manual UI checks confirmed folder creation, app search/add, launching Calculator, and restoring a folder after DockFolders restarted.
- Code was pushed to `codex/dockfolders-mvp`; production signing and App Sandbox were not configured.

## Scenarios not verified at that time

- Reopening the window by clicking the Dock icon was implemented and built, but not manually checked.
- Multiple displays, detailed accessibility, production signing, and sandbox/distribution policy remained for a later stage.

Русская версия: [ENVIRONMENT_AUDIT.md](ENVIRONMENT_AUDIT.md).

## Beta 2 release compatibility audit — 2026-10-20

- Host: macOS 27.0.1. Selected Xcode 27.1 (27A9275), macOS SDK 27.0, bundled Swift compiler 6.4 in Swift 6 language mode. `xcodebuild -list` found the DockFolders scheme, and a clean Release build succeeded for Apple Silicon.
- The Release bundle reports version 1.0 (build 2), minimum macOS 27.0, and an arm64 executable. Its imported modules and linked frameworks are public system APIs; the release source scan found no private Dock or window-server API identifiers. A successful build against the selected SDK confirms the referenced API symbols compile here, not behavior on every macOS configuration.
- The ad-hoc signature passed `codesign --verify --deep --strict`. There is no valid Developer ID signing identity on this host. The app and DMG are not notarized.
- All 34 tests passed in Debug. A Release test invocation could not import the non-testable Release app module; a separate clean Release build passed. The DMG passed `hdiutil verify`, and its mounted app passed strict signature verification. Clean installation, upgrade, Gatekeeper handling, and notarization were not exercised.
