# Dock integration
Русская версия: [Dock-Integration.ru.md](Dock-Integration.ru.md)


## Stage A — One Dock icon (implemented in 0.1)

The user adds DockFolders itself to the Dock. Clicking it shows the regular folder browser. The app implements `applicationShouldHandleReopen` to restore or bring that window forward through public app lifecycle APIs. The app does not add views to, patch, or otherwise modify the system Dock. Manual verification of repeated Dock activation remains outstanding.

## Dock pinning is user-controlled

DockFolders can create and install launcher application bundles, but it must not silently add or remove Dock items. macOS documents adding an open app through its Dock menu (**Options → Keep in Dock**) and adding apps by dragging them into Dock; use this user-driven flow for each generated launcher. See [Apple Support: Use the Dock on Mac](https://support.apple.com/en-gb/guide/mac-help/mh35859/27/mac/27).

AppKit's [`NSDockTile`](https://developer.apple.com/documentation/appkit/nsdocktile) exposes appearance/badge customization for an existing app or window tile. It is not a public API for registering an arbitrary folder as a Dock item or silently pinning a new app. This conclusion follows from the documented scope of `NSDockTile` and Apple's documented user workflow. Do not edit Dock preference databases, invoke private APIs, or automate Dock UI to bypass the user action.

For launchers, create a stable per-folder bundle under `/Applications/DockFolders`, then show its location and a short manual pinning instruction. Deletion/rename behavior must be explicit: renaming a folder should preserve launcher identity and update its displayed name; deleting a folder should offer to remove its launcher bundle from DockFolders-managed storage, while macOS may keep a now-stale Dock shortcut until the user removes it. The folder popup animates from the clicked Dock icon on open and back to that icon on close, unless Reduce Motion is enabled.

## Stage B — One launcher per folder (implemented)

DockFolders generates one launcher app per folder under `/Applications/DockFolders`, using the folder name as the app name and a numeric suffix for duplicate names. Renaming a folder updates its launcher name while preserving the UUID route. On launch, it migrates existing launchers from `~/Applications/DockFolders` to the new location. Each launcher sends a stable UUID using a custom `dockfolders://folder/<UUID>` URL. The URL is validated before routing to the selected folder. When the popup opens, it uses the pointer location to select the screen and align the panel with the Dock icon that was clicked. `NSScreen.visibleFrame` identifies a reserved bottom, left, or right Dock edge; if no edge is reserved, the clicked point is used to infer the nearest edge. The panel is placed inward from that edge and clamped to the selected screen. Apple documents that `visibleFrame` reflects current system UI settings and can remain smaller than the full screen when Dock auto-hide is enabled ([`NSScreen.visibleFrame`](https://developer.apple.com/documentation/appkit/nsscreen/visibleframe)). The launcher is generated and managed by DockFolders; pinning remains a separate, user-driven macOS action.

Each generated bundle declares its launcher artwork through `CFBundleIconFile` and contains a multi-resolution `.icns` resource generated from the 1024 × 1024 px design. This lets macOS present it as a normal application icon and apply the system's Dock treatment. There is no per-icon Dock size setting exposed to applications: macOS controls tile size and pointer magnification through Desktop & Dock settings ([Apple Support: Change Desktop & Dock settings](https://support.apple.com/en-ie/guide/mac-help/mchlp1119/27/mac/27)).

### User setup

1. Generate the folder launcher from DockFolders.
2. In Finder, open `/Applications/DockFolders` and launch the generated app once.
3. In Dock, Control-click/right-click its icon and choose **Options → Keep in Dock**.
4. Repeat for each folder launcher the user wants in Dock.

DockFolders must not write Dock preference files, invoke private APIs, or automate these UI actions. Apple documents the user flow in [Use the Dock on Mac](https://support.apple.com/en-gb/guide/mac-help/mh35859/27/mac/27). [`NSDockTile`](https://developer.apple.com/documentation/appkit/nsdocktile) customizes an existing app/window tile; it is not a public registration/pinning mechanism for arbitrary new Dock entries.

### Remaining verification

Generated launcher routing and cold-start are verified. Unit tests cover bottom, left, and right Dock geometry, pointer fallback, and screen anchoring. Actual popup placement on multiple physical displays, Dock auto-hide variants, stale Dock shortcut cleanup after folder removal, signing/notarization, and sandbox/distribution behavior still need manual verification.
