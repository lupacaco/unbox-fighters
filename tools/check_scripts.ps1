# Parse-checks every GDScript in the project with a headless Godot run.
# Usage: pwsh tools/check_scripts.ps1 [path-to-godot.exe]
param(
    [string]$Godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.1-stable_win64_console.exe"
)

# Godot writes its banner to stderr, which must not abort the loop.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$targets = @('scripts', 'addons/part_magnet_editor') | Where-Object { Test-Path $_ }
$files = Get-ChildItem -Recurse -Filter *.gd -Path $targets |
    ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') }

$failed = 0
foreach ($file in $files) {
    $out = & $Godot --headless --path . --check-only --script $file 2>&1 |
        Select-String -Pattern 'SCRIPT ERROR|Parse Error|Compile Error'
    if ($out) {
        $failed++
        Write-Output "=== $file"
        $out | ForEach-Object { Write-Output "    $($_.Line.Trim())" }
    }
}

Write-Output "checked $($files.Count) scripts, $failed with errors"
exit ([int]($failed -gt 0))
