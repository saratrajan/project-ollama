#!/usr/bin/env bash
# =============================================================================
# install.sh — Set up Continue for local Ollama
# Safe to run multiple times — backs up existing config before overwriting.
#
# Usage:
#   ./install.sh [--yes] [--no-embed] [--install-prompts]
#
#   --yes              Non-interactive: auto-confirm all prompts
#   --no-embed         Skip pulling nomic-embed-text (no @codebase search)
#   --install-prompts  Also copy slash-command prompts to ~/.continue/prompts/
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"     # toolkit/continue/
CONFIG_SRC="$TOOLKIT_DIR/config.yaml"
PROMPTS_SRC="$TOOLKIT_DIR/prompts"
CONTINUE_DIR="$HOME/.continue"
PROMPTS_DIR="$CONTINUE_DIR/prompts"
CONFIG_DEST="$CONTINUE_DIR/config.yaml"

# --- Arg parsing ---
YES=false
NO_EMBED=false
INSTALL_PROMPTS=false
for arg in "$@"; do
    case "$arg" in
        --yes|-y)          YES=true ;;
        --no-embed)        NO_EMBED=true ;;
        --install-prompts) INSTALL_PROMPTS=true ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

step()  { echo -e "\n\033[36m>>> $1\033[0m"; }
ok()    { echo -e "    \033[32m[OK] $1\033[0m"; }
skip()  { echo -e "    \033[90m[--] $1\033[0m"; }
warn()  { echo -e "    \033[33m[!!] $1\033[0m"; }
fail()  { echo -e "    \033[31m[XX] $1\033[0m"; }

# Prompt only when stdin is a tty and --yes not passed
confirm() {
    local prompt="$1"
    if [[ "$YES" == true ]]; then return 0; fi
    if [[ ! -t 0 ]]; then
        # Non-interactive stdin (piped/CI) — default to yes
        warn "Non-interactive mode: auto-confirming '$prompt'"
        return 0
    fi
    read -rp "    $prompt [Y/n]: " answer
    answer="${answer:-Y}"
    [[ "$answer" =~ ^[Yy] ]]
}

echo ""
echo -e "  \033[35m╔══════════════════════════════════════╗\033[0m"
echo -e "  \033[35m║   Continue x Ollama — installer      ║\033[0m"
echo -e "  \033[35m╚══════════════════════════════════════╝\033[0m"

# --- 1. Verify source config exists ---
step "Checking source config..."
if [[ ! -f "$CONFIG_SRC" ]]; then
    fail "Source config not found: $CONFIG_SRC"
    fail "Run this script from inside the project-ollama repo."
    exit 1
fi
ok "Source config found"

# --- 2. Create ~/.continue if missing ---
step "Checking ~/.continue directory..."
if [[ ! -d "$CONTINUE_DIR" ]]; then
    mkdir -p "$CONTINUE_DIR"
    ok "Created $CONTINUE_DIR"
else
    skip "$CONTINUE_DIR already exists"
fi

# --- 3. Back up existing config only if it differs ---
step "Checking for existing config.yaml..."
if [[ -f "$CONFIG_DEST" ]]; then
    if command -v sha256sum &>/dev/null; then
        src_hash=$(sha256sum "$CONFIG_SRC"  | awk '{print $1}')
        dst_hash=$(sha256sum "$CONFIG_DEST" | awk '{print $1}')
    elif command -v shasum &>/dev/null; then
        src_hash=$(shasum -a 256 "$CONFIG_SRC"  | awk '{print $1}')
        dst_hash=$(shasum -a 256 "$CONFIG_DEST" | awk '{print $1}')
    else
        src_hash=""; dst_hash="different"   # can't compare — always back up
    fi

    if [[ "$src_hash" == "$dst_hash" ]]; then
        skip "Config is already up to date — no backup needed"
    else
        cp "$CONFIG_DEST" "$CONFIG_DEST.bak"
        warn "Existing config backed up to $CONFIG_DEST.bak"
    fi
else
    skip "No existing config — nothing to back up"
fi

# --- 4. Copy config ---
step "Installing config.yaml..."
cp "$CONFIG_SRC" "$CONFIG_DEST"
ok "config.yaml installed to $CONFIG_DEST"

# --- 5. Install prompts (optional) ---
if [[ "$INSTALL_PROMPTS" == true ]]; then
    step "Installing slash-command prompts..."
    mkdir -p "$PROMPTS_DIR"
    prompt_files=("$PROMPTS_SRC"/*.yaml)
    if [[ ! -e "${prompt_files[0]}" ]]; then
        warn "No prompt files found in $PROMPTS_SRC"
    else
        for f in "${prompt_files[@]}"; do
            cp "$f" "$PROMPTS_DIR/"
            ok "Installed prompt: $(basename "$f")"
        done
    fi
else
    skip "Prompt install skipped (re-run with --install-prompts to add slash commands)"
fi

# --- 6. Pull embeddings model ---
if [[ "$NO_EMBED" == true ]]; then
    skip "Embed model skipped (--no-embed). @codebase search will not work."
else
    step "Checking for nomic-embed-text (used for @codebase search)..."
    if ! command -v ollama &>/dev/null; then
        warn "Ollama not found on PATH — skipping embed model check."
        warn "After installing Ollama, run: ollama pull nomic-embed-text"
    elif ollama list 2>/dev/null | grep -q "nomic-embed-text"; then
        skip "nomic-embed-text already present"
    elif confirm "Pull nomic-embed-text now? (~300MB)"; then
        if ollama pull nomic-embed-text; then
            ok "nomic-embed-text ready"
        else
            warn "Pull failed — run manually: ollama pull nomic-embed-text"
        fi
    else
        warn "Skipped. Run 'ollama pull nomic-embed-text' when ready."
    fi
fi

# --- Done ---
echo ""
echo -e "  \033[32mSetup complete!\033[0m"
echo "  Reload VS Code (Ctrl+Shift+P > 'Reload Window') to apply the new config."
echo ""
