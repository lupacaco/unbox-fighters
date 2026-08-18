# Runs every scripts/core/verify_*.gd in a headless Godot and reports the result.
# Usage: powershell -File tools/run_checks.ps1 [path-to-godot.exe]
param(
    [string]$Godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.1-stable_win64_console.exe"
)

# Godot writes its banner to stderr, which must not abort the loop.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$files = Get-ChildItem -Path 'scripts/core' -Filter 'verify_*.gd' |
    ForEach-Object { "scripts/core/$($_.Name)" }

$failed = 0
foreach ($file in $files) {
    $out = & $Godot --headless --path . --script $file 2>&1
    $bad = $out | Select-String -Pattern 'VERIFY_FAIL|SCRIPT ERROR|Parse Error|Assertion failed'
    if ($LASTEXITCODE -ne 0 -or $bad) {
        $failed++
        Write-Output "FAIL $file"
        $bad | ForEach-Object { Write-Output "    $($_.Line.Trim())" }
    }
    else {
        Write-Output "ok   $file"
    }
}

Write-Output "ran $($files.Count) checks, $failed failed"
exit ([int]($failed -gt 0))
