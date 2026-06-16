#!/usr/bin/env bash
# =============================================================================
# setup.sh — Run ONCE after cloning to pull models and start WebUI
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

step()  { echo -e "\n\033[36m>>> $1\033[0m"; }
ok()    { echo -e "    \033[32m[OK] $1\033[0m"; }
warn()  { echo -e "    \033[33m[!!] $1\033[0m"; }
fail()  { echo -e "    \033[31m[XX] $1\033[0m"; }

# --- 1. Ollama check ---
step "Checking Ollama..."
if ! command -v ollama &>/dev/null; then
    fail "Ollama not found. Install from https://ollama.com and re-run setup."
    exit 1
fi
ok "Ollama found"

# --- 2. Pull default model ---
step "Pulling default model: $DEFAULT_MODEL"
if ollama pull "$DEFAULT_MODEL"; then
    ok "$DEFAULT_MODEL ready"
else
    warn "Pull may have failed — check output above"
fi

# --- 3. Pull extra models ---
for model in "${EXTRA_MODELS[@]}"; do
    step "Pulling extra model: $model"
    if ollama pull "$model"; then
        ok "$model ready"
    else
        warn "Could not pull $model — skipping"
    fi
done

# --- 4. Docker check ---
step "Checking Docker..."
if ! docker info 2>&1 | grep -q "Server Version"; then
    fail "Docker is not running. Start the Docker daemon and re-run setup."
    exit 1
fi
ok "Docker is running"

# --- 5. Launch Open WebUI ---
step "Setting up Open WebUI container..."
if docker ps -a --format "{{.Names}}" | grep -q "^${WEBUI_CONTAINER}$"; then
    ok "Container '$WEBUI_CONTAINER' already exists — skipping creation"
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

echo -e "\n\033[32m=== Setup complete! ===\033[0m"
echo "Run ./start.sh any time to launch your AI environment."
