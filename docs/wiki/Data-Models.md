# Data models
Русская версия: [Data-Models.ru.md](Data-Models.ru.md)


## Current persisted shape

`DockFolder` stores a UUID, name, SF Symbol, color and order, its layout preset, grid columns, icon size, glass transparency, plus an ordered array of `ApplicationItem`. `ApplicationItem` stores a UUID, display name, filesystem path, and optional bundle identifier. App settings persist named layout presets, theme, login-start preference and global hotkey preference. New folders use the standard 4 × 4 layout. Older JSON files with a default-layout field still decode; that obsolete field is ignored. JSON is versioned and written atomically under Application Support. Framework image objects are resolved at runtime and are not serialized.

## Migration, preferences, and transfer

- Old version 0.1 JSON migrates with defaults for icon, color and order while preserving IDs, names and app membership; migration is covered by a unit test.
- Login-start and hotkey preference values are user settings; actual OS registration/result is runtime state and can fail independently.
- Import/export includes the user configuration and validates supported schema before replacement.
- Validate identifiers, paths, duplicate folder IDs, duplicate app membership and supported schema before replacing active data.
- Write atomically; if decoding, migration, or import validation fails, keep the current valid file untouched and explain the error.
- Round-trip import/export and migration are covered by the 13-test suite. Keep future schema changes backward-compatible or provide explicit migrations.
