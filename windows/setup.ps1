# =============================================================================
# setup.ps1 - Pull models and launch Open WebUI
# Safe to run multiple times - skips steps that are already complete.
#
# Usage:
#   .\setup.ps1 [-SkipWebUI] [-Yes]
#
#   -SkipWebUI   Skip Docker / Open WebUI setup (Ollama + models only)
#   -Yes         Non-interactive: auto-confirm any prompts
# =============================================================================

[CmdletBinding()]
param(
    [switch]$SkipWebUI,
    [switch]$Yes
)

. "$PSScriptRoot\config.ps1"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    [--] $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "    [!!] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "    [XX] $msg" -ForegroundColor Red }

function Pull-IfMissing($model) {
    $base = $model.Split(":")[0]
    $already = ollama list 2>&1 | Select-String "^$base"
    if ($already) {
        Write-Skip "$model already pulled"
    } else {
        ollama pull $model
        if ($LASTEXITCODE -eq 0) { Write-OK "$model ready" }
        else { Write-Warn "Could not pull $model - skipping (run manually: ollama pull $model)" }
    }
}

# --- 1. Ollama check / install ---
Write-Step "Checking Ollama..."
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Warn "Ollama not found - installing via winget..."
    winget install Ollama.Ollama --silent --accept-source-agreements --accept-package-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Fail "Ollama install failed. Install manually from https://ollama.com"
        Write-Fail "Then restart your terminal and re-run setup."
        exit 1
    }
    Write-OK "Ollama installed"
} else {
    $ollamaVer = ollama --version 2>&1
    Write-OK "Ollama found ($ollamaVer)"
}

# --- 2. Pull default model ---
Write-Step "Checking default model: $DEFAULT_MODEL"
Pull-IfMissing $DEFAULT_MODEL

# --- 3. Pull extra models ---
if ($EXTRA_MODELS.Count -gt 0) {
    foreach ($model in $EXTRA_MODELS) {
        Write-Step "Checking extra model: $model"
        Pull-IfMissing $model
    }
} else {
    Write-Skip "No extra models configured"
}

# --- 4. Docker + WebUI (skippable) ---
if ($SkipWebUI) {
    Write-Skip "Skipping Docker / WebUI setup (-SkipWebUI)"
} else {
    Write-Step "Checking Docker..."
    $dockerRunning = docker info 2>&1 | Select-String "Server Version"
    if (-not $dockerRunning) {
        Write-Fail "Docker is not running. Start Docker Desktop and re-run setup."
        exit 1
    }
    Write-OK "Docker is running"

    Write-Step "Setting up Open WebUI container..."

    # Ensure data directory exists
    if (-not (Test-Path $WEBUI_DATA_DIR)) {
        New-Item -ItemType Directory -Path $WEBUI_DATA_DIR | Out-Null
        Write-OK "Created data directory: $WEBUI_DATA_DIR"
    } else {
        Write-Skip "Data directory exists: $WEBUI_DATA_DIR"
    }

    $running = docker ps --format "{{.Names}}" | Where-Object { $_ -eq $WEBUI_CONTAINER }
    $stopped = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $WEBUI_CONTAINER }

    if ($running) {
        Write-Skip "Container '$WEBUI_CONTAINER' already running"
    } elseif ($stopped) {
        docker start $WEBUI_CONTAINER | Out-Null
        Write-OK "Container '$WEBUI_CONTAINER' was stopped - started it"
        Write-Warn "Telemetry flags only apply to new containers. Run teardown + setup to rebuild with them."
    } else {
        $dockerArgs = @(
            "run", "-d",
            "-p", "${WEBUI_PORT}:8080",
            "--add-host=host.docker.internal:host-gateway",
            "-v", "${WEBUI_DATA_DIR}:/app/backend/data",
            "--name", $WEBUI_CONTAINER,
            "--restart", "always",
            "--env", "SCARF_NO_ANALYTICS=true",
            "--env", "DO_NOT_TRACK=1",
            "--env", "ANONYMIZED_TELEMETRY=false",
            "ghcr.io/open-webui/open-webui:main"
        )
        & docker @dockerArgs
        if ($LASTEXITCODE -eq 0) { Write-OK "Open WebUI container created (data -> $WEBUI_DATA_DIR, telemetry disabled)" }
        else { Write-Fail "Failed to create container - check Docker output above"; exit 1 }
    }
}

Write-Host "`n=== Setup complete! ===" -ForegroundColor Green
Write-Host "Run .\start.ps1 any time to launch your AI environment." -ForegroundColor White
