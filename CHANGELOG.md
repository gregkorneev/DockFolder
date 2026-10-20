# Changelog
Русская версия: [CHANGELOG.ru.md](CHANGELOG.ru.md)



## Unreleased — feature-complete implementation; release validation outstanding

- Installed the supplied `Preview_Light.png` as the DockFolders app icon without image edits; preserved the original layered draft for future Icon Composer work.
- Expanded the icon picker from a curated subset to the searchable SF Symbols 7.0 catalog (7,752 identifiers), including Apple device designs; artwork remains provided at runtime by macOS.
- Added a categorized, searchable SF Symbols picker, curated background colors and the system color picker for folder and Dock launcher icons; launcher icons are now bundled as standard multi-resolution `.icns` app icons from a 1024 × 1024 px source, so macOS applies its normal Dock icon treatment. The tile size and magnification remain controlled by macOS Dock settings.
- Named each generated Dock launcher after its folder, preserved stable UUID routing, and added readable numeric suffixes for duplicate names; renames now update the launcher name.
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
- Added one generated launcher `.app` per folder under `/Applications/DockFolders`; validated `dockfolders://folder/<UUID>` URLs open the correct folder when DockFolders is running or cold-started.
- Added Russian translations alongside English for the README, contributor instructions, changelogs, environment audit, and every project Wiki page.
- Compactified the folder popup with smaller unboxed app icons, labels, inline search, and a scrollable four-column grid.
- Positioned the popup on the display containing the clicked Dock icon and adapted it to bottom, left, right, and auto-hidden Dock layouts; added geometry tests.
- Animated the popup expanding from and collapsing back to its Dock icon, and disabled the transition when macOS Reduce Motion is enabled.
- Added per-folder label visibility and grid, single-row, and single-column layouts, plus a layout preset builder whose selected default applies to newly created folders.
- Made popup grid choices depend on folder size: layouts with too few cells are hidden and larger square grids are offered automatically as needed.
- Twenty-two unit tests pass, including dynamic grid capacity and automatic growth, model migration, URL validation, launcher bundle generation, ordering, and configuration transfer.
- Manual launcher smoke check opened a generated launcher through Finder and verified it opened the Code folder with the main app already running and after cold-start.
- Still unverified: visual animation behavior across multiple displays and all Dock edges, accessibility, actual login-start registration, hotkey collision behavior, signing/notarization/sandbox/distribution, and manual pinning by users on a clean install.

## 2026-10-20 — Hover to Open

- Verified live pointer-to-Dock-item detection on macOS 27 using global mouse movement events and the public Accessibility API.
- Added optional Click / Hover / Both modes, configurable open/close delays, an Accessibility permission explanation, and event-driven popup control with an adaptive low-frequency fallback.
- Sized popups to the available display area and folder contents; overflowing layouts adapt to a grid without scrolling app tiles. Added adaptive layout coverage.
- Verified in the built app that hovering Code opens its folder, moving into the popup keeps it open, and leaving closes it.
- Kept click opening as the default; neighboring-folder switching, denied-permission behavior, active-hover energy and alternate display/Dock configurations still require validation.
