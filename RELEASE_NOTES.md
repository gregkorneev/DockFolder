# DockFolders 1.0 — Beta 2

## English

Beta 2 adds editable folder grids and includes fixes to folder launcher startup, hover opening, and persistence error handling.

### What's new

- Set each folder's row and column counts independently from 1 to 10. A value of 0 is clamped to 1.
- Custom grids keep their selected size. Scroll the folder popup to reach apps beyond its visible cells or available screen area.
- Hover settings report whether Accessibility access applies to the current build and resume monitoring after access is granted.
- Fixed hover opening when the Dock appears under a stationary pointer, and prevented a brief main-window flash when opening a folder launcher.
- Improved error handling when folders cannot be saved or launcher links contain stale data.

### Install and use

1. On an Apple Silicon Mac running macOS 27.0 or later, open `DockFolders-1.0.0-beta.2-macOS-arm64.dmg` and drag `DockFolders.app` to `Applications`. Quit an older copy before replacing it.
2. Open DockFolders and create a folder. Generate its launcher, open the generated app from `/Applications/DockFolders`, then choose **Options → Keep in Dock** from its Dock menu. Pinning is a user action controlled by macOS.
3. For optional hover opening, select **On hover** or **On click and hover** in Settings and grant the installed DockFolders app Accessibility access. Click opening does not need this permission.

The DMG contains an ad-hoc-signed, unnotarized app. macOS may require manual security approval. Accessibility permission granted to an earlier ad-hoc build may need to be granted again. Developer ID signing, notarization, clean installation and upgrades, and alternate Dock/display configurations remain unverified; this is a prerelease.

DMG SHA-256: `faad38481d47a262cd3f63b1d79d9d7e9a2d275ab8256596c95e50b0393832cf`

## Русский

В Beta 2 появились настраиваемые сетки папок, а также исправления запуска ярлыка папки, открытия наведением и обработки ошибок сохранения.

### Изменения

- Для каждой папки можно отдельно задать число строк и столбцов от 1 до 10. Значение 0 ограничивается единицей.
- Пользовательская сетка сохраняет выбранный размер. Прокручивайте popup, чтобы открыть приложения, которые не помещаются в видимые ячейки или на экран.
- В настройках наведения показано, действует ли разрешение «Универсальный доступ» для текущей сборки; после выдачи разрешения мониторинг возобновляется.
- Исправлено открытие наведением, когда Dock появляется под неподвижным курсором; при запуске ярлыка папки главное окно больше не мигает.
- Улучшена обработка ошибок, если папку не удаётся сохранить или ссылка ярлыка содержит устаревшие данные.

### Установка и использование

1. На Mac с Apple Silicon и macOS 27.0 или новее откройте `DockFolders-1.0.0-beta.2-macOS-arm64.dmg` и перетащите `DockFolders.app` в «Программы». Перед заменой закройте прежнюю копию.
2. Откройте DockFolders и создайте папку. Создайте для неё ярлык, откройте приложение-ярлык из `/Applications/DockFolders`, затем выберите в меню Dock **Параметры → Оставить в Dock**. Закрепление выполняет сам пользователь через macOS.
3. Для открытия наведением выберите в настройках «При наведении» или «По нажатию и наведению» и разрешите установленному DockFolders доступ к «Универсальному доступу». Для открытия нажатием это разрешение не требуется.

DMG содержит приложение с временной подписью без нотариального заверения. macOS может потребовать ручного подтверждения безопасности. Разрешение, выданное прежней сборке с временной подписью, возможно, потребуется выдать заново. Подпись Developer ID, нотариальное заверение, чистая установка и обновление, а также другие конфигурации Dock и дисплеев ещё не проверены; это предварительный релиз.

SHA-256 DMG: `faad38481d47a262cd3f63b1d79d9d7e9a2d275ab8256596c95e50b0393832cf`
