# Architecture decisions

## D-001 — Native SwiftUI/AppKit application (accepted)

Use Swift 6, SwiftUI, public AppKit APIs, system frameworks and Codable. Keep third-party dependencies out unless a measured need appears.

## D-002 — Local versioned JSON persistence (accepted for MVP)

Store user data in Application Support and write atomically. Preserve existing data on decoding or write errors. The version 1.0 model must migrate version 0.1 data safely.

## D-003 — Dock integration respects user control (accepted)

Use one ordinary app Dock icon for Stage A and independent launcher app bundles for Stage B. macOS documents user-driven Dock actions such as **Options → Keep in Dock**. AppKit's `NSDockTile` customizes an app/window tile; it does not provide a public API to pin an arbitrary new item. Therefore, users add each folder launcher through standard macOS controls. No Dock preference editing, private APIs, or UI automation. See [Dock Integration](Dock-Integration.md) and [Apple's Dock guide](https://support.apple.com/en-gb/guide/mac-help/mh35859/27/mac/27).

## D-004 — URL scheme for launcher routing (accepted)

Use a validated `dockfolders://folder/<UUID>` URL to route launcher activations. The generated launcher has been manually tested both with the host running and on cold-start. Continue validating signing and sandbox boundaries before release; do not interpret a UUID as authorization to perform unrelated actions.

## D-005 — Dock-aware popup (implemented; geometry coverage pending)

Use an AppKit panel hosted with SwiftUI, positioned in relation to Dock/screen geometry. Escape, focus loss and successful app launch dismiss it. Multi-display, each Dock edge, auto-hide and display reconfiguration still need manual verification.

## D-006 — User-controlled Dock pinning (accepted)

Generated launchers live in `~/Applications/DockFolders`; the user opens each launcher and chooses **Options → Keep in Dock**. Do not modify Dock preferences or automate the UI.

## D-007 — Distribution policy is open

The current local build is not a release distribution. Decide signing/notarization and sandbox policy after validating app discovery, bookmarks/permissions, and launcher installation.
