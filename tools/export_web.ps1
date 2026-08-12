# Export Unbox Fighters to Web (HTML5) using Godot 4.7.1.
# Usage: powershell -File tools/export_web.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "builds\web"
$outFile = Join-Path $outDir "index.html"

$godotCandidates = @(
	"C:\Users\luisp\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.1-stable_win64_console.exe",
	"C:\Users\luisp\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.1-stable_win64.exe",
	"C:\Users\luisp\OneDrive\Desktop\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
	"C:\Users\luisp\OneDrive\Desktop\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"
)
$godot = $godotCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $godot) {
	Write-Host "Godot 4.7.1 nao encontrado. Ajuste o caminho em tools/export_web.ps1"
	exit 1
}

$templates = Join-Path $env:APPDATA "Godot\export_templates\4.7.1.stable\web_release.zip"
if (-not (Test-Path $templates)) {
	Write-Host "Templates web 4.7.1.stable nao encontrados em:"
	Write-Host "  $templates"
	Write-Host "Baixe os Export Templates no Godot (Editor -> Manage Export Templates)."
	exit 1
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Write-Host "Exportando Web (debug) para $outFile ..."
& $godot --headless --path $root --export-debug "Web" $outFile
if ($LASTEXITCODE -ne 0) {
	Write-Host "Export falhou com codigo $LASTEXITCODE"
	exit $LASTEXITCODE
}

if (-not (Test-Path $outFile)) {
	Write-Host "Export terminou, mas index.html nao apareceu."
	exit 1
}

Write-Host "OK. Para jogar no navegador:"
Write-Host "  powershell -File tools/serve_web.ps1"
Write-Host "Depois abra http://localhost:8080"
