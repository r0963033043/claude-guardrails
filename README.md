# claude-guardrails

Personal Claude Code configuration for Windows — a hardened `.claude/` folder (permission allowlist, sensitive-file blocker, CLAUDE.md sync reminder) intended to be reused across projects on the same machine.

See [CLAUDE.md](./CLAUDE.md) for design details: hook architecture, permission model, allowed roots.

## Requirements

- Windows 10 / 11
- Windows PowerShell 5.1 (ships with Windows; PowerShell 7+ is not supported)
- Git
- Claude Code CLI

## Install model

`%USERPROFILE%\.claude\` is **not** a single junction to the repo. Files are deployed individually, with two modes:

| Source path                        | Mode | Reason |
|------------------------------------|---|---|
| `.claude\settings.json`            | **copy** | Permission rules — live behavior must not change just because the repo was edited |
| `.claude\sensitive-files.txt`      | **copy** | Pattern list consumed by the file gate — same |
| `.claude\hooks\restrict-paths.ps1` | **copy** | The security gate itself |
| `.claude\commands\`                | link | Slash-command prompts; iterated frequently |
| `.claude\memory\`                  | link | iterated frequently |

`.claude\hooks\remind-claude-md.ps1` is **not** deployed globally. It only matters when this repo *itself* is the working project, so the user-global `settings.json` drops the PostToolUse hook entry that references it (see step 4).

The repo stays the source of truth. **Copied** files require a manual re-copy after edits; **linked** files update live.

## Install

### 1. Clone the repo

```cmd
git clone <repo-url> "%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails"
```

The clone location can move later for the *copied* files, but symlinks store the absolute target — moving the repo afterwards breaks them. Pick a stable path.

### 2. Create `%USERPROFILE%\.claude\` and its subfolders

Installing Claude Code creates `%USERPROFILE%\.claude\` itself. Only the `hooks\` subfolder needs creating up front — `commands\` is *not* created here, because step 5 establishes it as a junction and `mklink /J` refuses to run if the path already exists.

```cmd
mkdir "%USERPROFILE%\.claude\hooks"
```

Skip if `hooks\` already exists.

### 3. Copy the security-critical files

```cmd
copy /Y ".claude\settings.json"             "%USERPROFILE%\.claude\settings.json"
copy /Y ".claude\sensitive-files.txt"       "%USERPROFILE%\.claude\sensitive-files.txt"
copy /Y ".claude\hooks\restrict-paths.ps1"  "%USERPROFILE%\.claude\hooks\restrict-paths.ps1"
```

### 4. Patch the copied `settings.json`

Two edits are required, **only on the copied `%USERPROFILE%\.claude\settings.json`** — leave the source `.claude\settings.json` in this repo untouched so it keeps working when this checkout is itself the project Claude is launched in.

**4a. Rewrite hook paths.** The source references `$CLAUDE_PROJECT_DIR\.claude\hooks\...`, which Claude Code expands to the *current project's* `.claude\hooks\` — wrong for a user-global install. Replace every occurrence of:

```
$CLAUDE_PROJECT_DIR\.claude\hooks\
```

with:

```
%USERPROFILE%\.claude\hooks\
```

**4b. Remove the `PostToolUse` block.** That hook entry points at `remind-claude-md.ps1`, which is not deployed globally (see Install model). If left in place, every `Write | Edit | MultiEdit | NotebookEdit` would fail because `powershell` cannot find the script. Delete the entire `"PostToolUse": [ ... ]` array from `hooks` and the trailing comma after `"PreToolUse": [ ... ]`. After both edits, `hooks` should contain only the `PreToolUse` entry pointing at `%USERPROFILE%\.claude\hooks\restrict-paths.ps1`.

### 5. Symlink the remaining folder

```cmd
mklink /J "%USERPROFILE%\.claude\commands\"    "%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails\.claude\commands\"
mklink /J "%USERPROFILE%\.claude\memory\"    "%USERPROFILE%\Desktop\Project\CLAUDE\claude-guardrails\.claude\memory\"
```

- `/J` creates a directory junction and does not require admin rights.
- `mklink` refuses to overwrite an existing path; remove any pre-existing target first.

### 6. Verification

Attempting to read a file outside the allowed roots (for example, `C:\Windows\System32\drivers\etc\hosts`) should produce:

```
Blocked: 'C:\Windows\System32\drivers\etc\hosts' is outside allowed roots.
```

A PowerShell "file not found" error instead means a hook path in the deployed `settings.json` is wrong — re-check step 4.

## Updating the config

- **Copied files** (`settings.json`, `sensitive-files.txt`, `restrict-paths.ps1`): edits in this repo do **not** propagate. Re-run the relevant `copy /Y` from step 3 after every change. For `settings.json`, re-apply the path patch from step 4.
- **Linked files** (`commands\`, `memory\`): edits propagate immediately. No re-deploy needed.

## Uninstall

```cmd
rmdir "%USERPROFILE%\.claude\commands"   REM detach junction first (no /S)
rmdir "%USERPROFILE%\.claude\memory"     REM detach junction first (no /S)
rmdir /S /Q "%USERPROFILE%\.claude"      REM safe now: junction is gone
```

The `commands\`, `memory\` junction are removed by `rmdir` *without* `/S` — that detaches the link only and leaves the source repo untouched. **Never run `rmdir /S` against the junction**: it would recurse through the link and delete the real files in the repo.

Do not `del` individual files under `%USERPROFILE%\.claude\commands\` either — those reads/writes pass through the junction to the actual repo files and would delete them at the source.
