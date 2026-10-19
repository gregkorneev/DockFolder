# Development guide
Русская версия: [Development-Guide.ru.md]


## Requirements

Use Xcode and the macOS 27 SDK, Swift 6 language mode, SwiftUI and public AppKit APIs. See [Environment](Environment.md) for the recorded host audit and [README](../../README.md) for build commands.

## Workflow

1. Read [Architecture](Architecture.md), [Decisions](Decisions.md), and the affected component page before changing behavior.
2. Keep model, UI and OS integrations separated. Add protocol seams where they improve testability.
3. Implement one small, reviewable roadmap increment at a time.
4. Add/update tests for meaningful behavior and manually verify OS-level window behavior where automation cannot prove it.
5. Update the relevant wiki page, [Roadmap](Roadmap.md), [Known Issues](Known-Issues.md), and changelog status.
6. Build/test using the Xcode scheme and report what was actually verified.

## Platform rules

- Use public APIs and verify them against the selected SDK.
- Do not modify Dock preferences or automate user interaction with the Dock.
- Keep persisted data migration-safe and preserve data when reads/imports fail.
- Surface unavailable applications and OS registration failures to the user.
- Keep all interactive controls keyboard-accessible and labelled.
- Do not install or update toolchains/dependencies automatically.

## Current versus planned

Current code includes per-folder launchers, popup, folder customization/order, settings, hotkey, login-start integration, drag-and-drop, and import/export. Remaining release validation is listed in [Implementation Plan](Implementation-Plan.md) and [Testing](Testing.md). Do not claim success for machine-specific behavior unless it was verified on that host.
