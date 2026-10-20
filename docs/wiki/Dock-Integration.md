# Dock integration
Русская версия: [Dock-Integration.ru.md](Dock-Integration.ru.md)


## Stage A — One Dock icon (implemented in 0.1)

DockFolders runs as an accessory app while serving folder popups, so its manager icon does not stay in the Dock. A gear button in each popup opens the folder manager, switches the app to regular activation and makes its Dock icon visible while the manager window is open. Closing that window restores accessory activation and removes the app's Dock icon; the process stays available for folder launchers, hover, and shortcuts. `applicationShouldHandleReopen` restores the manager while it is open or minimized. This uses public app lifecycle APIs and does not modify the system Dock. Manual verification of these activation transitions remains outstanding.

If the user previously pinned DockFolders itself, they must remove that persistent Dock item manually; macOS keeps user-pinned items regardless of an app's current activation policy. Keep the generated per-folder launchers pinned.

## Dock pinning is user-controlled

DockFolders can create and install launcher application bundles, but it must not silently add or remove Dock items. macOS documents adding an open app through its Dock menu (**Options → Keep in Dock**) and adding apps by dragging them into Dock; use this user-driven flow for each generated launcher. See [Apple Support: Use the Dock on Mac](https://support.apple.com/en-gb/guide/mac-help/mh35859/27/mac/27).

AppKit's [`NSDockTile`](https://developer.apple.com/documentation/appkit/nsdocktile) exposes appearance/badge customization for an existing app or window tile. It is not a public API for registering an arbitrary folder as a Dock item or silently pinning a new app. This conclusion follows from the documented scope of `NSDockTile` and Apple's documented user workflow. Do not edit Dock preference databases, invoke private APIs, or automate Dock UI to bypass the user action.

For launchers, create a stable per-folder bundle under `/Applications/DockFolders`, then show its location and a short manual pinning instruction. Deletion/rename behavior must be explicit: renaming a folder should preserve launcher identity and update its displayed name; deleting a folder should offer to remove its launcher bundle from DockFolders-managed storage, while macOS may keep a now-stale Dock shortcut until the user removes it. The folder popup animates from the clicked Dock icon on open and back to that icon on close, unless Reduce Motion is enabled.

## Stage B — One launcher per folder (implemented)

DockFolders generates one launcher app per folder under `/Applications/DockFolders`, using the folder name as the app name and a numeric suffix for duplicate names. Renaming a folder updates its launcher name while preserving the UUID route. On launch, it migrates existing launchers from `~/Applications/DockFolders` to the new location. Each launcher sends a stable UUID using a custom `dockfolders://folder/<UUID>` URL. The URL is validated before routing to the selected folder. When the popup opens, it uses the pointer location to select the screen and align the panel with the Dock icon that was clicked. `NSScreen.visibleFrame` identifies a reserved bottom, left, or right Dock edge; if no edge is reserved, the clicked point is used to infer the nearest edge. The panel is placed inward from that edge and clamped to the selected screen. Apple documents that `visibleFrame` reflects current system UI settings and can remain smaller than the full screen when Dock auto-hide is enabled ([`NSScreen.visibleFrame`](https://developer.apple.com/documentation/appkit/nsscreen/visibleframe)). The launcher is generated and managed by DockFolders; pinning remains a separate, user-driven macOS action.

Each generated bundle declares its launcher artwork through `CFBundleIconFile` and contains a multi-resolution `.icns` resource generated from the 1024 × 1024 px design. This lets macOS present it as a normal application icon and apply the system's Dock treatment. There is no per-icon Dock size setting exposed to applications: macOS controls tile size and pointer magnification through Desktop & Dock settings ([Apple Support: Change Desktop & Dock settings](https://support.apple.com/en-ie/guide/mac-help/mchlp1119/27/mac/27)).

While DockFolders runs in the background, its app icon stays in the macOS menu bar. The icon menu opens the folder manager or quits DockFolders completely. Closing the manager hides its Dock tile but leaves the menu bar icon until the app quits.

Folder URLs are routed directly by the application delegate using the shared store. There is no automatic main `WindowGroup`: the AppKit browser window is created only for a default app launch (`NSApplication.launchIsDefaultUserInfoKey`), explicit app reopen, or error display. Startup services do not depend on the browser appearing. Regression tests cover URL startup without a browser, normal launch/reopen, and missing-folder errors. Visual validation of the new cold-start path remains outstanding.

An existing error does not replace a valid folder popup with the browser; the popup presents the error. Startup launcher migration runs only when an older bundle needs moving or renaming. Folder deletion persists the data change before removing its launcher; a failed save keeps both the folder and launcher.

If folder data cannot be read, opening a stale launcher keeps the data-load error visible instead of replacing it with a generic invalid-link message.

### User setup

1. Generate the folder launcher from DockFolders.
2. In Finder, open `/Applications/DockFolders` and launch the generated app once.
3. In Dock, Control-click/right-click its icon and choose **Options → Keep in Dock**.
4. Repeat for each folder launcher the user wants in Dock.

DockFolders must not write Dock preference files, invoke private APIs, or automate these UI actions. Apple documents the user flow in [Use the Dock on Mac](https://support.apple.com/en-gb/guide/mac-help/mh35859/27/mac/27). [`NSDockTile`](https://developer.apple.com/documentation/appkit/nsdocktile) customizes an existing app/window tile; it is not a public registration/pinning mechanism for arbitrary new Dock entries.

### Remaining verification

Generated launcher routing and cold-start are verified. Unit tests cover bottom, left, and right Dock geometry, pointer fallback, and screen anchoring. Actual popup placement on multiple physical displays, Dock auto-hide variants, stale Dock shortcut cleanup after folder removal, signing/notarization, and sandbox/distribution behavior still need manual verification.

## Stage C — Hover to Open (implemented; host verification partial)

The optional setting supports Click, Hover, and Both; Click remains the default and works without Accessibility permission. Hover mode listens for global/local mouse-movement events and hit-tests the Dock through public `AXUIElementCopyElementAtPosition`, matching only generated launcher bundle identifiers to folder UUIDs. It opens after a configurable 180 ms default, retains the panel while the pointer enters it, closes after a configurable 250 ms default, and changes folders without replacing the panel. Escape and app-launch handling continue through the existing popup. An adaptive timer also rechecks a stationary pointer after the Dock moves into place, polling slowly while idle and more frequently near the Dock. Accessibility permission is explained in Settings; no Screen Recording or Input Monitoring permission is requested. On macOS 27, the pinned `/Applications/DockFolders/Code.app` was verified end to end before this timer fix: hovering opened the matching popup, moving into it kept it open, and leaving closed it. The stationary-pointer case, neighbor switching, permission-denied behavior, and multiple display/Dock arrangements still need manual verification.

The implementation uses Apple's documented [`AXUIElementCopyElementAtPosition`](https://developer.apple.com/documentation/applicationservices/1462077-axuielementcopyelementatposition), [`AXUIElementCopyAttributeValue`](https://developer.apple.com/documentation/applicationservices/1459076-axuielementcopyattributevalue), [`AXIsProcessTrustedWithOptions`](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions), [`NSEvent.addGlobalMonitorForEvents`](https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents%28matching%3Ahandler%3A%29), [`NSEvent.addLocalMonitorForEvents`](https://developer.apple.com/documentation/appkit/nsevent/addlocalmonitorforevents%28matching%3Ahandler%3A%29), `NSPanel`, and `NSWorkspace`. Coordinate conversion is anchored to the primary display's AppKit frame; multi-display coordinate arrangements remain unverified on this host.

The local Debug build uses an ad-hoc signature. After rebuilding it, the previous System Settings toggle may remain visible while `AXIsProcessTrusted()` inside the new build returns false. Hover settings now report that actual trust result and explain how to reauthorize the current app; the monitor retries when trust becomes active. Do not count a visible toggle alone as host verification.
