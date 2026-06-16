# =============================================================================
# install.ps1 — Set up Continue for local Ollama
# Safe to run multiple times — backs up existing config before overwriting.
#
# Usage:
#   .\install.ps1 [-Yes] [-NoEmbed] [-InstallPrompts]
#
#   -Yes             Non-interactive: auto-confirm all prompts
#   -NoEmbed         Skip pulling nomic-embed-text (no @codebase search)
#   -InstallPrompts  Also copy slash-command prompts to ~/.continue/prompts/
# =============================================================================

[CmdletBinding()]
param(
    [switch]$Yes,
    [switch]$NoEmbed,
    [switch]$InstallPrompts
)

$SCRIPT_DIR    = Split-Path -Parent $MyInvocation.MyCommand.Path
$TOOLKIT_DIR   = Split-Path -Parent $SCRIPT_DIR          # toolkit/continue/
$CONFIG_SRC    = Join-Path $TOOLKIT_DIR "config.yaml"
$PROMPTS_SRC   = Join-Path $TOOLKIT_DIR "prompts"
$CONTINUE_DIR  = Join-Path $env:USERPROFILE ".continue"
$PROMPTS_DIR   = Join-Path $CONTINUE_DIR "prompts"
$CONFIG_DEST   = Join-Path $CONTINUE_DIR "config.yaml"

function Write-Step($msg) { Write-Host "`n>>> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    [--] $msg" -ForegroundColor DarkGray }
function Write-Warn($msg) { Write-Host "    [!!] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "    [XX] $msg" -ForegroundColor Red }

function Confirm-Action($prompt) {
    if ($Yes) { return $true }
    $answer = Read-Host "    $prompt [Y/n]"
    return ($answer -eq "" -or $answer -match "^[Yy]")
}

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║   Continue x Ollama — installer      ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Magenta

# --- 1. Verify source config exists ---
Write-Step "Checking source config..."
if (-not (Test-Path $CONFIG_SRC)) {
    Write-Fail "Source config not found: $CONFIG_SRC"
    Write-Fail "Run this script from inside the project-ollama repo."
    exit 1
}
Write-OK "Source config found"

# --- 2. Create ~/.continue if missing ---
Write-Step "Checking ~/.continue directory..."
if (-not (Test-Path $CONTINUE_DIR)) {
    New-Item -ItemType Directory -Path $CONTINUE_DIR | Out-Null
    Write-OK "Created $CONTINUE_DIR"
} else {
    Write-Skip "$CONTINUE_DIR already exists"
}

# --- 3. Back up existing config if it differs ---
Write-Step "Checking for existing config.yaml..."
if (Test-Path $CONFIG_DEST) {
    $srcHash  = (Get-FileHash $CONFIG_SRC  -Algorithm SHA256).Hash
    $destHash = (Get-FileHash $CONFIG_DEST -Algorithm SHA256).Hash
    if ($srcHash -eq $destHash) {
        Write-Skip "Config is already up to date — no backup needed"
    } else {
        $backup = "$CONFIG_DEST.bak"
        Copy-Item $CONFIG_DEST $backup -Force
        Write-Warn "Existing config backed up to $backup"
    }
} else {
    Write-Skip "No existing config — nothing to back up"
}

# --- 4. Copy config ---
Write-Step "Installing config.yaml..."
Copy-Item $CONFIG_SRC $CONFIG_DEST -Force
Write-OK "config.yaml installed to $CONFIG_DEST"

# --- 5. Install prompts (optional) ---
if ($InstallPrompts) {
    Write-Step "Installing slash-command prompts..."
    if (-not (Test-Path $PROMPTS_DIR)) {
        New-Item -ItemType Directory -Path $PROMPTS_DIR | Out-Null
        Write-OK "Created $PROMPTS_DIR"
    }
    $promptFiles = Get-ChildItem "$PROMPTS_SRC\*.yaml" -ErrorAction SilentlyContinue
    if ($promptFiles.Count -eq 0) {
        Write-Warn "No prompt files found in $PROMPTS_SRC"
    } else {
        foreach ($f in $promptFiles) {
            Copy-Item $f.FullName $PROMPTS_DIR -Force
            Write-OK "Installed prompt: $($f.Name)"
        }
    }
} else {
    Write-Skip "Prompt install skipped (re-run with -InstallPrompts to add slash commands)"
}

# --- 6. Pull embeddings model ---
if ($NoEmbed) {
    Write-Skip "Embed model skipped (-NoEmbed). @codebase search will not work."
} else {
    Write-Step "Checking for nomic-embed-text (used for @codebase search)..."
    $ollamaAvailable = Get-Command ollama -ErrorAction SilentlyContinue
    if (-not $ollamaAvailable) {
        Write-Warn "Ollama not found on PATH — skipping embed model check."
        Write-Warn "After installing Ollama, run: ollama pull nomic-embed-text"
    } else {
        $models = ollama list 2>&1
        if ($models -match "nomic-embed-text") {
            Write-Skip "nomic-embed-text already present"
        } elseif (Confirm-Action "Pull nomic-embed-text now? (~300MB)") {
            ollama pull nomic-embed-text
            if ($LASTEXITCODE -eq 0) { Write-OK "nomic-embed-text ready" }
            else { Write-Warn "Pull may have failed — run manually: ollama pull nomic-embed-text" }
        } else {
            Write-Warn "Skipped. Run 'ollama pull nomic-embed-text' when ready."
        }
    }
}

# --- Done ---
Write-Host ""
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "  Reload VS Code (Ctrl+Shift+P > 'Reload Window') to apply the new config." -ForegroundColor White
Write-Host ""
