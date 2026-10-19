# Testing
Русская версия: [Testing.ru.md](Testing.ru.md)


## Recorded verification evidence

- macOS scheme build completed successfully with Xcode 27.1 / SDK 27.0.
- Twenty unit tests pass, including an assertion that generated launcher artwork is a square 1024 × 1024 px bitmap at 2× resolution (512 pt), popup position calculations for all Dock edges and the popup's collapse transform targeting its Dock anchor, migration, URL validation, launcher bundles, ordering, configuration transfer, persistence, discovery and launch errors.
- Manual UI smoke check created a folder, searched for and added Calculator, launched Calculator, and verified folder persistence after relaunch.
- Manual launcher smoke check opened the generated app through Finder and verified that it selected the Code folder both while DockFolders was running and after a cold start.

## Explicitly unverified

Actual popup placement, animation and clipping on multiple physical displays, all Dock edges, hidden/auto-hide Dock, and display attach/detach; VoiceOver, keyboard-only accessibility and runtime behavior with Reduce Motion; actual login-start registration/removal across restart; hotkey collision behavior; stale Dock alias cleanup; signing/notarization/sandbox/distribution; and clean-install pinning instructions remain unverified. Dock-edge geometry and the animation's target transform have unit coverage, but host behavior still needs manual checking.

## Remaining test matrix

- Popup: available screen geometry on all Dock edges, hidden Dock, multiple displays, unplug/replug and display scale changes.
- Settings: login launch enable/disable/failure across restart; hotkey collision and re-registration behavior.
- UI/accessibility: keyboard operation, VoiceOver names, text scaling, contrast and reduced motion.
- Launcher: rename/delete, stale Dock item messaging, install/update/uninstall outside the development environment.
- Release: signing/notarization, selected sandbox policy, packaged clean install/upgrade/uninstall.

Run only checks that the environment supports; record manual setup and observed outcome. A passing build alone is not acceptance evidence for window behavior or distribution.
