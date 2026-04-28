---
name: Git commit messages use Conventional Commits
description: Follow the Conventional Commits format (type(scope): subject) when authoring git commit messages
type: feedback
---

Git commit messages must follow the Conventional Commits format: `<type>(<optional scope>): <subject>`, where `<type>` is one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, or `revert`. The subject is in imperative mood with no trailing period. Case is not constrained — follow the spec, which does not mandate capitalization.

Examples:
- `feat: add per-call file-removal prompts`
- `fix(hooks): resolve $env:USERPROFILE before PowerShell receives -File`
- `docs: clarify allowed roots in CLAUDE.md`

**Why:** The user asked for the Standard Format (Conventional Commits) for commits. They did not specify a case preference, so do not impose one.

**How to apply:** Whenever drafting a `git commit` message in any repo, produce subject lines in this shape. If a repo's recent `git log` shows a clearly different convention (e.g., non-Conventional, or a strongly enforced case style), surface the conflict to the user before deviating.
