# Dock integration

## Stage A — One Dock icon (implemented in 0.1)

The user adds DockFolders itself to the Dock. Clicking it shows the regular folder browser. The app implements `applicationShouldHandleReopen` to restore or bring that window forward through public app lifecycle APIs. The app does not add views to, patch, or otherwise modify the system Dock. Manual verification of repeated Dock activation remains outstanding.

## Dock pinning is user-controlled

DockFolders can create and install launcher application bundles, but it must not silently add or remove Dock items. macOS documents adding an open app through its Dock menu (**Options → Keep in Dock**) and adding apps by dragging them into Dock; use this user-driven flow for each generated launcher. See [Apple Support: Use the Dock on Mac](https://support.apple.com/en-gb/guide/mac-help/mh35859/27/mac/27).

AppKit's [`NSDockTile`](https://developer.apple.com/documentation/appkit/nsdocktile) exposes appearance/badge customization for an existing app or window tile. It is not a public API for registering an arbitrary folder as a Dock item or silently pinning a new app. This conclusion follows from the documented scope of `NSDockTile` and Apple's documented user workflow. Do not edit Dock preference databases, invoke private APIs, or automate Dock UI to bypass the user action.

For launchers, create a stable per-folder bundle under `/Applications/DockFolders`, then show its location and a short manual pinning instruction. Deletion/rename behavior must be explicit: renaming a folder should preserve launcher identity and update its displayed name; deleting a folder should offer to remove its launcher bundle from DockFolders-managed storage, while macOS may keep a now-stale Dock shortcut until the user removes it.

## Stage B — One launcher per folder (implemented)

DockFolders generates one launcher app per folder under `/Applications/DockFolders`. On launch, it migrates existing launchers from `~/Applications/DockFolders` to the new location. Each launcher sends a stable UUID using a custom `dockfolders://folder/<UUID>` URL. The URL is validated before routing to the selected folder. The launcher is generated and managed by DockFolders; pinning remains a separate, user-driven macOS action.

### User setup

1. Generate the folder launcher from DockFolders.
2. In Finder, open `/Applications/DockFolders` and launch the generated app once.
3. In Dock, Control-click/right-click its icon and choose **Options → Keep in Dock**.
4. Repeat for each folder launcher the user wants in Dock.

DockFolders must not write Dock preference files, invoke private APIs, or automate these UI actions. Apple documents the user flow in [Use the Dock on Mac](https://support.apple.com/en-gb/guide/mac-help/mh35859/27/mac/27). [`NSDockTile`](https://developer.apple.com/documentation/appkit/nsdocktile) customizes an existing app/window tile; it is not a public registration/pinning mechanism for arbitrary new Dock entries.

### Remaining verification

Generated launcher routing and cold-start are verified. Multiple display/Dock-edge popup placement, stale Dock shortcut cleanup after folder removal, signing/notarization, and sandbox/distribution behavior remain unverified.
