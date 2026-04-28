---
name: Default to writing memories to global location
description: New memories default to %USERPROFILE%\.claude\memory\ (global) rather than the per-project memory dir, unless the rule is genuinely project-specific.
type: feedback
---

When saving a new memory, the default destination is the global memory directory `%USERPROFILE%\.claude\memory\` (with its index `MEMORY.md`), **not** the per-project memory dir under `~/.claude/projects/<project-id>/memory/`. Only write to the per-project memory dir when the memory is clearly tied to a single repo (e.g., a fact about that codebase's architecture, a project-specific deadline, a reference to that project's tracker).

**Why:** Most feedback rules (commit-message style, doc voice, file-edit flow) apply to any project the user works on, so they should follow the user across repos rather than living inside one project's memory.

**How to apply:**
- New `feedback`/`reference` memories → global by default.
- New `project` memories → per-project (they're inherently scoped).
- New `user` memories → global by default (the user is the same across projects).
- When in doubt, prefer global; only narrow to per-project when the rule would be misleading or wrong outside this repo.
- Always show the user the file path + content before writing (per the existing file-edit-flow rule).
