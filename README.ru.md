# DockFolders

DockFolders — нативное приложение macOS для организации установленных программ в пользовательские папки и запуска их из Dock. В текущей версии реализованы основные функции версии 1.0; проверка совместимости с платформой и готовности к распространению ещё не завершена.

## Реализованные функции

- Создание, переименование и удаление папок.
- Поиск установленных приложений и добавление/удаление их из папок.
- Запуск приложений из папки.
- Локальное сохранение папок и настроек между запусками.
- Интерфейс и стандартные сообщения приложения локализованы на английский и русский; macOS выбирает язык по предпочтительным языкам пользователя.
- Нативный интерфейс SwiftUI с визуальными материалами macOS 27.
- Настройка папок с помощью SF Symbols и цветов; изменение порядка папок и приложений перетаскиванием.
- Всплывающее окно Liquid Glass с учётом положения Dock; закрывается клавишей Escape, при потере фокуса или после успешного запуска приложения.
- Настройки сетки, размера значков и темы; глобальное сочетание Control–Option–Space и запуск при входе в систему.
- Импорт и экспорт конфигурации.
- Создание приложения-ярлыка для каждой папки в `/Applications/DockFolders`; проверенные ссылки `dockfolders://folder/<UUID>` открывают нужную папку, в том числе при холодном запуске DockFolders.

Чтобы закрепить папку в Dock, создайте для неё ярлык в DockFolders, откройте созданное приложение из `/Applications/DockFolders` в Finder, затем выберите в меню значка Dock **Options → Keep in Dock**. macOS требует выполнить закрепление вручную; DockFolders не изменяет настройки Dock. Работа на нескольких дисплеях и со всеми положениями Dock, доступность и уменьшение движения, фактическая регистрация запуска при входе, конфликты сочетаний клавиш, а также подпись и нотариальное заверение ещё не проверены.

## Требования

- macOS 27.0 или новее, Apple Silicon.
- Xcode 27.1 или новее с macOS SDK.

Откройте `DockFolders.xcodeproj` в Xcode, выберите схему DockFolders и назначение My Mac, затем выполните сборку и запуск. Проверка из командной строки:

```sh
xcodebuild -list -project DockFolders.xcodeproj
xcodebuild -project DockFolders.xcodeproj -scheme DockFolders -destination 'platform=macOS' build
xcodebuild -project DockFolders.xcodeproj -scheme DockFolders -destination 'platform=macOS' test
```

## Документация проекта

- Архитектура и область проекта: [docs/wiki/Architecture.md](docs/wiki/Architecture.md) · [русский](docs/wiki/Architecture.ru.md)
- План реализации: [docs/wiki/Implementation-Plan.md](docs/wiki/Implementation-Plan.md) · [русский](docs/wiki/Implementation-Plan.ru.md)
- Ограничения Dock: [docs/wiki/Dock-Integration.md](docs/wiki/Dock-Integration.md) · [русский](docs/wiki/Dock-Integration.ru.md)
- Объём и состояние работ: [docs/wiki/Roadmap.md](docs/wiki/Roadmap.md) · [русский](docs/wiki/Roadmap.ru.md)
- Модель данных: [docs/wiki/Data-Models.md](docs/wiki/Data-Models.md) · [русский](docs/wiki/Data-Models.ru.md)
- Тестирование и критерии приёмки: [docs/wiki/Testing.md](docs/wiki/Testing.md) · [русский](docs/wiki/Testing.ru.md)
- Аудит окружения: [ENVIRONMENT_AUDIT.md](ENVIRONMENT_AUDIT.md) · [English](ENVIRONMENT_AUDIT.en.md)

Русская версия этого файла: [README.ru.md](README.ru.md).
