# DockFolders 1.0 — Beta 2

## English

This beta fixes Dock folder opening and ships as a drag-to-Applications DMG.

### Changes since Beta 1

- Folder launchers no longer briefly show the main DockFolders window when opening a folder.
- Hover opening rechecks a stationary pointer when the Dock appears beneath it.
- Hover settings show whether the current app build actually has Accessibility access and monitoring resumes after access is granted.
- Folder deletion and stale launcher links preserve and show persistence errors instead of hiding them.
- The folder popup has more space below its app icons.

### Install and use

1. On an Apple Silicon Mac running macOS 27.0 or later, open `DockFolders-1.0.0-beta.2-macOS-arm64.dmg` and drag `DockFolders.app` to `Applications`. Quit an older copy before replacing it.
2. Open DockFolders and create a folder. Generate its launcher, open the generated app from `/Applications/DockFolders`, then choose **Options → Keep in Dock** from its Dock menu. Pinning is a user action controlled by macOS.
3. For optional hover opening, select **On hover** or **On click and hover** in Settings and grant the installed DockFolders app Accessibility access. Click opening does not need this permission.

The DMG contains an ad-hoc-signed, unnotarized app. macOS may require manual security approval. Accessibility permission granted to an earlier ad-hoc build may need to be granted again. Developer ID signing, notarization, clean installation and upgrades, and alternate Dock/display configurations remain unverified; this is a prerelease.

## Русский

В этой бета-версии исправлено открытие папок Dock; приложение распространяется в DMG с установкой перетаскиванием.

### Изменения после Beta 1

- При открытии папки ярлык больше не показывает на мгновение главное окно DockFolders.
- Открытие наведением повторно проверяет неподвижный курсор после появления Dock под ним.
- В настройках показано, действует ли разрешение «Универсальный доступ» для текущей сборки; после выдачи доступа мониторинг возобновляется.
- Ошибки сохранения при удалении папки и устаревших ссылках ярлыка остаются видны пользователю.
- Под значками приложений во всплывающей папке стало больше места.

### Установка и использование

1. На Mac с Apple Silicon и macOS 27.0 или новее откройте `DockFolders-1.0.0-beta.2-macOS-arm64.dmg` и перетащите `DockFolders.app` в «Программы». Перед заменой закройте прежнюю копию.
2. Откройте DockFolders и создайте папку. Создайте для неё ярлык, откройте приложение-ярлык из `/Applications/DockFolders`, затем выберите в меню Dock **Параметры → Оставить в Dock**. Закрепление выполняет сам пользователь через macOS.
3. Для открытия наведением выберите в настройках «При наведении» или «По нажатию и наведению» и разрешите установленному DockFolders доступ к «Универсальному доступу». Для открытия нажатием это разрешение не требуется.

DMG содержит приложение с временной подписью без нотариального заверения. macOS может потребовать ручного подтверждения безопасности. Разрешение, выданное прежней сборке с временной подписью, возможно, потребуется выдать заново. Подпись Developer ID, нотариальное заверение, чистая установка и обновление, а также другие конфигурации Dock и дисплеев ещё не проверены; это предварительный релиз.

SHA-256 / Контрольная сумма DMG: `c175415109bb6aa46de3064f85dd45eeb5042d1054bc7f8a6176267fed1015c1`
