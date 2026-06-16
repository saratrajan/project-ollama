#!/usr/bin/env bash
# =============================================================================
# teardown.sh - Full cleanup (destructive)
# Stops and REMOVES the container and Docker volume. Models are kept.
# Run setup.sh to rebuild from scratch.
#
# Usage:
#   ./teardown.sh [--yes]
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

YES=false
for arg in "$@"; do
    case "$arg" in
        --yes|-y) YES=true ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

step()  { echo -e "\n\033[36m>>> $1\033[0m"; }
ok()    { echo -e "    \033[32m[OK] $1\033[0m"; }
skip()  { echo -e "    \033[90m[--] $1\033[0m"; }

if [[ "$YES" != true ]]; then
    echo -e "\n  \033[33m[!!] This will remove the Open WebUI container and its data volume.\033[0m"
    echo -e "       Ollama models are NOT deleted."
    if [[ ! -t 0 ]]; then
        echo -e "  Non-interactive mode - auto-confirming."
    else
        read -rp $'\n  Continue? [y/N]: ' confirm
        if [[ ! "$confirm" =~ ^[Yy] ]]; then
            echo "  Aborted."
            exit 0
        fi
    fi
fi

# --- 1. Stop + remove container ---
step "Removing Open WebUI container..."
if docker ps -a --format "{{.Names}}" | grep -q "^${WEBUI_CONTAINER}$"; then
    docker rm -f "$WEBUI_CONTAINER" >/dev/null
    ok "Container '$WEBUI_CONTAINER' removed"
else
    skip "Container '$WEBUI_CONTAINER' not found"
fi

# --- 2. Remove Docker volume ---
step "Removing Docker volume (open-webui)..."
if docker volume ls --format "{{.Name}}" | grep -q "^open-webui$"; then
    docker volume rm open-webui >/dev/null
    ok "Volume 'open-webui' removed"
else
    skip "Volume 'open-webui' not found"
fi

# --- 3. Stop Ollama ---
step "Stopping Ollama..."
if pgrep -x ollama >/dev/null 2>&1; then
    sudo pkill -x ollama
    ok "Ollama stopped"
else
    skip "Ollama is not running"
fi

echo -e "\n  \033[32mTeardown complete. Run ./setup.sh to rebuild.\033[0m"
