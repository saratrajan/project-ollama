# =============================================================================
# setup.ps1 — Run ONCE after cloning to pull models and start WebUI
# =============================================================================

. "$PSScriptRoot\config.ps1"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    [!!] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "    [XX] $msg" -ForegroundColor Red }

# --- 1. Ollama check ---
Write-Step "Checking Ollama..."
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Fail "Ollama not found. Download from https://ollama.com and re-run setup."
    exit 1
}
Write-OK "Ollama found"

# --- 2. Pull default model ---
Write-Step "Pulling default model: $DEFAULT_MODEL"
ollama pull $DEFAULT_MODEL
if ($LASTEXITCODE -eq 0) { Write-OK "$DEFAULT_MODEL ready" }
else { Write-Warn "Pull may have failed — check output above" }

# --- 3. Pull extra models ---
foreach ($model in $EXTRA_MODELS) {
    Write-Step "Pulling extra model: $model"
    ollama pull $model
    if ($LASTEXITCODE -eq 0) { Write-OK "$model ready" }
    else { Write-Warn "Could not pull $model — skipping" }
}

# --- 4. Docker check ---
Write-Step "Checking Docker..."
$dockerRunning = docker info 2>&1 | Select-String "Server Version"
if (-not $dockerRunning) {
    Write-Fail "Docker is not running. Start Docker Desktop and re-run setup."
    exit 1
}
Write-OK "Docker is running"

# --- 5. Launch Open WebUI ---
Write-Step "Setting up Open WebUI container..."
$existing = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $WEBUI_CONTAINER }

if ($existing) {
    Write-OK "Container '$WEBUI_CONTAINER' already exists — skipping creation"
} else {
    docker run -d `
        -p "${WEBUI_PORT}:8080" `
        --add-host=host.docker.internal:host-gateway `
        -v open-webui:/app/backend/data `
        --name $WEBUI_CONTAINER `
        --restart always `
        ghcr.io/open-webui/open-webui:main

    if ($LASTEXITCODE -eq 0) { Write-OK "Open WebUI container created" }
    else { Write-Fail "Failed to create container — check Docker output above"; exit 1 }
}

Write-Host "`n=== Setup complete! ===" -ForegroundColor Green
Write-Host "Run .\start.ps1 any time to launch your AI environment." -ForegroundColor White
