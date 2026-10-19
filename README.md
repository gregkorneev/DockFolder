# DockFolders

DockFolders is a native macOS app for organizing installed applications into user-created folders and launching them from one Dock icon.

## MVP 0.1

- Create, rename, and delete folders.
- Find installed applications and add/remove them from folders.
- Launch an application from a folder.
- Save folders locally between launches.
- Use a native SwiftUI interface with macOS 27 visual materials.

The MVP uses one regular app and one Dock icon. Per-folder launcher apps are a separate future phase and will use public APIs only.

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
- Environment audit: [ENVIRONMENT_AUDIT.md](ENVIRONMENT_AUDIT.md)
