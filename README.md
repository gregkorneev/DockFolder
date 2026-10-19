# DockFolders

DockFolders is a native macOS app for organizing installed applications into user-created folders and launching them from the Dock. The current build implements the main version 1.0 feature set; platform/distribution verification still has open items.

## Implemented features

- Create, rename, and delete folders.
- Find installed applications and add/remove them from folders.
- Launch an application from a folder.
- Save folders and settings locally between launches.
- Localize the interface and standard application messages in English and Russian; macOS selects the language from its preferred languages.
- Use a native SwiftUI interface with macOS 27 visual materials.
- Customize folders with SF Symbols and colors; reorder folders and apps by dragging.
- Open a Dock-aware Liquid Glass popup, dismissed by Escape, focus loss, or successful app launch.
- Adjust grid, icon size, and theme; set a global Control–Option–Space shortcut and login startup preference.
- Import and export configuration.
- Generate a launcher app for each folder in `~/Applications/DockFolders`; validated `dockfolders://folder/<UUID>` links open the matching folder, including cold launch of DockFolders.

To show a folder in Dock, generate its launcher from DockFolders, open the generated app from `~/Applications/DockFolders` in Finder, then use its Dock menu **Options → Keep in Dock**. macOS requires this pinning step from the user; DockFolders does not modify Dock preferences. Multiple displays and Dock edges, accessibility/reduced motion, login-start registration, shortcut collisions, and signed/notarized distribution remain unverified.

## Requirements

- macOS 27.0 or later, Apple Silicon.
- Xcode 27.1 or later with the macOS SDK.

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
- Full scope and status: [docs/wiki/Roadmap.md](docs/wiki/Roadmap.md)
- Data model: [docs/wiki/Data-Models.md](docs/wiki/Data-Models.md)
- Testing and acceptance: [docs/wiki/Testing.md](docs/wiki/Testing.md)
- Environment audit: [ENVIRONMENT_AUDIT.md](ENVIRONMENT_AUDIT.md)
