# =============================================================================
# stop.ps1 - Stop the AI environment (reversible)
# Stops Open WebUI container and Ollama. Run start.ps1 to resume.
# =============================================================================

. "$PSScriptRoot\config.ps1"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    [--] $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "    [!!] $msg" -ForegroundColor Yellow }

# --- 1. Stop Open WebUI container ---
Write-Step "Stopping Open WebUI container..."
$running = docker ps --format "{{.Names}}" | Where-Object { $_ -eq $WEBUI_CONTAINER }
if ($running) {
    docker stop $WEBUI_CONTAINER | Out-Null
    Write-OK "Container '$WEBUI_CONTAINER' stopped"
} else {
    Write-Skip "Container '$WEBUI_CONTAINER' is not running"
}

# --- 2. Stop Ollama ---
Write-Step "Stopping Ollama..."
$proc = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if ($proc) {
    Stop-Process -Name "ollama" -Force
    Write-OK "Ollama stopped"
} else {
    Write-Skip "Ollama is not running"
}

Write-Host "`n  Stopped. Run .\start.ps1 to resume." -ForegroundColor Green
