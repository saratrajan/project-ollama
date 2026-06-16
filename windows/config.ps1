# =============================================================================
# config.ps1 — Edit this file to match your preferences
# =============================================================================

# Model to use by default (must already be pulled, or run setup.ps1)
$DEFAULT_MODEL     = "qwen2.5-coder:3b"

# Additional models to pull during setup (add more as needed)
$EXTRA_MODELS      = @(
    "qwen2.5:7b"
)

# Open WebUI settings
$WEBUI_PORT        = 3000          # Browser port (http://localhost:3000)
$WEBUI_CONTAINER   = "open-webui" # Docker container name

# Ollama API
$OLLAMA_HOST       = "http://localhost:11434"

# Security: restrict Ollama to local callers only (Continue + WebUI)
# Change only if you deliberately expose Ollama to other machines
$OLLAMA_ORIGINS    = "http://localhost,http://127.0.0.1,http://localhost:3000"

# Open browser automatically on start?
$AUTO_OPEN_BROWSER = $true
