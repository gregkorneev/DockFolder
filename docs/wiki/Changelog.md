# Wiki changelog
Русская версия: [Changelog.ru.md](Changelog.ru.md)



## 2026-10-20 — Full feature implementation and status reconciliation

- Added the categorized, searchable symbol picker, system color picker and preset backgrounds; generated Dock launcher artwork now uses an unmasked square 1024 × 1024 px source image at 2× resolution (512 pt).
- Named generated launcher apps after their folders, preserved UUID routing, handled duplicate names with numeric suffixes, and added rename/collision tests.
- Updated status to reflect generated per-folder launchers, validated URL routing, popup, folder customization/order, settings, hotkey, login-start integration, and import/export.
- Recorded 19 passing unit tests and the Finder launcher smoke check covering running and cold-start behavior.
- Kept multiple display/Dock-edge behavior, accessibility/reduced motion, actual login-start registration, hotkey collisions, Dock pinning on clean install, and signing/notarization/sandbox/distribution explicitly unverified.
- Documented that Dock pinning is a macOS user action and excluded preference edits/private APIs.

For implementation history, see the root [CHANGELOG.md](../../CHANGELOG.md).
