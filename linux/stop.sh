#!/usr/bin/env bash
# =============================================================================
# stop.sh - Stop the AI environment (reversible)
# Stops Open WebUI container and Ollama. Run start.sh to resume.
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

step()  { echo -e "\n\033[36m>>> $1\033[0m"; }
ok()    { echo -e "    \033[32m[OK] $1\033[0m"; }
skip()  { echo -e "    \033[90m[--] $1\033[0m"; }

# --- 1. Stop Open WebUI container ---
step "Stopping Open WebUI container..."
if docker ps --format "{{.Names}}" | grep -q "^${WEBUI_CONTAINER}$"; then
    docker stop "$WEBUI_CONTAINER" >/dev/null
    ok "Container '$WEBUI_CONTAINER' stopped"
else
    skip "Container '$WEBUI_CONTAINER' is not running"
fi

# --- 2. Stop Ollama ---
step "Stopping Ollama..."
if pgrep -x ollama >/dev/null 2>&1; then
    sudo pkill -x ollama
    ok "Ollama stopped"
else
    skip "Ollama is not running"
fi

echo -e "\n  \033[32mStopped. Run ./start.sh to resume.\033[0m"
