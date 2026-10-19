# Changelog

## Unreleased — feature-complete implementation; release validation outstanding

- Project environment audited and Xcode 27.1 / macOS SDK 27 confirmed.
- Initial architecture and MVP plan recorded.
- Added a native SwiftUI macOS app with folder create, rename, and delete flows.
- Added installed-app discovery/search, file-picker fallback, app add/remove, and launching through `NSWorkspace`.
- Added versioned atomic JSON persistence and recovery-safe error handling.
- Added Dock reopen handling and a Liquid Glass application grid.
- Added folder SF Symbol/color customization and manual drag ordering for folders and apps.
- Added Dock-aware Liquid Glass popup behavior, dismissal on Escape/focus loss/successful app launch, and settings for grid/icon size, theme, login startup, and global hotkey.
- Added configuration import/export.
- Added English and Russian interface localization, including Russian plural forms for application counts.
- Added one generated launcher `.app` per folder under `~/Applications/DockFolders`; validated `dockfolders://folder/<UUID>` URLs open the correct folder when DockFolders is running or cold-started.
- Thirteen unit tests pass, including model migration from the old JSON shape, URL validation, launcher bundle generation, ordering, and configuration transfer.
- Manual launcher smoke check opened a generated launcher through Finder and verified it opened the Code folder with the main app already running and after cold-start.
- Still unverified: multiple displays and all Dock edges, accessibility/reduced motion, actual login-start registration, hotkey collision behavior, signing/notarization/sandbox/distribution, and manual pinning by users on a clean install.
