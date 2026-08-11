# Serve the exported web build on localhost (Windows PowerShell).
# Usage: powershell -File tools/serve_web.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$web = Join-Path $root "builds\web"
$port = 8080

if (-not (Test-Path (Join-Path $web "index.html"))) {
	Write-Host "Pasta builds/web ainda nao existe ou esta vazia."
	Write-Host "Exporte primeiro (Godot -> Export -> Web) ou rode: tools/export_web.ps1"
	exit 1
}

Write-Host "Servindo Unbox Fighters em http://localhost:$port"
Write-Host "Pasta: $web"
Write-Host "Ctrl+C para parar."
Set-Location $web
python -m http.server $port
