# Known issues and verification gaps
Русская версия: [Known-Issues.ru.md](Known-Issues.ru.md)


Last reviewed: 2026-10-20.

## Remaining product limitations / unverified behavior

- Users must manually pin each generated folder launcher to Dock using macOS controls.
- Popup geometry has not been validated on multiple displays, all Dock edges, hidden Dock, or after display configuration changes.
- VoiceOver, keyboard-only accessibility, reduced motion, and broader accessibility checks remain unverified.
- Login-start preference uses ServiceManagement, but actual registration/removal and restart persistence are unverified.
- The Control–Option–Space shortcut is implemented, but collision handling and conflicts with user/system shortcuts remain unverified.
- A moved/uninstalled app can fail to launch; verify the full relink/unavailable-app recovery experience.
- Signing, notarization, sandboxing, and packaged distribution have not been validated.

## Dock constraints

The user must pin generated launchers to Dock using standard macOS UI. The project will not use private APIs, modify Dock preferences, or automate user interaction. A stale Dock alias may remain after a generated launcher is removed; verify the cleanup guidance.

## Release decisions still required

- Signing, notarization and distribution format.
- Whether sandboxing is feasible for the discovery, launch, generated-app and IPC model; validate any security-scoped bookmark needs.
- Packaged lifecycle for generated per-user launchers and stale Dock shortcuts.

Track resolved issues in the changelog and move enduring constraints to [Decisions](Decisions.md).

- Hover detection was confirmed by a live prototype on one macOS 27 setup, but the integrated popup's entry/exit behavior and permission-denied fallback have not been manually exercised.
- Accessibility coordinate mapping across multiple displays, Dock movement/restart, magnification, auto-hide and fullscreen apps remain unverified.
