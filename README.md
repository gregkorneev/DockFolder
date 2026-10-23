# DockFolders

DockFolders is a native macOS app for organizing installed applications into user-created folders and launching them from the Dock. The current build implements the main version 1.0 feature set; platform/distribution verification still has open items.

## Implemented features

- Create, rename, and delete folders.
- Find installed applications and add/remove them from folders.
- Launch an application from a folder.
- Save folders and settings locally between launches.
- Localize the interface and standard application messages in English and Russian; macOS selects the language from its preferred languages.
- Use a native SwiftUI interface with macOS 27 visual materials.
- Use the supplied folder-and-app-grid artwork as the DockFolders app icon; its light 1024 × 1024 PNG is installed without image edits. Original editable layers and previews are preserved in [Design/DockFolders_IconComposer](Design/DockFolders_IconComposer/README.md), with the Icon Composer 27.1 import set in [Design/DockFolders_IconComposer_27_1_Import](Design/DockFolders_IconComposer_27_1_Import/README_Import_Icon_Composer_27.1.md).
- Choose folder and Dock launcher icons from a searchable, categorized catalog of 7,752 SF Symbols 7 names with larger previews, including Apple device designs; macOS renders the glyph artwork through public AppKit APIs. Set the background from curated colors or the system color picker. Dock icons use unmasked square artwork at 1024 × 1024 px and 2× resolution (512 pt), which macOS scales to Dock size. Reorder folders and apps by dragging.
- Open a compact Liquid Glass folder popup aligned with the clicked Dock icon on its display, adapting to bottom, left, and right Dock positions.
- Optionally open the popup on hover, on click, or both. Hover uses public Accessibility APIs and requires the macOS Accessibility permission; click remains available without it. Open/close delays are adjustable in Settings.
- Hide or show app names and enter 1–10 rows and columns for each folder; extra apps can be reached by scrolling. Named layout presets remain available for individual folders. New folders start with the standard layout.
- Adjust grid, icon size, and theme; set a global Control–Option–Space shortcut and login startup preference.
- Import and export configuration.
- Generate a launcher app for each folder in `/Applications/DockFolders`, named after the folder (numbered only when names collide); renaming updates the launcher name while preserving its stable `dockfolders://folder/<UUID>` route.
- Keep folder popups running without a permanent Dock icon. Use the gear button in a popup to open the folder manager; its Dock icon appears while the manager window is open and disappears when it closes.
- Follow the welcome guide on first launch, or reopen it from the Help menu.

To choose its icon, right-click the folder in the sidebar and select **Customize Folder & Dock Icon…**. To show a folder in Dock, generate its launcher from DockFolders, open the generated app from `/Applications/DockFolders` in Finder, then use its Dock menu **Options → Keep in Dock**. macOS requires this pinning step from the user; DockFolders does not modify Dock preferences. On macOS 27, the pinned Code launcher was verified end to end: hover opens its folder, moving into the popup keeps it open, and leaving closes it. Multiple displays and hidden-Dock configurations, accessibility/reduced motion, login-start registration, shortcut collisions, and signed/notarized distribution still need host verification.

If DockFolders itself was previously pinned, remove that pin manually with **Options → Remove from Dock**; macOS keeps user-pinned apps in the Dock independently of whether their window is open. Keep the generated folder launchers pinned instead.

## Requirements

- macOS 27.0 or later, Apple Silicon.

## Development builds

Beta 3 is available as an Apple Silicon DMG on [GitHub Releases](https://github.com/gregkorneev/DockFolder/releases). Development continues on `main`.

To build from source, use Xcode 27.1 or later with the macOS 27 SDK.

Open `DockFolders.xcodeproj` in Xcode, select the DockFolders scheme and My Mac destination, then build and run. Command-line verification:

```sh
xcodebuild -list -project DockFolders.xcodeproj
xcodebuild -project DockFolders.xcodeproj -scheme DockFolders -destination 'platform=macOS' build
xcodebuild -project DockFolders.xcodeproj -scheme DockFolders -destination 'platform=macOS' test
```

## Project notes

- Architecture and scope: [docs/wiki/Architecture.md](docs/wiki/Architecture.md)
- Implementation plan: [docs/wiki/Implementation-Plan.md](docs/wiki/Implementation-Plan.md)
- Dock constraints: [docs/wiki/Dock-Integration.md](docs/wiki/Dock-Integration.md)
- SF Symbols source and use: [docs/wiki/SF-Symbols.md](docs/wiki/SF-Symbols.md)
- App icon selection and source layers: [docs/wiki/App-Icon.md](docs/wiki/App-Icon.md)
- Full scope and status: [docs/wiki/Roadmap.md](docs/wiki/Roadmap.md)
- Data model: [docs/wiki/Data-Models.md](docs/wiki/Data-Models.md)
- Testing and acceptance: [docs/wiki/Testing.md](docs/wiki/Testing.md)
- Environment audit: [ENVIRONMENT_AUDIT.md](ENVIRONMENT_AUDIT.md)
