# Окружение разработки

Последняя проверка: **2026-10-20**. Подробный аудит находится в [ENVIRONMENT_AUDIT.md](../../ENVIRONMENT_AUDIT.md).

## Статус

**PARTIALLY READY**: Xcode 27.1 установлен и выбран активным Developer Directory, но лицензия Xcode ещё не принята. `xcodebuild` и SDK-проверки заблокированы до принятия соглашения. Сборка и тестирование отложены.

## Проверенное локальное окружение

- macOS 27.0.1 (26A434), Apple Silicon arm64.
- Xcode 27.1 (27A9275) в `/Applications/Xcode.app`; активный Developer Directory — `/Applications/Xcode.app/Contents/Developer`.
- Command Line Tools 27.0; SDK-проверку через Xcode требуется повторить после принятия лицензии.
- Apple Swift 6.4.0-dev и SwiftPM 6.4.0-dev.
- Git 2.54.0, GitHub CLI 2.96.0 (авторизация есть), Homebrew 7.0.9, Codex CLI 0.142.5.
- Свободно 84 GiB; `/usr/bin/codesign` доступен.
- GitHub remote доступен для чтения, но локальный репозиторий без коммитов, remote refs отсутствуют; Wiki включена.

## Действие для возобновления

Открыть Xcode, принять лицензионное соглашение и завершить начальную настройку, если система её запросит. После этого повторить проверку Xcode, SDK и Swift. Установка/обновление не выполнялись в рамках аудита.

## Последняя проверка stable версий

- Xcode 27.1 stable; 27.2 beta 3 — предварительная.
- Swift 6.4 stable release line; официальный каталог показывает 6.4.1 как stable.
- Git 2.56.0, GitHub CLI 2.102.0, Homebrew 7.0.10, Codex CLI rust-v0.163.0.

Ссылки на официальные источники и сравнение установленных версий приведены в [ENVIRONMENT_AUDIT.md](../../ENVIRONMENT_AUDIT.md).
