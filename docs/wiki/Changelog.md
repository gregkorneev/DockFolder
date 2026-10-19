# Wiki changelog
Русская версия: [Changelog.ru.md](Changelog.ru.md)



## 2026-10-20 — Full feature implementation and status reconciliation

- Expanded the icon picker from a curated subset to the searchable SF Symbols 7.0 catalog (7,752 identifiers), including Apple device designs. Added bilingual documentation of Apple's use restrictions and why Shortcuts assets are not extracted.
- Added the categorized, searchable symbol picker, system color picker and preset backgrounds; generated Dock launchers now declare a standard multi-resolution `.icns` app icon from a 1024 × 1024 px source, allowing macOS to apply its normal Dock treatment. Tile size and magnification remain controlled by macOS Dock settings.
- Named generated launcher apps after their folders, preserved UUID routing, handled duplicate names with numeric suffixes, and added rename/collision tests.
- Animated the popup expanding from and collapsing back to its Dock icon; the transition respects macOS Reduce Motion.
- Added per-folder label visibility and grid, single-row, and single-column layouts, with named presets that can be selected as the default for future folders.
- Made grid choices dynamic: hide layouts that cannot hold the folder's current apps and offer larger square sizes when needed.
- Updated status to reflect generated per-folder launchers, validated URL routing, popup, folder customization/order, settings, hotkey, login-start integration, and import/export.
- Recorded 22 passing unit tests and the Finder launcher smoke check covering running and cold-start behavior.
- Kept multiple display/Dock-edge behavior, accessibility/reduced motion, actual login-start registration, hotkey collisions, Dock pinning on clean install, and signing/notarization/sandbox/distribution explicitly unverified.
- Documented that Dock pinning is a macOS user action and excluded preference edits/private APIs.

For implementation history, see the root [CHANGELOG.md](../../CHANGELOG.md).
