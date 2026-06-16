#!/usr/bin/env bash
# =============================================================================
# config.sh — Edit this file to match your preferences
# =============================================================================

# Model to use by default (must already be pulled, or run setup.sh)
DEFAULT_MODEL="qwen2.5-coder:3b"

# Additional models to pull during setup (space-separated)
EXTRA_MODELS=(
    "qwen2.5:7b"
)

# Open WebUI settings
WEBUI_PORT=3000                          # Browser port (http://localhost:3000)
WEBUI_CONTAINER="open-webui"            # Docker container name
WEBUI_DATA_DIR="$HOME/.webui-data"      # Host directory for persistent chat/data storage

# Ollama API
OLLAMA_HOST="http://localhost:11434"

# Security: restrict Ollama to local callers only (Continue + WebUI)
# Change only if you deliberately expose Ollama to other machines
OLLAMA_ORIGINS="http://localhost,http://127.0.0.1,http://localhost:3000"

# Open browser automatically on start? (true/false)
AUTO_OPEN_BROWSER=true
