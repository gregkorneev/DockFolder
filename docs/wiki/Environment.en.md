# Development environment

Last checked: **2026-10-20**. The detailed audit is in [ENVIRONMENT_AUDIT.md](../../ENVIRONMENT_AUDIT.md).

## Status

**READY**: Xcode 27.1 and macOS SDK 27 are available, the license is accepted, and `xcodebuild` works. The project can be built and tested.

## Verified local environment

- macOS 27.0.1 (26A434), Apple Silicon arm64.
- Xcode 27.1 (27A9275) at `/Applications/Xcode.app`; active Developer Directory: `/Applications/Xcode.app/Contents/Developer`.
- macOS SDK 27.0; Command Line Tools 27.0.
- Apple Swift 6.4 and SwiftPM 6.4.0-dev from the selected Xcode toolchain.
- Git 2.54.0, GitHub CLI 2.96.0 (authenticated), Homebrew 7.0.9, Codex CLI 0.142.5.
- 84 GiB free; `/usr/bin/codesign` is available.
- The repository and its GitHub history changed after the initial audit. Check Git/remote/push state before publishing rather than treating this historical status as current.

## Follow-up

Recheck Xcode and SDK compatibility before moving to the next platform version and before release.

## Latest stable versions checked

- Xcode 27.1 stable; 27.2 beta 3 is a prerelease.
- Swift 6.4 stable release line; the official catalog lists 6.4.1 as stable.
- Git 2.56.0, GitHub CLI 2.102.0, Homebrew 7.0.10, Codex CLI rust-v0.163.0.

Official sources and installed-version comparisons are listed in [ENVIRONMENT_AUDIT.md](../../ENVIRONMENT_AUDIT.md).

Русская версия: [Environment.md](Environment.md).
