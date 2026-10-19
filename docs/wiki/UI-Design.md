# UI design
Русская версия: [UI-Design.ru.md](UI-Design.ru.md)


All fixed interface labels, explanatory text, dialogs, help text, accessibility labels, and app-owned errors have English and Russian translations. macOS chooses a localized resource from the user's preferred languages. Application counts use locale-specific plural categories.

## Implemented

The app uses SwiftUI for folder management/settings and the application grid, with an AppKit Dock-aware popup panel and macOS 27 Liquid Glass. The folder popup uses one compact glass surface with unboxed app icons and small labels; it shows up to four columns, retains inline search, and scrolls for larger folders. Its position follows the clicked Dock icon's screen and adapts to bottom, left, or right Dock placement. Folder SF Symbols and colors are configurable; folders and apps can be drag-reordered. Grid/icon sizing and theme are settings. The panel closes on Escape, focus loss and successful app launch. Physical multi-display behavior and accessibility/reduced motion remain unverified.

## Remaining design verification

- Verify placement near each Dock orientation and supported display configurations.
- Verify clear states for empty/loading/search/unavailable/error content.
- Verify light/dark appearance, contrast, keyboard navigation, accessibility labels, VoiceOver, and reduced motion.
- Verify animations do not obstruct interaction or accessibility.

No custom design should mimic private Dock internals or depend on modifying the system Dock. Detailed acceptance is in [Implementation Plan](Implementation-Plan.md).
