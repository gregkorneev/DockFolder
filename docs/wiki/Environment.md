# Окружение разработки
English version: [Environment.en.md]


Последняя проверка: **2026-10-20**. Подробный аудит находится в [ENVIRONMENT_AUDIT.md](../../ENVIRONMENT_AUDIT.md).

## Статус

**READY**: Xcode 27.1 и macOS SDK 27 доступны, лицензия принята, `xcodebuild` работает. Проект можно собирать и тестировать.

## Проверенное локальное окружение

- macOS 27.0.1 (26A434), Apple Silicon arm64.
- Xcode 27.1 (27A9275) в `/Applications/Xcode.app`; активный Developer Directory — `/Applications/Xcode.app/Contents/Developer`.
- macOS SDK 27.0; Command Line Tools 27.0.
- Apple Swift 6.4 и SwiftPM 6.4.0-dev из выбранного Xcode toolchain.
- Git 2.54.0, GitHub CLI 2.96.0 (авторизация есть), Homebrew 7.0.9, Codex CLI 0.142.5.
- Свободно 84 GiB; `/usr/bin/codesign` доступен.
- Репозиторий и его GitHub-история изменились после первоначальной проверки. Git/remote/push-состояние следует проверять непосредственно перед публикацией, а не считать эту строку исторического аудита текущим статусом.

## Действие для возобновления

Повторно проверять совместимость Xcode и SDK перед переходом на следующую платформенную версию и перед релизом.

## Последняя проверка stable версий

- Xcode 27.1 stable; 27.2 beta 3 — предварительная.
- Swift 6.4 stable release line; официальный каталог показывает 6.4.1 как stable.
- Git 2.56.0, GitHub CLI 2.102.0, Homebrew 7.0.10, Codex CLI rust-v0.163.0.

Ссылки на официальные источники и сравнение установленных версий приведены в [ENVIRONMENT_AUDIT.md](../../ENVIRONMENT_AUDIT.md).
