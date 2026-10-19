# Environment Audit

**Дата:** 2026-10-20 (Europe/Moscow)  
**Проект:** DockFolders  
**Общий статус:** **READY**

Аудит выполнен только диагностическими командами. Программы и зависимости не устанавливались и не обновлялись; конфигурация системы и исходный код не менялись.

## Сводка версий

| Component | Installed Version | Latest Stable Version | Compatibility | Update Required | Status |
|---|---|---|---|---|---|
| macOS | 27.0.1 (26A434), arm64 | 27.0.1 | Соответствует целевой macOS 27 | Нет | UP TO DATE |
| Xcode | Xcode 27.1 (27A9275), `/Applications/Xcode.app` | Xcode 27.1; 27.2 beta 3 — предварительная | Запускается, macOS 27 SDK доступен, лицензия принята | Нет | UP TO DATE |
| Xcode Command Line Tools | 27.0.0.0.1788430756 | 27.0.x (точная последняя стабильная версия отдельно не подтверждена) | Инструменты доступны, но не заменяют полноценный Xcode для данного приложения | Проверить после установки Xcode | VERSION NOT VERIFIED |
| macOS SDK | 27.0 из Xcode | SDK 27 в составе Xcode 27.1 | `xcodebuild -showsdks` и `xcrun` подтверждают SDK | Нет | UP TO DATE |
| Swift | Apple Swift 6.4 (swiftlang-6.4.0.34.1) из Xcode 27.1 | Swift 6.4 stable toolchain included in Xcode 27.1 | Swift 6 и arm64 macOS 27 доступны | Нет | UP TO DATE |
| Swift Package Manager | 6.4.0-dev (bundled SwiftPM) | SwiftPM из Xcode 27.1 | Доступен; SwiftPM сообщает dev version, при этом Apple Swift compiler в комплекте — 6.4 | Нет для MVP | READY |
| Git | 2.54.0 (Apple Git-157) | 2.56.0 | Работоспособность локального Git подтверждена; более новая стабильная версия опубликована | Не критично для сборки | UPDATE AVAILABLE |
| GitHub CLI | 2.96.0 | 2.102.0 | Авторизация github.com успешна, протокол Git — SSH | Обновление доступно, не критично для локальной сборки | UPDATE AVAILABLE |
| Homebrew | 7.0.9 | 7.0.10 | Установлен; актуальность макOS 27 не препятствует аудиту | Обновление доступно, необязательно | UPDATE AVAILABLE |
| Codex CLI | 0.142.5 | rust-v0.163.0 (официальный последний release) | Установлен; работа выполняется из Codex Desktop, поэтому CLI обновление не требуется для этого аудита | Необязательно | UPDATE AVAILABLE |
| `codesign` | `/usr/bin/codesign` (версия отдельно не выводится) | Системный инструмент Apple; отдельный номер релиза не применим | Наличие подтверждено; подпись приложения не проверялась | Нет отдельного обновления | READY |
| GitHub remote | `git@github.com:gregkorneev/DockFolder.git`; соединение чтения успешно | Н/П | Репозиторий доступен; `gh auth status` успешен, область `repo` присутствует. Push фактически не выполнялся | Не проверено фактической отправкой | PARTIALLY READY |
| Git состояние | Ветка `main`, 0 коммитов; удалённая ветка `main` отсутствует | Н/П | Пустая локальная история и не обнаружены remote branches; GitHub Wiki включена | Нужна исходная история/проверка владельца репозитория перед записью и push | PARTIALLY READY |
| Xcode test tooling | `xcodebuild` из Xcode 27.1 | В составе Xcode 27.1 | Доступен после завершения первого запуска; Simulator runtime не установлен, но macOS-host сборки/тесты доступны | Нет для macOS-only MVP | READY |
| Средства мультиагентной работы | Codex Desktop и инструменты делегирования доступны в сессии | Н/П | Возможность делегирования подтверждена; работа на этом шаге не делегировалась | Нет | READY |
| Свободное место | 84 GiB доступно из 460 GiB | Н/П | Достаточно для установки Xcode и сборочных артефактов | Нет | READY |

\* Swift.org сообщает о стабильной линейке Swift 6.4, а официальный установочный каталог показывает 6.4.1 как текущий стабильный выпуск (на 2026-10-20). Для macOS-разработки предпочтителен комплект Swift, поставляемый с Xcode, а не отдельная установка toolchain.

## Критические проблемы

- Xcode 27.1 установлен в `/Applications/Xcode.app` и выбран активным Developer Directory `/Applications/Xcode.app/Contents/Developer`.
- Xcode 27.1, SDK 27.0 и `xcodebuild` подтверждены после завершения первого запуска и принятия лицензии.
- Локальный и удалённый `main` теперь содержат базовый коммит аудита.

## Некритические проблемы

- Git, GitHub CLI, Homebrew и Codex CLI отстают от обнаруженных последних stable релизов. Они не являются блокерами сборки приложения.
- На компьютере установлена macOS 27.0.1 на Apple Silicon, что соответствует минимальной целевой платформе macOS 27 / arm64.
- Наличие `/usr/bin/codesign` подтверждено, однако сертификаты подписи, entitlements и sandbox разрешения не проверялись.
- Liquid Glass, `NSPanel`, `NSWindow`, `NSWorkspace`, ServiceManagement и IPC API ещё не проверялись через локальный Xcode SDK. Наличие конкретных символов API не предполагается.

## Инструменты и репозиторий

- `sw_vers`: macOS 27.0.1, сборка 26A434.
- `uname -m`: arm64.
- `xcode-select -p`: `/Applications/Xcode.app/Contents/Developer`.
- `xcodebuild -version`: Xcode 27.1 (27A9275).
- `xcodebuild -showsdks`: macOS SDK 27.0 доступен.
- `xcrun --sdk macosx --show-sdk-version`: 27.0.
- `swift --version`: Apple Swift 6.4.0-dev, target `arm64-apple-macosx27.0.0`.
- `swift package --version`: Swift Package Manager 6.4.0-dev.
- `git status`: чистая ветка `main`, синхронизирована с `origin/main`.
- `git remote -v`: SSH remote `gregkorneev/DockFolder`; push аудита завершён.
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

1. Повторно проверять совместимость Xcode и SDK перед переходом на следующую платформенную версию и перед релизом.
2. Использовать Swift toolchain из Xcode; отдельный Swift toolchain не устанавливать.
4. Не устанавливать отдельный Swift toolchain, если комплект Xcode соответствует требованиям проекта.

## Непроверенные сценарии

- Сборка, unit/UI tests, доступность macOS 27 API в SwiftUI/AppKit, подпись, sandbox permissions, запуск приложения и push.
- Эти проверки выполняются по мере появления исходников приложения; платформенные сборочные инструменты готовы.
