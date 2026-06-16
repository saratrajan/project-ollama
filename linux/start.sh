#!/usr/bin/env bash
# =============================================================================
# start.sh — Boot your local AI environment
# Safe to run multiple times — skips anything already running.
#
# Usage:
#   ./start.sh [--no-browser]
#
#   --no-browser   Don't open the browser automatically
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# --- Arg parsing ---
NO_BROWSER=false
for arg in "$@"; do
    case "$arg" in
        --no-browser) NO_BROWSER=true ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

step()  { echo -e "\n\033[36m>>> $1\033[0m"; }
ok()    { echo -e "    \033[32m[OK] $1\033[0m"; }
skip()  { echo -e "    \033[90m[--] $1\033[0m"; }
warn()  { echo -e "    \033[33m[!!] $1\033[0m"; }
fail()  { echo -e "    \033[31m[XX] $1\033[0m"; }

echo ""
echo -e "  \033[35m╔══════════════════════════════════╗\033[0m"
echo -e "  \033[35m║     project-ollama  start.sh     ║\033[0m"
echo -e "  \033[35m║   Model: $DEFAULT_MODEL\033[0m"
echo -e "  \033[35m╚══════════════════════════════════╝\033[0m"

# --- 1. Ollama service ---
step "Checking Ollama service..."
if ! command -v ollama &>/dev/null; then
    fail "Ollama is not installed. Run setup.sh first."
    exit 1
fi

if curl -sf "$OLLAMA_HOST" &>/dev/null; then
    ok "Ollama is running at $OLLAMA_HOST"
else
    warn "Ollama not responding — attempting to start..."
    OLLAMA_HOST="127.0.0.1:11434" OLLAMA_ORIGINS="$OLLAMA_ORIGINS" ollama serve &>/dev/null &
    OLLAMA_PID=$!
    # Wait up to 10s for the server to respond
    for i in {1..5}; do
        sleep 2
        if curl -sf "$OLLAMA_HOST" &>/dev/null; then
            ok "Ollama started successfully (PID $OLLAMA_PID)"
            break
        fi
        if [[ $i -eq 5 ]]; then
            fail "Could not start Ollama. Try running 'ollama serve' in a separate terminal."
            exit 1
        fi
    done
fi

# --- 2. Verify model is available ---
step "Verifying model: $DEFAULT_MODEL..."
base_model="${DEFAULT_MODEL%%:*}"
if ollama list 2>/dev/null | grep -q "^${base_model}"; then
    ok "$DEFAULT_MODEL is available"
else
    warn "$DEFAULT_MODEL not found locally — pulling now..."
    if ! ollama pull "$DEFAULT_MODEL"; then
        warn "Pull failed — continuing anyway (model may still work if partially cached)"
    fi
fi

# --- 3. Docker check ---
step "Checking Docker..."
if ! docker info &>/dev/null; then
    fail "Docker is not running. Please start the Docker daemon."
    fail "  Linux:  sudo systemctl start docker"
    fail "  macOS:  open Docker Desktop"
    exit 1
fi
ok "Docker is running"

# --- 4. Open WebUI container ---
step "Starting Open WebUI..."
if docker ps --format "{{.Names}}" | grep -q "^${WEBUI_CONTAINER}$"; then
    skip "Open WebUI already running"
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
if [[ "$NO_BROWSER" == true ]] || [[ "$AUTO_OPEN_BROWSER" != true ]]; then
    skip "Browser launch skipped"
else
    step "Opening browser..."
    if command -v xdg-open &>/dev/null; then
        xdg-open "http://localhost:$WEBUI_PORT" &
    elif command -v open &>/dev/null; then
        open "http://localhost:$WEBUI_PORT"
    else
        warn "No browser launcher found. Open http://localhost:$WEBUI_PORT manually."
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
