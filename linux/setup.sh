#!/usr/bin/env bash
# =============================================================================
# setup.sh — Pull models and launch Open WebUI
# Safe to run multiple times — skips steps that are already complete.
#
# Usage:
#   ./setup.sh [--skip-webui] [--yes]
#
#   --skip-webui   Skip Docker / Open WebUI setup (Ollama + models only)
#   --yes          Non-interactive: auto-confirm any prompts
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# --- Arg parsing ---
SKIP_WEBUI=false
YES=false
for arg in "$@"; do
    case "$arg" in
        --skip-webui) SKIP_WEBUI=true ;;
        --yes|-y)     YES=true ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

step()  { echo -e "\n\033[36m>>> $1\033[0m"; }
ok()    { echo -e "    \033[32m[OK] $1\033[0m"; }
skip()  { echo -e "    \033[90m[--] $1\033[0m"; }
warn()  { echo -e "    \033[33m[!!] $1\033[0m"; }
fail()  { echo -e "    \033[31m[XX] $1\033[0m"; }

# Pull a model only if not already present
pull_if_missing() {
    local model="$1"
    local base="${model%%:*}"
    if ollama list 2>/dev/null | grep -q "^${base}"; then
        skip "$model already pulled"
    else
        if ollama pull "$model"; then
            ok "$model ready"
        else
            warn "Could not pull $model — skipping (run manually: ollama pull $model)"
        fi
    fi
}

# =============================================================================

# --- 1. Ollama check ---
step "Checking Ollama..."
if ! command -v ollama &>/dev/null; then
    fail "Ollama not found. Install from https://ollama.com and re-run setup."
    exit 1
fi
ok "Ollama found ($(ollama --version 2>/dev/null || echo 'version unknown'))"

# --- 2. Pull default model ---
step "Checking default model: $DEFAULT_MODEL"
pull_if_missing "$DEFAULT_MODEL"

# --- 3. Pull extra models (safe with empty array on any bash version) ---
if [[ ${#EXTRA_MODELS[@]} -gt 0 ]]; then
    for model in "${EXTRA_MODELS[@]}"; do
        step "Checking extra model: $model"
        pull_if_missing "$model"
    done
else
    skip "No extra models configured"
fi

# --- 4. Docker + WebUI (skippable) ---
if [[ "$SKIP_WEBUI" == true ]]; then
    skip "Skipping Docker / WebUI setup (--skip-webui)"
else
    step "Checking Docker..."
    if ! docker info &>/dev/null; then
        fail "Docker is not running. Start the Docker daemon and re-run setup."
        fail "  Linux:  sudo systemctl start docker"
        fail "  macOS:  open Docker Desktop"
        exit 1
    fi
    ok "Docker is running"

    step "Setting up Open WebUI container..."
    if docker ps --format "{{.Names}}" | grep -q "^${WEBUI_CONTAINER}$"; then
        skip "Container '$WEBUI_CONTAINER' already running"
    elif docker ps -a --format "{{.Names}}" | grep -q "^${WEBUI_CONTAINER}$"; then
        docker start "$WEBUI_CONTAINER" >/dev/null
        ok "Container '$WEBUI_CONTAINER' was stopped — started it"
    else
        docker run -d \
            -p "${WEBUI_PORT}:8080" \
            --add-host=host.docker.internal:host-gateway \
            -v open-webui:/app/backend/data \
            --name "$WEBUI_CONTAINER" \
            --restart always \
            ghcr.io/open-webui/open-webui:main
        ok "Open WebUI container created"
    fi
fi

echo -e "\n\033[32m=== Setup complete! ===\033[0m"
echo "Run ./start.sh any time to launch your AI environment."
