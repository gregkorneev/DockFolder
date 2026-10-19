# DockFolders contributor instructions

## Product and platform

- DockFolders is a native macOS application targeting macOS 27.0+ and Apple Silicon (`arm64`).
- Use Swift 6 language mode, SwiftUI for the interface, and AppKit only where macOS app lifecycle or window behavior requires it.
- Before significant platform changes, verify API availability and compatibility against the selected Xcode and macOS 27 SDK. Do not infer API availability from an API name or an online example.
- Prefer public Apple APIs and system frameworks. Do not use private Dock APIs or modify the system Dock.
- Keep MVP scope at version 0.1. Helper launcher apps, hotkeys, login startup, drag-and-drop, and import/export are later releases unless the user explicitly changes scope.

## Design and implementation

- Keep UI, models, and OS interaction separate. Add a protocol at an OS or persistence seam when it makes behavior testable; avoid generic frameworks and unnecessary layers.
- Persist user folders atomically and preserve existing data on decode/write errors.
- Surface errors to the user; never silently discard a folder or application entry.
- Use structured Swift concurrency and isolate UI state to `MainActor`.
- Keep accessibility labels and keyboard navigation for all controls.
- Do not add third-party dependencies without a concrete need.

## Work and verification

- Follow repository and user instructions before changing files. Work in a Git worktree for implementation; use a `codex/` branch unless the user asks otherwise.
- Make small, coherent commits. Push completed stages to the current branch and report the commit and push status. Do not push directly to `main`.
- Update `docs/wiki/` and `CHANGELOG.md` when a stage changes architecture, behavior, or project status.
- Run `xcodebuild -list` to inspect schemes, then build and test the macOS scheme with `xcodebuild`. Report only checks that were actually run.
- Do not install or update toolchains or dependencies automatically.
- Before release, repeat the toolchain/API compatibility audit.

## Current target

- Minimum deployment target: macOS 27.0.
- Xcode: 27.1; macOS SDK: 27.0; bundled Swift compiler: 6.4.
