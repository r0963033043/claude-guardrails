$raw = [Console]::In.ReadToEnd()
try { $payload = $raw | ConvertFrom-Json } catch { exit 0 }

$p = $payload.tool_input.file_path
if ([string]::IsNullOrEmpty($p)) { exit 0 }

try { $abs = [System.IO.Path]::GetFullPath($p) } catch { exit 0 }

$cmp = [System.StringComparison]::OrdinalIgnoreCase
$name = [System.IO.Path]::GetFileName($abs)

if ($name.Equals('CLAUDE.md', $cmp)) { exit 0 }

$cwd = [System.IO.Path]::GetFullPath((Get-Location).Path)
$claudeDir = Join-Path $cwd '.claude'

if (-not $abs.StartsWith($claudeDir + '\', $cmp)) { exit 0 }

$memoryDir = Join-Path $claudeDir 'memory'
if ($abs.StartsWith($memoryDir + '\', $cmp)) { exit 0 }

[Console]::Error.WriteLine("Reminder: '$abs' under .claude/ was modified. Review CLAUDE.md and update the relevant section (permissions, hooks, sensitive patterns, allowed roots) so the documentation stays in sync.")

$relative = $abs.Substring($claudeDir.Length + 1)
$globallyDeployed = @('settings.json', 'sensitive-files.txt', 'hooks\restrict-paths.ps1')
if ($globallyDeployed -contains $relative) {
    [Console]::Error.WriteLine("Reminder: '$relative' is also deployed to '%USERPROFILE%\.claude\$relative'. ASK the user in this turn whether to sync the global copy — do not sync automatically. If the user confirms, perform the sync using Claude Code's Read + Write/Edit tools so the write passes through the file-edit hook.")
    if ($relative -eq 'settings.json') {
        [Console]::Error.WriteLine("  Patches to apply if/when writing the global settings.json: (a) every PreToolUse hook command must become 'cmd /c powershell -NoProfile -ExecutionPolicy Bypass -File `"%USERPROFILE%\.claude\hooks\<scriptname>`"' — the 'cmd /c' wrapper is required so cmd expands '%USERPROFILE%' before handing the resolved path to PowerShell (PowerShell does not expand env vars in -File arguments); (b) omit the entire 'PostToolUse' block (remind-claude-md.ps1 is not deployed globally).")
    }
}

exit 2