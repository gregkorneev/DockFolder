# UI design
Русская версия: [UI-Design.ru.md](UI-Design.ru.md)


All fixed interface labels, explanatory text, dialogs, help text, accessibility labels, and app-owned errors have English and Russian translations. macOS chooses a localized resource from the user's preferred languages. Application counts use locale-specific plural categories.

## Implemented

The popup Layout editor accepts separate row and column counts from 1 to 10. Saved presets and legacy single-row or single-column layouts still load. Editing either count creates a per-folder custom grid. Extra apps remain accessible by scrolling the grid; the popup itself stays within the available display area.

The popup reserves additional bottom padding below the app icons so they do not sit against the lower glass edge.

Each folder's Folder Layout popover contains its own icon size, custom rows and columns, app label visibility, and matte-to-clear glass transparency. These values are persisted per folder and control its app grid and Dock popup. The default glass transparency is 55%.

The app uses SwiftUI for folder management/settings and the application grid, with an AppKit Dock-aware popup panel and macOS 27 Liquid Glass. The folder popup uses one compact glass surface with unboxed app icons and optional labels. Each folder can use a configurable square grid, a single horizontal row, or a single vertical column. The popup sizes itself to the current display’s usable area and app count; if the selected row or column would not fit, it redistributes icons into a compact grid. Legacy preset layouts still adapt to show all apps without scrolling. Custom grids keep the chosen dimensions and scroll when the app count or display size exceeds the visible cells. A settings builder saves named layout presets; the selected default is copied to folders when they are created, and each folder can then edit its own row and column counts or hide labels from the popup menu. The popup position follows the clicked Dock icon's screen and adapts to bottom, left, or right Dock placement. The panel expands from the clicked Dock icon and collapses back to it on close; the transition is skipped when macOS Reduce Motion is enabled. Folder and Dock launcher icons use a searchable picker covering the 7,752-name SF Symbols 7 catalog, including Apple device designs, with curated colors and the system color picker. Some Apple product symbols have use restrictions; see [SF Symbols](SF-Symbols.md). Generated launcher icons use square, unmasked 1024 × 1024 px artwork at 2× resolution (512 pt), which macOS scales for system surfaces; this follows [Apple’s app icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons), and AppKit distinguishes pixel dimensions from the point size of an image representation ([`NSImageRep.size`](https://developer.apple.com/documentation/appkit/nsimagerep/size)); folders and apps can be drag-reordered. Grid/icon sizing and theme are settings. The panel closes on Escape, focus loss and successful app launch. Multi-display layout and animation behavior still need manual verification.

## Remaining design verification

- Verify placement near each Dock orientation and supported display configurations.
- Verify clear states for empty/loading/search/unavailable/error content.
- Verify light/dark appearance, contrast, keyboard navigation, accessibility labels, VoiceOver, and reduced motion.
- Verify animations do not obstruct interaction or accessibility.

No custom design should mimic private Dock internals or depend on modifying the system Dock. Detailed acceptance is in [Implementation Plan](Implementation-Plan.md).
