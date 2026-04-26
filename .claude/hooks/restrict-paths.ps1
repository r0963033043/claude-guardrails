$raw = [Console]::In.ReadToEnd()
try { $payload = $raw | ConvertFrom-Json } catch { exit 0 }

$p = $payload.tool_input.file_path
if ([string]::IsNullOrEmpty($p)) { exit 0 }

try { $abs = [System.IO.Path]::GetFullPath($p) } catch { $abs = $p }

$cmp = [System.StringComparison]::OrdinalIgnoreCase

$sensitiveFile = Join-Path (Split-Path $PSScriptRoot -Parent) 'sensitive-files.txt'
if (Test-Path $sensitiveFile) {
    $name = [System.IO.Path]::GetFileName($abs)
    foreach ($line in Get-Content $sensitiveFile) {
        $pat = $line.Trim()
        if (-not $pat -or $pat.StartsWith('#')) { continue }
        if ($name -like $pat -or $abs -like $pat) {
            [Console]::Error.WriteLine("Blocked: '$abs' matches sensitive pattern '$pat'")
            exit 2
        }
    }
}

$allowed = @(
    "$env:USERPROFILE\Desktop\Project\CLAUDE",
    "$env:USERPROFILE\.claude"
)

foreach ($root in $allowed) {
    $rootAbs = [System.IO.Path]::GetFullPath($root)
    if ($abs.Equals($rootAbs, $cmp) -or $abs.StartsWith($rootAbs + '\', $cmp)) {
        exit 0
    }
}

[Console]::Error.WriteLine("Blocked: '$abs' is outside allowed roots. Allowed: $($allowed -join '; ')")
exit 2