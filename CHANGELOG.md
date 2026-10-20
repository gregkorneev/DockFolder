# Changelog
Русская версия: [CHANGELOG.ru.md](CHANGELOG.ru.md)

## Unreleased — development

- Tighten folder popup icon rows and columns by using icon-sized grid cells instead of stretching each cell across the panel.
- Render generated launcher symbols with a clear secondary layer, so multicolor SF Symbols such as `macbook` keep the same outline as the folder picker instead of gaining a tinted fill.
- Keep the DockFolders Dock icon hidden when a folder popup opens from the manager, and give popup content enough height to display complete app icons at every chosen grid size.
- Group all SF Symbols in the icon picker by category and enlarge their previews.
- Remove the default-layout-for-new-folders setting; new folders start with the standard layout, while saved presets remain available for individual folders.
- Show a four-page welcome guide on first ordinary launch, with a Help menu command to reopen it.
- Reduce horizontal and vertical grid spacing as app icons shrink, so more icons fit in the same popup area.
- Keep DockFolders out of the Dock while it runs folder popups; add a gear button to open the manager, showing the app in Dock only while its window is open.
- Keep a hover-open folder visible while its layout settings are open, hide the visible row/column captions, and resize the popup grid continuously with the icon-size slider.
- Make custom grid cells expand across the popup and fit every selected row and column on screen. The selected capacity is visible without scrolling; only apps beyond that capacity scroll, and labels/icons scale down on constrained displays.

## 2026-10-20 — 1.0.0 Beta 2

- Added editable row and column counts from 1 to 10 in each folder's layout menu. Custom grids keep their chosen dimensions and scroll when apps exceed the visible cells or screen space.

- Show the actual Accessibility trust status for the current build in Hover settings and retry monitoring after permission becomes active. Rebuilding the ad-hoc-signed app may require reauthorizing that build.

- Fixed hover opening when the Dock appears beneath a stationary pointer: an adaptive timer now rechecks the Dock item even when a global mouse monitor is installed.

- Preserved the original folder-data load error when a stale or invalid launcher URL is opened, so the recovery problem remains visible.

- Fixed folder deletion after a persistence failure: the launcher remains in place when the folder could not be saved, and launcher removal now follows a successful save. Existing errors no longer redirect valid folder links to the main window; the folder popup can show those errors. Startup migration skips launchers already in their current location.

- Increased the popup's bottom breathing room beneath the app icons.
- Fixed the main-window flash when opening folder launchers by routing URLs independently of the browser and creating its AppKit window only for ordinary app launches, explicit reopens, or errors. Added lifecycle regression tests; visual cold-start validation remains outstanding.

## 2026-10-20 — 1.0.0 Beta 1

- Added per-folder icon size, grid columns, and glass transparency controls inside the Folder Layout popover; each folder now keeps its own display settings instead of inheriting app-wide values.
- Expanded dynamic square layouts from 1 × 1 through 10 × 10, showing only sizes that fit every app in the folder; folders over 100 apps also get larger fitting grids.
- Fixed selected folder text contrast in the sidebar for light and dark appearances.
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

### 2026-10-20 — Hover to Open

- Prevented the regular browser window from appearing during folder launcher startup by disabling stale window restoration and hiding any default windows before showing the folder popup.
- Verified live pointer-to-Dock-item detection on macOS 27 using global mouse movement events and the public Accessibility API.
- Added optional Click / Hover / Both modes, configurable open/close delays, an Accessibility permission explanation, and event-driven popup control with an adaptive low-frequency fallback.
- Sized popups to the available display area and folder contents; overflowing layouts adapt to a grid without scrolling app tiles. Added adaptive layout coverage.
- Verified in the built app that hovering Code opens its folder, moving into the popup keeps it open, and leaving closes it.
- Kept click opening as the default; neighboring-folder switching, denied-permission behavior, active-hover energy and alternate display/Dock configurations still require validation.
