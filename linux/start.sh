#!/usr/bin/env bash
# =============================================================================
# start.sh — Run this every time to boot your local AI environment
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

step()  { echo -e "\n\033[36m>>> $1\033[0m"; }
ok()    { echo -e "    \033[32m[OK] $1\033[0m"; }
warn()  { echo -e "    \033[33m[!!] $1\033[0m"; }
fail()  { echo -e "    \033[31m[XX] $1\033[0m"; }

echo ""
echo -e "  \033[35m╔══════════════════════════════════╗\033[0m"
echo -e "  \033[35m║     project-ollama  start.sh     ║\033[0m"
echo -e "  \033[35m║   Model: $DEFAULT_MODEL\033[0m"
echo -e "  \033[35m╚══════════════════════════════════╝\033[0m"

# --- 1. Ollama service ---
step "Checking Ollama service..."
if curl -sf "$OLLAMA_HOST" &>/dev/null; then
    ok "Ollama is running at $OLLAMA_HOST"
else
    warn "Ollama not responding — attempting to start..."
    ollama serve &>/dev/null &
    sleep 3
    if curl -sf "$OLLAMA_HOST" &>/dev/null; then
        ok "Ollama started successfully"
    else
        fail "Could not start Ollama. Open a terminal and run: ollama serve"
        exit 1
    fi
fi

# --- 2. Verify model is available ---
step "Verifying model: $DEFAULT_MODEL..."
base_model="${DEFAULT_MODEL%%:*}"
if ollama list 2>&1 | grep -q "$base_model"; then
    ok "$DEFAULT_MODEL is available"
else
    warn "$DEFAULT_MODEL not found locally — pulling now..."
    ollama pull "$DEFAULT_MODEL"
fi

# --- 3. Docker check ---
step "Checking Docker..."
if ! docker info 2>&1 | grep -q "Server Version"; then
    fail "Docker is not running. Please start the Docker daemon."
    exit 1
fi
ok "Docker is running"

# --- 4. Open WebUI container ---
step "Starting Open WebUI..."
if docker ps --format "{{.Names}}" | grep -q "^${WEBUI_CONTAINER}$"; then
    ok "Open WebUI already running"
elif docker ps -a --format "{{.Names}}" | grep -q "^${WEBUI_CONTAINER}$"; then
    docker start "$WEBUI_CONTAINER" >/dev/null
    ok "Open WebUI container restarted"
else
    warn "Container not found — running setup first..."
    bash "$SCRIPT_DIR/setup.sh"
fi

# --- 5. Wait for WebUI to be ready ---
step "Waiting for WebUI to be ready..."
max_attempts=15
attempt=0
ready=false
while [[ $attempt -lt $max_attempts ]] && [[ $ready == false ]]; do
    attempt=$((attempt + 1))
    if curl -sf "http://localhost:$WEBUI_PORT" &>/dev/null; then
        ready=true
    else
        echo -e "    \033[90mWaiting... ($attempt/$max_attempts)\033[0m"
        sleep 2
    fi
done

if [[ $ready == true ]]; then
    ok "Open WebUI is live at http://localhost:$WEBUI_PORT"
else
    warn "WebUI taking longer than expected — try http://localhost:$WEBUI_PORT in a moment"
fi

# --- 6. Open browser ---
if [[ "$AUTO_OPEN_BROWSER" == true ]]; then
    step "Opening browser..."
    if command -v xdg-open &>/dev/null; then
        xdg-open "http://localhost:$WEBUI_PORT" &
    elif command -v open &>/dev/null; then
        open "http://localhost:$WEBUI_PORT"
    else
        warn "Could not detect a browser launcher. Open http://localhost:$WEBUI_PORT manually."
    fi
    ok "Browser launched"
fi

echo ""
echo -e "  \033[32mAll systems go. Happy building!\033[0m"
echo -e "  WebUI  -> http://localhost:$WEBUI_PORT"
echo -e "  API    -> $OLLAMA_HOST"
echo -e "  Model  -> $DEFAULT_MODEL"
echo -e "  \033[90m  VS Code Continue plugin connects automatically.\033[0m"
echo ""
