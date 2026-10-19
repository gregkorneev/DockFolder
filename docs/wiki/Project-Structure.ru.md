# Структура проекта

Текущая структура реализации (уровни пакетов и каталогов):

```text
DockFolders.xcodeproj/       Xcode app и unit-test targets
DockFolders/
  App/                       SwiftUI entry и адаптер app delegate
  Models/                    Codable-значения папок, приложений и настроек
  Views/                     Боковая панель, popup, app picker/grid, настройки
  ViewModels/                 Наблюдаемое состояние папок и координация хранения
  Services/                   Поиск, запуск, хранение, ярлыки и перенос конфигурации
  Managers/                   Popup/Dock, горячая клавиша и запуск при входе
DockFoldersTests/             Модульные тесты для macOS
docs/wiki/                    Основная документация проекта
AGENTS.md                     Инструкции участникам и агентам
README.md                     Обзор приложения и сборки
CHANGELOG.md                  История выпусков в корне проекта
ENVIRONMENT_AUDIT.md          Первоначальный аудит toolchain
```

Приложения-ярлыки папок создаются во время работы в `/Applications/DockFolders`; для каждой пользовательской папки отдельная Xcode-цель не хранится в репозитории. Оставшиеся проверки платформы и распространения описаны в [дорожной карте](Roadmap.ru.md). Записывайте точные изменения файлов после проверки дерева проекта.

English version: [Project-Structure.md](Project-Structure.md).
