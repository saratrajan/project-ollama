# =============================================================================
# teardown.ps1 - Full cleanup (destructive)
# Stops and REMOVES the container and Docker volume. Models are kept.
# Run setup.ps1 to rebuild from scratch.
# =============================================================================

[CmdletBinding()]
param(
    [switch]$Yes
)

. "$PSScriptRoot\config.ps1"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    [--] $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "    [!!] $msg" -ForegroundColor Yellow }

if (-not $Yes) {
    Write-Host "`n  [!!] This will remove the Open WebUI container and its data volume." -ForegroundColor Yellow
    Write-Host "       Ollama models are NOT deleted." -ForegroundColor Yellow
    $confirm = Read-Host "`n  Continue? [y/N]"
    if ($confirm -notmatch "^[Yy]") {
        Write-Host "  Aborted." -ForegroundColor DarkGray
        exit 0
    }
}

# --- 1. Stop + remove container ---
Write-Step "Removing Open WebUI container..."
$exists = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $WEBUI_CONTAINER }
if ($exists) {
    docker rm -f $WEBUI_CONTAINER | Out-Null
    Write-OK "Container '$WEBUI_CONTAINER' removed"
} else {
    Write-Skip "Container '$WEBUI_CONTAINER' not found"
}

# --- 2. Remove Docker volume ---
Write-Step "Removing Docker volume (open-webui)..."
$volume = docker volume ls --format "{{.Name}}" | Where-Object { $_ -eq "open-webui" }
if ($volume) {
    docker volume rm open-webui | Out-Null
    Write-OK "Volume 'open-webui' removed"
} else {
    Write-Skip "Volume 'open-webui' not found"
}

# --- 3. Stop Ollama ---
Write-Step "Stopping Ollama..."
$proc = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if ($proc) {
    Stop-Process -Name "ollama" -Force
    Write-OK "Ollama stopped"
} else {
    Write-Skip "Ollama is not running"
}

Write-Host "`n  Teardown complete. Run .\setup.ps1 to rebuild." -ForegroundColor Green
