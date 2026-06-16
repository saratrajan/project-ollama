# =============================================================================
# start.ps1 — Boot your local AI environment
# Safe to run multiple times — skips anything already running.
#
# Usage:
#   .\start.ps1 [-NoBrowser]
#
#   -NoBrowser   Don't open the browser automatically
# =============================================================================

[CmdletBinding()]
param(
    [switch]$NoBrowser
)

. "$PSScriptRoot\config.ps1"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    [--] $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "    [!!] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "    [XX] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║     project-ollama  start.ps1    ║" -ForegroundColor Magenta
Write-Host "  ║   Model: $DEFAULT_MODEL" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Magenta

# --- 1. Ollama service ---
Write-Step "Checking Ollama service..."
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Fail "Ollama is not installed. Run setup.ps1 first."
    exit 1
}

$ollamaUp = $false
try {
    $null = Invoke-RestMethod -Uri "$OLLAMA_HOST" -TimeoutSec 3 -ErrorAction Stop
    $ollamaUp = $true
} catch {}

if ($ollamaUp) {
    Write-OK "Ollama is running at $OLLAMA_HOST"
} else {
    Write-Warn "Ollama not responding — attempting to start..."
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden

    # Wait up to 10s
    for ($i = 1; $i -le 5; $i++) {
        Start-Sleep -Seconds 2
        try {
            $null = Invoke-RestMethod -Uri "$OLLAMA_HOST" -TimeoutSec 3 -ErrorAction Stop
            Write-OK "Ollama started successfully"
            $ollamaUp = $true
            break
        } catch {}
    }

    if (-not $ollamaUp) {
        Write-Fail "Could not start Ollama. Open a terminal and run: ollama serve"
        exit 1
    }
}

# --- 2. Verify model is available ---
Write-Step "Verifying model: $DEFAULT_MODEL..."
$base = $DEFAULT_MODEL.Split(":")[0]
$models = ollama list 2>&1
if ($models -match [regex]::Escape($base)) {
    Write-OK "$DEFAULT_MODEL is available"
} else {
    Write-Warn "$DEFAULT_MODEL not found locally — pulling now..."
    ollama pull $DEFAULT_MODEL
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Pull may have failed — continuing (model may still work if partially cached)"
    }
}

# --- 3. Docker check ---
Write-Step "Checking Docker..."
$dockerRunning = docker info 2>&1 | Select-String "Server Version"
if (-not $dockerRunning) {
    Write-Fail "Docker is not running. Please start Docker Desktop."
    exit 1
}
Write-OK "Docker is running"

# --- 4. Open WebUI container ---
Write-Step "Starting Open WebUI..."
$running = docker ps --format "{{.Names}}" | Where-Object { $_ -eq $WEBUI_CONTAINER }
$stopped = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $WEBUI_CONTAINER }

if ($running) {
    Write-Skip "Open WebUI already running"
} elseif ($stopped) {
    docker start $WEBUI_CONTAINER | Out-Null
    Write-OK "Open WebUI container restarted"
} else {
    Write-Warn "Container not found — running setup first..."
    & "$PSScriptRoot\setup.ps1"
}

# --- 5. Wait for WebUI to be ready ---
Write-Step "Waiting for WebUI to be ready..."
$maxAttempts = 15
$attempt = 0
$ready = $false
while ($attempt -lt $maxAttempts -and -not $ready) {
    $attempt++
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:$WEBUI_PORT" -TimeoutSec 2 -ErrorAction Stop
        $ready = $true
    } catch {
        Write-Host "    Waiting... ($attempt/$maxAttempts)" -ForegroundColor DarkGray
        Start-Sleep -Seconds 2
    }
}

if ($ready) {
    Write-OK "Open WebUI is live at http://localhost:$WEBUI_PORT"
} else {
    Write-Warn "WebUI taking longer than expected — try http://localhost:$WEBUI_PORT in a moment"
}

# --- 6. Open browser ---
if ($NoBrowser -or -not $AUTO_OPEN_BROWSER) {
    Write-Skip "Browser launch skipped"
} else {
    Write-Step "Opening browser..."
    Start-Process "http://localhost:$WEBUI_PORT"
    Write-OK "Browser launched"
}

Write-Host ""
Write-Host "  All systems go. Happy building!" -ForegroundColor Green
Write-Host "  WebUI  -> http://localhost:$WEBUI_PORT" -ForegroundColor White
Write-Host "  API    -> $OLLAMA_HOST" -ForegroundColor White
Write-Host "  Model  -> $DEFAULT_MODEL" -ForegroundColor White
Write-Host "  VS Code Continue plugin connects automatically." -ForegroundColor DarkGray
Write-Host ""
