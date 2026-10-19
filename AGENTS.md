# DockFolders contributor instructions
Русская версия: [AGENTS.ru.md](AGENTS.ru.md)


## Product and platform

- DockFolders is a native macOS application targeting macOS 27.0+ and Apple Silicon (`arm64`).
- Use Swift 6 language mode, SwiftUI for the interface, and public AppKit, Carbon, or ServiceManagement APIs at the macOS integration seams that need them.
- Before significant platform changes, verify API availability and compatibility against the selected Xcode and macOS 27 SDK. Do not infer API availability from an API name or an online example.
- Prefer public Apple APIs and system frameworks. Do not use private Dock APIs or modify the system Dock.
- The current implementation includes the feature scope of version 1.0 and per-folder launchers; check `docs/wiki/Roadmap.md` and `docs/wiki/Implementation-Plan.md` for the evidence and remaining release validation. Distinguish implemented behavior from unverified machine-specific/release scenarios.
- macOS controls whether applications are kept in the Dock. Do not write Dock preferences or claim that app code can silently pin a launcher. Provide a clear user-driven install/pinning step and document it.
- Preserve the requirement that only public Apple APIs are used. `NSDockTile` customizes a running app's tile; it is not an API for creating arbitrary Dock entries or pinning applications.

## Design and implementation

- Keep UI, models, and OS interaction separate. Add a protocol at an OS or persistence seam when it makes behavior testable; avoid generic frameworks and unnecessary layers.
- Persist user folders atomically and preserve existing data on decode/write errors.
- Surface errors to the user; never silently discard a folder or application entry.
- Use structured Swift concurrency and isolate UI state to `MainActor`.
- Keep accessibility labels and keyboard navigation for all controls.
- Do not add third-party dependencies without a concrete need.

## Work and verification

- Follow repository and user instructions before changing files. The user has requested that all project work be done on `main`; make future changes directly on `main` unless the user changes this instruction.
- Make small, coherent commits. Push completed stages to `origin/main` and report the commit and push status. Preserve existing commit history; do not squash or rewrite shared history.
- Update `docs/wiki/` and `CHANGELOG.md` when a stage changes architecture, behavior, or project status.
- Keep all documentation, including the README, contributor instructions, changelogs, environment audit, and wiki, available in both English and Russian. Update both paired language versions together.
- Keep all required Wiki pages listed in `docs/wiki/Home.md` present and consistent with the code. Mark roadmap items `Planned`, `In progress`, or `Complete` with evidence; do not label a phase complete until its acceptance criteria pass.
- Per-folder launcher apps use validated `dockfolders://folder/<UUID>` links and are generated under `/Applications/DockFolders`. Existing launchers in `~/Applications/DockFolders` migrate on app launch. Users must pin each app to Dock themselves. Do not edit Dock preferences or automate pinning.
- Current hotkey is Control–Option–Space; login startup uses ServiceManagement. Do not claim the OS registration or conflict scenarios passed unless those were manually verified on the target macOS host.
- Run `xcodebuild -list` to inspect schemes, then build and test the macOS scheme with `xcodebuild`. Report only checks that were actually run.
- Do not install or update toolchains or dependencies automatically.
- Before release, repeat the toolchain/API compatibility audit.

## Current target

- Minimum deployment target: macOS 27.0.
- Xcode: 27.1; macOS SDK: 27.0; bundled Swift compiler: 6.4.
