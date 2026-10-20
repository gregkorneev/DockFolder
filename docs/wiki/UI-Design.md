# UI design
Русская версия: [UI-Design.ru.md](UI-Design.ru.md)


All fixed interface labels, explanatory text, dialogs, help text, accessibility labels, and app-owned errors have English and Russian translations. macOS chooses a localized resource from the user's preferred languages. Application counts use locale-specific plural categories.

## Implemented

The app uses SwiftUI for folder management/settings and the application grid, with an AppKit Dock-aware popup panel and macOS 27 Liquid Glass. The folder popup uses one compact glass surface with unboxed app icons and optional labels. Each folder can use a configurable square grid, a single horizontal row, or a single vertical column. The popup sizes itself to the current display’s usable area and app count; if the selected row or column would not fit, it redistributes icons into a compact grid. The popup shows all apps without vertical or horizontal scrolling. Grid choices are filtered by the folder's app count; undersized grids are omitted and larger square sizes are offered dynamically. Adding apps automatically grows an undersized square grid to the minimum size that fits. A settings builder saves named layout presets; the selected default is copied to folders when they are created, and each folder can then choose an available saved or dynamic layout or hide its labels from the popup menu. The popup position follows the clicked Dock icon's screen and adapts to bottom, left, or right Dock placement. The panel expands from the clicked Dock icon and collapses back to it on close; the transition is skipped when macOS Reduce Motion is enabled. Folder and Dock launcher icons use a searchable picker covering the 7,752-name SF Symbols 7 catalog, including Apple device designs, with curated colors and the system color picker. Some Apple product symbols have use restrictions; see [SF Symbols](SF-Symbols.md). Generated launcher icons use square, unmasked 1024 × 1024 px artwork at 2× resolution (512 pt), which macOS scales for system surfaces; this follows [Apple’s app icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons), and AppKit distinguishes pixel dimensions from the point size of an image representation ([`NSImageRep.size`](https://developer.apple.com/documentation/appkit/nsimagerep/size)); folders and apps can be drag-reordered. Grid/icon sizing and theme are settings. The panel closes on Escape, focus loss and successful app launch. Multi-display layout and animation behavior still need manual verification.

## Remaining design verification

- Verify placement near each Dock orientation and supported display configurations.
- Verify clear states for empty/loading/search/unavailable/error content.
- Verify light/dark appearance, contrast, keyboard navigation, accessibility labels, VoiceOver, and reduced motion.
- Verify animations do not obstruct interaction or accessibility.

No custom design should mimic private Dock internals or depend on modifying the system Dock. Detailed acceptance is in [Implementation Plan](Implementation-Plan.md).
