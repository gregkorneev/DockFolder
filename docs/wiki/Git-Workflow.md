# Git workflow
Русская версия: [Git-Workflow.ru.md](Git-Workflow.ru.md)


- The project owner has requested that all work be done directly on `main`.
- Commit small coherent increments using Conventional Commit prefixes (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
- Before publishing a stage, inspect the diff, run relevant checks, update wiki/changelog, and confirm no local secrets or generated build products are included.
- Push completed work to `origin/main`; never force-push or rewrite shared history.
- Report branch, commit, push result, tests, and any unverified behavior accurately.
- Keep `docs/wiki/` as the canonical documentation. If the GitHub Wiki is published, sync it from this directory as a copy rather than maintaining separate content.

See the repository-level [AGENTS.md](../../AGENTS.md) for contributor rules.
