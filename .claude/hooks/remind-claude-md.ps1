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

[Console]::Error.WriteLine("Reminder: '$abs' under .claude/ was modified. Review CLAUDE.md and update the relevant section (permissions, hooks, sensitive patterns, allowed roots) so the documentation stays in sync.")
exit 2