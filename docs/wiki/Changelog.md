# Wiki changelog
Русская версия: [Changelog.ru.md](Changelog.ru.md)

- Added per-folder icon size, grid columns, and glass transparency controls inside the Folder Layout popover; each folder now keeps its own display settings instead of inheriting app-wide values.



## 2026-10-20 — Full feature implementation and status reconciliation

- Installed the supplied `Preview_Light.png` as the DockFolders app icon without image edits, retained its original layered sources, and documented that Icon Composer 27.1 rejected the supplied `.icon` draft.
- Expanded the icon picker from a curated subset to the searchable SF Symbols 7.0 catalog (7,752 identifiers), including Apple device designs. Added bilingual documentation of Apple's use restrictions and why Shortcuts assets are not extracted.
- Added the categorized, searchable symbol picker, system color picker and preset backgrounds; generated Dock launchers now declare a standard multi-resolution `.icns` app icon from a 1024 × 1024 px source, allowing macOS to apply its normal Dock treatment. Tile size and magnification remain controlled by macOS Dock settings.
- Named generated launcher apps after their folders, preserved UUID routing, handled duplicate names with numeric suffixes, and added rename/collision tests.
- Animated the popup expanding from and collapsing back to its Dock icon; the transition respects macOS Reduce Motion.
- Added per-folder label visibility and grid, single-row, and single-column layouts, with named presets that can be selected as the default for future folders.
- Made grid choices dynamic: hide layouts that cannot hold the folder's current apps and offer larger square sizes when needed.
- Expanded square choices to 1 × 1 through 10 × 10, filtering out sizes too small for the current folder; folders with over 100 apps receive larger fitting options too.
- Updated status to reflect generated per-folder launchers, validated URL routing, popup, folder customization/order, settings, hotkey, login-start integration, and import/export.
- Recorded 22 passing unit tests and the Finder launcher smoke check covering running and cold-start behavior.
- Kept multiple display/Dock-edge behavior, accessibility/reduced motion, actual login-start registration, hotkey collisions, Dock pinning on clean install, and signing/notarization/sandbox/distribution explicitly unverified.
- Documented that Dock pinning is a macOS user action and excluded preference edits/private APIs.

For implementation history, see the root [CHANGELOG.md](../../CHANGELOG.md).

## 2026-10-20 — Hover to Open prototype and integration

- Confirmed on macOS 27 that global pointer-movement events plus the public Dock Accessibility hit-test identify the pinned Code launcher without a click.
- Added opt-in Click / Hover / Both opening modes, persisted configurable delays (180 ms open and 250 ms close by default), and a permission explanation requesting only Accessibility.
- Added an event-driven Dock hover monitor, folder UUID matching via generated launcher bundle identifiers, pointer transfer grace for the popup, neighbor switching without panel replacement, and an adaptive fallback when event monitors cannot be registered.
- Integrated hover behavior with the existing popup and kept click-only as the default. Panel interaction and alternate Dock/display configurations still require manual verification.
