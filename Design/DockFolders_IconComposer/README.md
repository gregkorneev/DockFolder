# DockFolders icon draft

This folder preserves the supplied draft artwork and layer files for later design work. The three SVGs in `SourceLayers/` are the editable layers; the PNGs are previews.

## Icon currently used

`Preview_Light.png` is installed as DockFolders' macOS app icon with no image edits. The asset catalog copy is byte-for-byte identical. The dark preview is kept for future iteration and is not yet wired as an appearance variant.

## Icon Composer package status

The supplied `AppIcon.icon` package was opened in Icon Composer 27.1, which rejected it because its data is not in the expected format. It is preserved as a draft, but it is not used by the Xcode target. To use the layered design later, create a valid document in Icon Composer and import the unchanged SVGs from `SourceLayers/`.

Apple's app icon workflow is documented at [Creating your app icon using Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).
