# DockFolders — safe import into Apple Icon Composer 27.1

Russian version: [README_Import_Icon_Composer_27.1.ru.md](README_Import_Icon_Composer_27.1.ru.md).

## Draft status

This set preserves SVG layers, transparent PNGs, previews, and the draft package `Drag_to_Icon_Composer/Untitled.icon`. Opening and saving that package in Icon Composer 27.1 has not been verified; the Xcode target does not use it. For a reliable import, create a new `.icon` document in Apple Icon Composer and import the supplied layers.

## Recommended import workflow

1. Open **Icon Composer** 27.1.
2. Choose **File → New**. If needed, select only macOS in the document settings.
3. Save the new document as `AppIcon.icon`.
4. In the editor, choose **+ → New Image**.
5. Import the SVGs from `Layers_SVG` in this order:
   - `01_FolderBack.svg` — folder back;
   - `02_FolderFront.svg` — folder front;
   - `03_AppGrid.svg` — app tiles.
6. Place layers in separate groups if you want to control the glass treatment independently.
7. Verify the layer order from back to front: 01 → 02 → 03.
8. Choose a light Default background and a dark Dark background; check that the tiles remain legible in Mono.
9. Configure glass, refraction, shadows, and reflections in Icon Composer.
10. Save the document created by Icon Composer.

Alternatively, drag the folders from `Drag_to_Icon_Composer` into Icon Composer's sidebar, then verify the imported group order.

## If SVG import fails

Use the matching transparent 1024 × 1024 PNGs in `Layers_PNG`. Their layer coordinates match the SVGs.

## Add the icon to Xcode

Add the `.icon` document created in Icon Composer to the Xcode project navigator. In target → General → App Icons and Launch Screen, select `AppIcon`. Confirm that the target uses the intended icon rather than an older entry in `Assets.xcassets`.

## Checks and limitations

- SVG layers use the same 1024 × 1024 canvas; the PNG layers have transparency.
- Opening and saving the package in Apple Icon Composer 27.1 has not been verified.
- The files in `Previews` are static images, not confirmed Icon Composer renders.

Official Apple guide: [Creating your app icon using Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).
