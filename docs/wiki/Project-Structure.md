# Project structure
Русская версия: [Project-Structure.ru.md](Project-Structure.ru.md)


Current implementation tree (recorded at package/directory level):

```text
DockFolders.xcodeproj/       Xcode app and unit-test targets
DockFolders/
  App/                       SwiftUI entry and app delegate adaptor
  Models/                    Codable folder, app-entry, and settings values
  Views/                     Sidebar, popup, app picker/grid, settings
  ViewModels/                 Observable folder state and persistence coordination
  Services/                   Discovery, launch, persistence, launcher, transfer
  Managers/                   Popup/Dock, hotkey, and login-start integration
DockFoldersTests/             macOS-hosted unit tests
docs/wiki/                    Project documentation source of truth
AGENTS.md                     Contributor and agent instructions
README.md                     Build and product overview
README.ru.md                  Russian build and product overview
CHANGELOG.md                  Root release history
ENVIRONMENT_AUDIT.md          Original toolchain audit
*.ru.md / *.en.md             Translated project documentation
```

Per-folder launcher apps are generated at runtime under `/Applications/DockFolders`; there is no one checked-in Xcode target per user folder. Remaining work is platform/distribution verification described in [Roadmap](Roadmap.md). Record exact file-level additions after confirming the project tree.
