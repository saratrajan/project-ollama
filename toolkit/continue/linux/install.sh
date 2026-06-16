#!/usr/bin/env bash
# =============================================================================
# install.sh — Set up Continue for local Ollama
# Copies config.yaml to ~/.continue/ and optionally pulls nomic-embed-text
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$SCRIPT_DIR/../config.yaml"
CONTINUE_DIR="$HOME/.continue"
CONFIG_DEST="$CONTINUE_DIR/config.yaml"

step()  { echo -e "\n\033[36m>>> $1\033[0m"; }
ok()    { echo -e "    \033[32m[OK] $1\033[0m"; }
warn()  { echo -e "    \033[33m[!!] $1\033[0m"; }

echo ""
echo -e "  \033[35m╔══════════════════════════════════════╗\033[0m"
echo -e "  \033[35m║   Continue x Ollama — installer      ║\033[0m"
echo -e "  \033[35m╚══════════════════════════════════════╝\033[0m"

# --- 1. Create ~/.continue if missing ---
step "Checking ~/.continue directory..."
if [[ ! -d "$CONTINUE_DIR" ]]; then
    mkdir -p "$CONTINUE_DIR"
    ok "Created $CONTINUE_DIR"
else
    ok "$CONTINUE_DIR already exists"
fi

# --- 2. Back up existing config ---
step "Checking for existing config.yaml..."
if [[ -f "$CONFIG_DEST" ]]; then
    cp "$CONFIG_DEST" "$CONFIG_DEST.bak"
    warn "Existing config backed up to $CONFIG_DEST.bak"
else
    ok "No existing config — nothing to back up"
fi

# --- 3. Copy new config ---
step "Installing config.yaml..."
cp "$CONFIG_SRC" "$CONFIG_DEST"
ok "config.yaml installed to $CONFIG_DEST"

# --- 4. Pull embeddings model ---
step "Checking for nomic-embed-text (used for @codebase search)..."
if ollama list 2>&1 | grep -q "nomic-embed-text"; then
    ok "nomic-embed-text already present"
else
    read -rp "    Pull nomic-embed-text now? (~300MB) [Y/n]: " pull
    pull="${pull:-Y}"
    if [[ "$pull" =~ ^[Yy] ]]; then
        ollama pull nomic-embed-text
        ok "nomic-embed-text ready"
    else
        warn "Skipped. @codebase search won't work until you pull nomic-embed-text."
    fi
fi

# --- Done ---
echo ""
echo -e "  \033[32mSetup complete!\033[0m"
echo "  Reload VS Code (Ctrl+Shift+P > 'Reload Window') to apply the new config."
echo ""
