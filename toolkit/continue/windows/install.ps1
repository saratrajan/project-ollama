# =============================================================================
# install.ps1 — Set up Continue for local Ollama
# Copies config.yaml to ~/.continue/ and optionally pulls nomic-embed-text
# =============================================================================

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$CONFIG_SRC   = Join-Path $SCRIPT_DIR "..\config.yaml"
$CONTINUE_DIR = Join-Path $env:USERPROFILE ".continue"
$CONFIG_DEST  = Join-Path $CONTINUE_DIR "config.yaml"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    [!!] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "    [XX] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║   Continue x Ollama — installer      ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Magenta

# --- 1. Create ~/.continue if missing ---
Write-Step "Checking ~/.continue directory..."
if (-not (Test-Path $CONTINUE_DIR)) {
    New-Item -ItemType Directory -Path $CONTINUE_DIR | Out-Null
    Write-OK "Created $CONTINUE_DIR"
} else {
    Write-OK "$CONTINUE_DIR already exists"
}

# --- 2. Back up existing config ---
Write-Step "Checking for existing config.yaml..."
if (Test-Path $CONFIG_DEST) {
    $backup = "$CONFIG_DEST.bak"
    Copy-Item $CONFIG_DEST $backup -Force
    Write-Warn "Existing config backed up to $backup"
} else {
    Write-OK "No existing config — nothing to back up"
}

# --- 3. Copy new config ---
Write-Step "Installing config.yaml..."
Copy-Item $CONFIG_SRC $CONFIG_DEST -Force
Write-OK "config.yaml installed to $CONFIG_DEST"

# --- 4. Pull embeddings model ---
Write-Step "Checking for nomic-embed-text (used for @codebase search)..."
$models = ollama list 2>&1
if ($models -match "nomic-embed-text") {
    Write-OK "nomic-embed-text already present"
} else {
    $pull = Read-Host "    Pull nomic-embed-text now? (~300MB) [Y/n]"
    if ($pull -eq "" -or $pull -match "^[Yy]") {
        ollama pull nomic-embed-text
        if ($LASTEXITCODE -eq 0) { Write-OK "nomic-embed-text ready" }
        else { Write-Warn "Pull may have failed — run: ollama pull nomic-embed-text" }
    } else {
        Write-Warn "Skipped. @codebase search won't work until you pull nomic-embed-text."
    }
}

# --- Done ---
Write-Host ""
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "  Reload VS Code (Ctrl+Shift+P > 'Reload Window') to apply the new config." -ForegroundColor White
Write-Host ""
