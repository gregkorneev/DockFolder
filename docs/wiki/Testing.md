# Testing
Русская версия: [Testing.ru.md](Testing.ru.md)


## Recorded verification evidence

- macOS scheme build and tests completed successfully with Xcode 27.1 / SDK 27.0.
- Thirty-five Debug unit tests pass, including adaptive popup sizing for column layouts and constrained displays, dynamic grid capacity and automatic growth, an assertion that generated launcher artwork is a square 1024 × 1024 px bitmap at 2× resolution (512 pt), popup position calculations for all Dock edges and the popup's collapse transform targeting its Dock anchor, migration, URL validation, launcher bundles, ordering, configuration transfer, persistence, discovery and launch errors.
- The development custom-grid test covers independent row/column persistence, overflow capacity, and 1–10 clamping. The new text fields and scrolling have not yet been manually inspected in a running app.
- Manual UI smoke check created a folder, searched for and added Calculator, launched Calculator, and verified folder persistence after relaunch.
- Manual launcher smoke check opened the generated app through Finder and verified that it selected the Code folder both while DockFolders was running and after a cold start.
- On the current display, manually opened the five-app Code folder in its single-column layout; all app tiles fit in the popup without scrolling.

The Beta 2 Release app built on Xcode 27.1 / macOS 27.0 SDK with arm64 and a macOS 27.0 deployment target. Its ad-hoc code signature passed strict verification. The DMG checksum passed `hdiutil verify`; mounting confirmed the app, `/Applications` shortcut and bilingual install notes, and the mounted app passed strict code-signature verification. Release-configuration tests did not run because the test target could not import the non-testable Release module; all 34 release-stage tests passed in Debug; the subsequent custom-grid test also passed, bringing development coverage to 35 tests. No clean install, upgrade, Gatekeeper or notarization check was performed.

## Explicitly unverified

Actual adaptive popup sizing and clipping on multiple physical displays, all Dock edges, hidden/auto-hide Dock, and display attach/detach; VoiceOver, keyboard-only accessibility and runtime behavior with Reduce Motion; actual login-start registration/removal across restart; hotkey collision behavior; stale Dock alias cleanup; signing/notarization/sandbox/distribution; and clean-install pinning instructions remain unverified. Adaptive sizing, Dock-edge geometry and the animation's target transform have unit coverage, but host behavior still needs manual checking.

## Remaining test matrix

- Popup: available screen geometry on all Dock edges, hidden Dock, multiple displays, unplug/replug and display scale changes.
- Settings: login launch enable/disable/failure across restart; hotkey collision and re-registration behavior.
- UI/accessibility: keyboard operation, VoiceOver names, text scaling, contrast and reduced motion.
- Launcher: rename/delete, stale Dock item messaging, install/update/uninstall outside the development environment.
- Release: signing/notarization, selected sandbox policy, packaged clean install/upgrade/uninstall.

Run only checks that the environment supports; record manual setup and observed outcome. A passing build alone is not acceptance evidence for window behavior or distribution.

## Hover verification

On macOS 27, the built app was manually verified with the pinned Code launcher: hovering opened the matching folder without a click; moving the pointer into the popup kept it open; leaving the popup closed it. The integrated AX hit test matched folder `BAE3D00D-7F1F-4BAB-A431-061AA6A44FF2`. The user confirmed the open/retain/close behavior.

The first Accessibility entry was enabled but did not match the current ad-hoc signed Xcode build (`AXIsProcessTrusted()` returned false and TCC logged a code-requirement mismatch). Removing that stale entry and adding the current `DockFolders.app` build made trust true after returning to the app. A newly built ad-hoc binary may need to be re-added in Privacy & Security → Accessibility. A stable signing identity is still required for distribution.

Neighboring-folder switching, permission-denied fallback, active-hover energy, multiple displays, Dock movement/restart, auto-hide, magnification and fullscreen behavior remain unverified.

A 20-second Xcode Instruments Activity Monitor trace was captured while Hover was selected but Accessibility permission was denied. Samples after startup showed 0.0% CPU and about 79 MiB physical footprint. This records the idle app with hover detection disabled; it does not measure active hover behavior or energy while moving over Dock.
