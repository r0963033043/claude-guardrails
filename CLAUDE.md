# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code configuration project — there is no application code, no build, lint, or test commands. The repo's purpose is to configure the Claude Code CLI itself via `.claude/settings.json` and supporting hook scripts. Treat edits here as edits to Claude's own runtime behavior for this workspace.

**The hook scripts are Windows-only.** PowerShell hooks (`.ps1`), `settings.json` hook commands, and any path-handling logic assume a Windows host — do not refactor those for portability across operating systems. Non-script content (markdown docs, slash command prompts in `.claude/commands/`, `sensitive-files.txt` patterns) is OS-agnostic and can be edited without Windows-specific concerns.

## Host assumption

The PreToolUse hook invokes `powershell -NoProfile -ExecutionPolicy Bypass`, so this configuration assumes a **Windows host** with Windows PowerShell 5.1 available. Anything that would not work under that shell (for example, PowerShell 7+ syntax, or POSIX shell features) will break the sandbox. Paths use Windows separators (`\`) and environment variables use PowerShell form (`$env:USERPROFILE`).

Hook commands in `settings.json` reference their scripts via `$CLAUDE_PROJECT_DIR\.claude\hooks\...` rather than a CWD-relative path. `$CLAUDE_PROJECT_DIR` is expanded by Claude Code before handing the command to the shell, so the hook resolves correctly regardless of the shell's working directory. Do not replace it with a bare relative path like `.claude\hooks\...` — that breaks if Claude is launched from a subdirectory.

## Architecture: how file access is gated

Every `Read | Write | Edit | MultiEdit | NotebookEdit` call goes through `.claude/hooks/restrict-paths.ps1` as a `PreToolUse` hook (wired in `.claude/settings.json`). The script:

1. Reads the tool payload from stdin, extracts `tool_input.file_path`, resolves it to an absolute path.
2. Loads `.claude/sensitive-files.txt` (one level up from the hook script) and rejects (exit 2) if the filename **or** the full absolute path matches any pattern — case-insensitive, wildcards `*` / `?` via PowerShell `-like`, `#` lines are comments.
3. Otherwise accepts only paths under the two allowed roots:
   - `$env:USERPROFILE\Desktop\Project\CLAUDE`
   - `$env:USERPROFILE\.claude`

Anything else → exit 2 with a "Blocked: ... outside allowed roots" message on stderr. Exit 0 means allow.

Implication: before suggesting an edit outside these roots, expect it to be blocked. The allowed roots use `$env:USERPROFILE` specifically so the config is portable across users — do not reintroduce hardcoded usernames.

**Known gap**: the hook matcher only covers the file-editing tools above. `Bash` (e.g. `cat`, `type`, `grep`) and web tools are **not** intercepted, so sensitive files can still leak through those paths. If tightening is requested, either extend the matcher in `settings.json` to include `Bash`, or add explicit `deny` rules there (e.g. `Bash(cat *.env*)`).

## Permission model in settings.json

`permissions.allow` is intentionally tight — only a short list of read-only commands (`ls`, read-only `git` subcommands like `status`, `log`, `diff`, `show`, `blame`, `ls-files`, `remote`, `rev-parse`, `config --get/--list`, and the listing forms of `git branch`) is pre-approved. Everything else prompts the user.

`permissions.ask` currently contains `Bash(git add)` — staging always prompts even though it is non-destructive, to give a checkpoint before any commit flow. Keep mutating-but-recoverable commands here rather than in `allow`.

`permissions.deny` hard-blocks these classes (deny overrides allow):

- **Repo mutation**: `git commit`, `git commit *`, `git push`, `git push *`.
- **All of `git branch *`**: every `git branch` invocation that carries any argument is denied, because `git branch <name>` creates a branch. Read-only listings work only because their exact forms (`git branch`, `git branch -a`, `--list`, `--show-current`, etc.) are matched by explicit `allow` entries before the broad deny wildcard can be considered. When adding a new read-only `git branch` variant, add the exact pattern to `allow`; do not loosen the deny.

When adding permissions, prefer narrow prefix patterns (`Bash(git status*)`) over broad ones (`Bash(git *)`), and keep the `deny` list as the final authority for anything that must never run.

## PostToolUse: CLAUDE.md sync reminder

A second hook, `.claude/hooks/remind-claude-md.ps1`, runs after every `Write | Edit | MultiEdit | NotebookEdit`. If the written file is under `.claude/` (and is not `CLAUDE.md` itself), the hook exits 2 and emits a stderr reminder. Claude receives that stderr as feedback and must update the relevant CLAUDE.md section (permissions, hooks, sensitive patterns, allowed roots) in the same turn so the documentation stays synchronized with the configuration. This rule is enforced by the harness, not by Claude's memory — do not disable the hook to skip the update.

## Editing the sensitive-file list

`.claude/sensitive-files.txt` is the single source of truth for blocked patterns. It lives at the top of `.claude/` because it is shared config. Add one pattern per line. Because the hook tests both basename and full path, a bare pattern like `*.env` blocks `.env` anywhere under the allowed roots without needing a path prefix.

This file has a second consumer: the `/code-review` command (`.claude/commands/code-review.md`) cross-references it when flagging sensitive data in a diff. Patterns added here therefore also tighten review-time secret detection, not just the file-edit gate.

## Custom slash commands

`.claude/commands/` holds markdown files that define custom slash commands. Each filename (minus `.md`) becomes the command name — `code-review.md` → `/code-review`. Front-matter (`description`, `argument-hint`, optionally `allowed-tools`) configures how the command surfaces in the UI; the markdown body is the prompt that runs when the command is invoked. These commands are prompts, not documentation, so imperative voice is appropriate inside them (the no-second-person rule for doc files does not apply here).