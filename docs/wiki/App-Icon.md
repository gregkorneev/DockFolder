# App icon

The DockFolders macOS app currently uses the supplied light folder-and-app-grid preview at `Design/DockFolders_IconComposer/Preview_Light.png`. The 1024 × 1024 PNG is copied unchanged to `DockFolders/Resources/Assets.xcassets/AppIcon.appiconset/DockFolders.png`; Xcode builds the standard macOS icon sizes from that source. The editable SVG layers and all alternate previews are preserved in `Design/DockFolders_IconComposer/` for future design work.

The supplied `AppIcon.icon` document was opened in Icon Composer 27.1 and rejected because its data is not in the expected format. The app target therefore uses the validated asset catalog PNG, not that draft document. The dark preview is not yet configured as an appearance variant.

Per-folder launcher apps use the folder's selected SF Symbol and color in a standard `.icns` bundle icon. Secondary symbol layers are transparent, preserving outlined details such as the `macbook` screen shown in the folder picker.

See the paired [Russian page](App-Icon.ru.md), the [design source notes](../../Design/DockFolders_IconComposer/README.md), and the [Icon Composer 27.1 import set](../../Design/DockFolders_IconComposer_27_1_Import/README_Import_Icon_Composer_27.1.md).
