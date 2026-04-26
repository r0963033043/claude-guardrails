# claude-guardrails

Personal Claude Code configuration for Windows — a hardened `.claude/` folder (permission allowlist, sensitive-file blocker, CLAUDE.md sync reminder) intended to be reused across projects on the same machine.

See [CLAUDE.md](./CLAUDE.md) for design details: hook architecture, permission model, allowed roots.

## Requirements

- Windows 10 / 11
- Windows PowerShell 5.1 (ships with Windows; PowerShell 7+ is not supported)
- Git
- Claude Code CLI

## Install

### 1. Clone the repo

The clone location must remain stable once links have been created. Example:

```cmd
git clone <repo-url> "%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails"
```

### 2. Link `.claude/` into the home directory (user-global install)

A junction at `%USERPROFILE%\.claude` pointing to the repo's `.claude/` folder makes the config user-global: Claude Code reads `%USERPROFILE%\.claude\settings.json` as the user-level config and applies it to every project on the machine.

From `cmd.exe`:

```cmd
mklink /J "%USERPROFILE%\.claude" "%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails\.claude"
```

- `/J` creates a directory junction and does not require admin rights.
- `/D` (directory symbolic link) requires Administrator or Developer Mode enabled in Windows Settings → Privacy & security → For developers.
- `mklink` refuses to overwrite an existing path; any pre-existing `%USERPROFILE%\.claude` must be removed first.

Verification:

```cmd
dir /AL "%USERPROFILE%"
```

A successful junction appears as `<JUNCTION>` pointing at the canonical repo.

> **Required settings.json change for user-global install.** The hook commands reference `$CLAUDE_PROJECT_DIR\.claude\hooks\...`, which resolves to the *current project's* `.claude\hooks\`. This is correct for per-project installs but broken for user-global — most projects have no `.claude\hooks\` of their own, so the hook script cannot be located. For user-global operation, both occurrences of `$CLAUDE_PROJECT_DIR\.claude\hooks\` in `.claude\settings.json` must be replaced with `%USERPROFILE%\.claude\hooks\`. That path resolves through the junction into the canonical repo regardless of which project Claude is launched in.

Removal:

```cmd
rmdir "%USERPROFILE%\.claude"
```

`rmdir` without `/S` removes only the junction; the canonical repo is left untouched. `rmdir /S` on a junction recurses into the real folder and is destructive — never safe for link cleanup.

---

### 2b. Alternative: per-project install

Per-project installs apply the config only to specific repos — useful when some repositories should remain outside the hook sandbox. In this mode step 2 (the home-directory junction) is skipped, and the link is created from inside each consuming project instead.

#### Option A — link the whole `.claude/` directory

Shares settings, hooks, and the sensitive-file list in a single junction. The existing `$CLAUDE_PROJECT_DIR\.claude\hooks\...` paths in `settings.json` remain correct under this mode.

```cmd
mklink /J .claude "%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails\.claude"
```

#### Option B — link individual files/folders

For projects that already contain their own `.claude/` and need only selected pieces shared:

```cmd
REM share settings.json
mklink .claude\settings.json "%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails\.claude\settings.json"

REM share the hooks folder (required when settings.json is shared, because
REM settings.json references $CLAUDE_PROJECT_DIR\.claude\hooks\*.ps1)
mklink /J .claude\hooks "%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails\.claude\hooks"
```

- File symlinks and `/D` links require admin or Developer Mode. Junctions (`/J`) do not.
- Linking `settings.json` without also linking `hooks/` breaks every tool call: the hook script at `$CLAUDE_PROJECT_DIR\.claude\hooks\restrict-paths.ps1` will not exist.

---

### 3. Verification

Attempting to read a file outside the allowed roots (for example, `C:\Windows\System32\drivers\etc\hosts`) should produce:

```
Blocked: 'C:\Windows\System32\drivers\etc\hosts' is outside allowed roots.
```

A PowerShell "file not found" error instead indicates a wrong hook path — typically Option B with the `hooks/` link missing.

## Updating the config

Edits to files in the canonical repo (`%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails`) propagate to all linked projects immediately. No re-linking is required.

## Uninstall

Per project:

```cmd
rmdir .claude               REM removes a /J junction; target is left intact
del .claude\settings.json   REM for individual file links
```

`rmdir /S` on a junction target path is destructive: it recurses into the real folder and deletes the canonical config. Not safe for link cleanup.