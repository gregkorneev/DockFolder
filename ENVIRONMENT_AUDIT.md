# Environment Audit

**Дата:** 2026-10-20 (Europe/Moscow)  
**Проект:** DockFolders  
**Общий статус:** **NOT READY**

Аудит выполнен только диагностическими командами. Программы и зависимости не устанавливались и не обновлялись; конфигурация системы и исходный код не менялись.

## Сводка версий

| Component | Installed Version | Latest Stable Version | Compatibility | Update Required | Status |
|---|---|---|---|---|---|
| macOS | 27.0.1 (26A434), arm64 | 27.0.1 | Соответствует целевой macOS 27 | Нет | UP TO DATE |
| Xcode | Не установлен/не выбран; активны Command Line Tools | Xcode 27.1 (27A9275); 27.2 beta 3 — предварительная | Без полного Xcode нельзя использовать Xcode build/test и проверить полный набор SDK | Да, установить стабильный Xcode вручную после решения пользователя | NOT INSTALLED |
| Xcode Command Line Tools | 27.0.0.0.1788430756 | 27.0.x (точная последняя стабильная версия отдельно не подтверждена) | Инструменты доступны, но не заменяют полноценный Xcode для данного приложения | Проверить после установки Xcode | VERSION NOT VERIFIED |
| macOS SDK | 27.0, путь `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk` | SDK 27 в составе актуального Xcode | CLI SDK присутствует; Xcode SDK и доступность целевых API не проверены | Требуется Xcode 27.1 | PARTIALLY READY |
| Swift | 6.4.0-dev (Apple Swift 6.4.0.34.1) | Swift 6.4.1 stable* | Компилятор Swift 6 и arm64 macOS 27 доступны; dev toolchain не является целевым стабильным стеком для проекта | Использовать стабильный toolchain из Xcode 27.1 | UPDATE AVAILABLE |
| Swift Package Manager | 6.4.0-dev | Встроенный SwiftPM актуального Xcode | Команда доступна, но версия указывает на dev toolchain | Использовать SwiftPM Xcode | PARTIALLY READY |
| Git | 2.54.0 (Apple Git-157) | 2.56.0 | Работоспособность локального Git подтверждена; более новая стабильная версия опубликована | Не критично для сборки | UPDATE AVAILABLE |
| GitHub CLI | 2.96.0 | 2.102.0 | Авторизация github.com успешна, протокол Git — SSH | Обновление доступно, не критично для локальной сборки | UPDATE AVAILABLE |
| Homebrew | 7.0.9 | 7.0.10 | Установлен; актуальность макOS 27 не препятствует аудиту | Обновление доступно, необязательно | UPDATE AVAILABLE |
| Codex CLI | 0.142.5 | rust-v0.163.0 (официальный последний release) | Установлен; работа выполняется из Codex Desktop, поэтому CLI обновление не требуется для этого аудита | Необязательно | UPDATE AVAILABLE |
| `codesign` | `/usr/bin/codesign` (версия отдельно не выводится) | Системный инструмент Apple; отдельный номер релиза не применим | Наличие подтверждено; подпись приложения не проверялась | Нет отдельного обновления | READY |
| GitHub remote | `git@github.com:gregkorneev/DockFolder.git`; соединение чтения успешно | Н/П | Репозиторий доступен; `gh auth status` успешен, область `repo` присутствует. Push фактически не выполнялся | Не проверено фактической отправкой | PARTIALLY READY |
| Git состояние | Ветка `main`, 0 коммитов; удалённая ветка `main` отсутствует | Н/П | Пустая локальная история и не обнаружены remote branches; GitHub Wiki включена | Нужна исходная история/проверка владельца репозитория перед записью и push | PARTIALLY READY |
| Xcode test tooling | `xcodebuild` недоступен в активном Developer Directory | В составе Xcode 27.1 | Сборка и тесты приложения сейчас невозможны | Да | NOT INSTALLED |
| Средства мультиагентной работы | Codex Desktop и инструменты делегирования доступны в сессии | Н/П | Возможность делегирования подтверждена; работа на этом шаге не делегировалась | Нет | READY |
| Свободное место | 84 GiB доступно из 460 GiB | Н/П | Достаточно для установки Xcode и сборочных артефактов | Нет | READY |

\* Swift.org сообщает о стабильной линейке Swift 6.4, а официальный установочный каталог показывает 6.4.1 как текущий стабильный выпуск (на 2026-10-20). Для macOS-разработки предпочтителен комплект Swift, поставляемый с Xcode, а не отдельная установка toolchain.

## Критические проблемы

- Полноценный Xcode отсутствует в активном Developer Directory `/Library/Developer/CommandLineTools`. `xcodebuild -version` и `xcodebuild -showsdks` завершаются ошибкой. Сборку SwiftUI/AppKit-приложения, запуск `xcodebuild` тестов и проверку APIs macOS 27 выполнить нельзя.
- ТЗ требует остановиться, если критические компоненты не установлены или несовместимы. Поэтому проектирование и реализация MVP не начинались.
- Репозиторий не содержит коммитов, а удалённая ветка `main` и другие ветки не обнаружены. Фактический push невозможен, пока не появится базовая история/ветка.

## Некритические проблемы

- Git, GitHub CLI, Homebrew и Codex CLI отстают от обнаруженных последних stable релизов. Они не являются блокерами сборки приложения.
- На компьютере установлена macOS 27.0.1 на Apple Silicon, что соответствует минимальной целевой платформе macOS 27 / arm64.
- Наличие `/usr/bin/codesign` подтверждено, однако сертификаты подписи, entitlements и sandbox разрешения не проверялись.
- Liquid Glass, `NSPanel`, `NSWindow`, `NSWorkspace`, ServiceManagement и IPC API не проверялись по локальному Xcode SDK, поскольку Xcode не установлен/не выбран. Наличие конкретных символов API не предполагается.

## Инструменты и репозиторий

- `sw_vers`: macOS 27.0.1, сборка 26A434.
- `uname -m`: arm64.
- `xcode-select -p`: `/Library/Developer/CommandLineTools`.
- `xcrun --sdk macosx --show-sdk-version`: 27.0.
- `swift --version`: Apple Swift 6.4.0-dev, target `arm64-apple-macosx27.0.0`.
- `swift package --version`: Swift Package Manager 6.4.0-dev.
- `git status`: `main`, без tracked/untracked изменений до создания этого отчёта; 0 коммитов. `origin/main` отсутствует на сервере.
- `git remote -v`: SSH remote `gregkorneev/DockFolder`; `git ls-remote --heads origin` не вернул refs.
- `gh auth status`: вход в `github.com` как `gregkorneev`, Git по SSH, scope `repo`.
- GitHub сообщает, что Wiki включена. CI/CD и содержимое удалённой Wiki не исследовались на этом этапе.
- Свободно 84 GiB.

## Последние версии, проверенные онлайн

| Component | Последняя стабильная версия | Источник |
|---|---|---|
| macOS | 27.0.1 | [Apple Developer Releases](https://developer.apple.com/news/releases/) |
| Xcode | 27.1 (27A9275), 2026-10-15; последняя beta — 27.2 beta 3 | [Xcode 27.1 release](https://developer.apple.com/news/releases/?id=10152026a), [Xcode Release Notes](https://developer.apple.com/documentation/xcode-release-notes) |
| Swift | 6.4.1 stable (каталог официальных выпусков); 6.4 объявлен stable | [Swift 6.4 announcement](https://www.swift.org/blog/swift-6.4-released/), [Swift install for macOS](https://www.swift.org/install/macos/) |
| Git | 2.56.0 | [git-scm.com](https://git-scm.com/) |
| GitHub CLI | v2.102.0 (2026-09-30) | [GitHub CLI releases](https://github.com/cli/cli/releases) |
| Homebrew | 7.0.10 (2026-10-19) | [Homebrew release](https://github.com/Homebrew/brew/releases/tag/7.0.10) |
| Codex CLI | rust-v0.163.0 (2026-10-15) | [OpenAI Codex releases](https://github.com/openai/codex/releases) |

На странице релизов Apple указана Xcode 27.2 beta 3 как более новая предварительная версия; она не рекомендуется для рабочей среды по условиям ТЗ. Команды установки или обновления не запускались.

## Рекомендуемые действия

1. Установить стабильный Xcode 27.1 обычным способом и выбрать его Developer Directory (`xcode-select`), затем принять лицензию/завершить первоначальную настройку, если система этого потребует.
2. Повторить `xcodebuild -version`, `xcodebuild -showsdks`, `xcrun --sdk macosx --show-sdk-version` и `swift --version`; подтвердить Xcode 27.1, SDK 27 и стабильный Swift 6 toolchain.
3. После прохождения критического аудита определить ожидаемую базовую ветку для пустого GitHub-репозитория и только затем планировать коммиты и push.
4. Не устанавливать отдельный Swift toolchain, если комплект Xcode соответствует требованиям проекта.

## Непроверенные сценарии

- Сборка, unit/UI tests, доступность macOS 27 API в SwiftUI/AppKit, подпись, sandbox permissions, запуск приложения и push.
- Эти проверки отложены до установки/выбора Xcode и появления базовой Git истории.
