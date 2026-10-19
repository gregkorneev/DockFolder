# Git workflow

- Use the repository's current branch/worktree strategy; keep implementation isolated from `main`.
- Commit small coherent increments using Conventional Commit prefixes (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
- Before publishing a stage, inspect the diff, run relevant checks, update wiki/changelog, and confirm no local secrets or generated build products are included.
- Push only the intended branch; never force-push or rewrite shared history.
- Report branch, commit, push result, tests, and any unverified behavior accurately.
- Keep `docs/wiki/` as the canonical documentation. If the GitHub Wiki is published, sync it from this directory as a copy rather than maintaining separate content.

See the repository-level [AGENTS.md](../../AGENTS.md) for contributor rules.
