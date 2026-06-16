# project-ollama

Bootstrap for a fully local, private AI environment — runs [Ollama](https://ollama.com) + [Open WebUI](https://github.com/open-webui/open-webui) with a single command. Scripts are provided for both **Windows (PowerShell)** and **Linux/macOS (Bash)**.

---

## Stack

| Component | Purpose |
|---|---|
| [Ollama](https://ollama.com) | Local LLM inference engine |
| `qwen2.5-coder:3b` | Default model — fast, code-focused, low VRAM |
| [Open WebUI](https://github.com/open-webui/open-webui) | Chat UI at `http://localhost:3000` |
| [Continue](https://marketplace.visualstudio.com/items?itemName=Continue.continue) (VS Code) | AI coding assistant — chat, edit, autocomplete, agent |

---

## Repository Structure

```
project-ollama/
├── windows/          # PowerShell scripts for Windows
│   ├── config.ps1   # Edit this to change models / ports
│   ├── setup.ps1    # Run once after cloning
│   └── start.ps1    # Run every time to boot the environment
├── linux/            # Bash scripts for Linux / macOS
│   ├── config.sh    # Edit this to change models / ports
│   ├── setup.sh     # Run once after cloning
│   └── start.sh     # Run every time to boot the environment
└── README.md
```

---

## Requirements

### All platforms
- [Ollama](https://ollama.com) installed and on `PATH`
- [Docker](https://www.docker.com/products/docker-desktop/) running
- A reasonably capable GPU (NVIDIA GTX 1660 Super or better recommended)

### Windows
- Windows 10 / 11
- PowerShell 5.1 or PowerShell 7+

### Linux / macOS
- Bash 4+ (macOS ships with Bash 3 — install a newer version via Homebrew if needed)
- `curl` available on `PATH`
- Docker daemon running (`sudo systemctl start docker` on most distros)

---

## Quick Start

### Windows

```powershell
# First time only
git clone https://github.com/saratrajan/project-ollama.git
cd project-ollama
.\windows\setup.ps1

# Every time after that
.\windows\start.ps1
```

### Linux / macOS

```bash
# First time only
git clone https://github.com/saratrajan/project-ollama.git
cd project-ollama
chmod +x linux/*.sh
./linux/setup.sh

# Every time after that
./linux/start.sh
```

Your browser opens to `http://localhost:3000` automatically.

---

## Configuration

Edit the config file for your platform before running setup:

| Setting | Windows (`config.ps1`) | Linux (`config.sh`) | Default |
|---|---|---|---|
| Default model | `$DEFAULT_MODEL` | `DEFAULT_MODEL` | `qwen2.5-coder:3b` |
| Extra models to pull | `$EXTRA_MODELS` | `EXTRA_MODELS` | `qwen2.5:7b` |
| WebUI browser port | `$WEBUI_PORT` | `WEBUI_PORT` | `3000` |
| Docker container name | `$WEBUI_CONTAINER` | `WEBUI_CONTAINER` | `open-webui` |
| Ollama API endpoint | `$OLLAMA_HOST` | `OLLAMA_HOST` | `http://localhost:11434` |
| Auto-open browser | `$AUTO_OPEN_BROWSER` | `AUTO_OPEN_BROWSER` | `true` |

---

## Adding More Models

Pull any model from the [Ollama library](https://ollama.com/library):

```bash
# Code-focused
ollama pull qwen2.5-coder:7b    # Larger coding model (~5GB)
ollama pull qwen2.5-coder:14b   # Strongest local coder (~10GB)

# General chat
ollama pull qwen2.5:7b           # Good general-purpose model
ollama pull qwen2.5:14b          # Stronger reasoning (~10GB)

# Lightweight / fast
ollama pull qwen2.5-coder:1.5b  # Runs on CPU-only machines
```

After pulling, add the model name to `EXTRA_MODELS` in your config file so it is pulled automatically on the next fresh setup.

---

## VS Code — Continue Extension

[Continue](https://marketplace.visualstudio.com/items?itemName=Continue.continue) is the primary AI coding interface for this setup. It wires directly into Ollama and provides four modes inside VS Code:

| Mode | What it does |
|---|---|
| **Agent** | Collaborative AI assistance — plans and executes multi-step dev tasks |
| **Chat** | Ask questions about your code, get explanations, brainstorm approaches |
| **Edit** | Inline code modification without leaving the file |
| **Autocomplete** | Real-time tab-completion as you type |

### Installation

1. Open VS Code and press `Ctrl+P`, then paste:
   ```
   ext install Continue.continue
   ```
2. Alternatively, search **"Continue"** in the Extensions panel and install the one by *Continue Dev, Inc.* (3M+ installs).

### Connecting to Ollama

Continue is configured via `~/.continue/config.yaml`. The snippet below sets up **chat**, **autocomplete**, and **embeddings** — all backed by local Ollama models, no API key needed.

```yaml
# ~/.continue/config.yaml

models:
  # Chat / Agent model
  - name: Qwen Coder (chat)
    provider: ollama
    model: qwen2.5-coder:3b
    apiBase: http://localhost:11434
    roles:
      - chat
      - agent

  # Autocomplete model (lightweight for low latency)
  - name: Qwen Coder (autocomplete)
    provider: ollama
    model: qwen2.5-coder:3b
    apiBase: http://localhost:11434
    roles:
      - autocomplete
    autocompleteOptions:
      debounceDelay: 350
      maxPromptTokens: 1024
      onlyMyCode: true
    defaultCompletionOptions:
      temperature: 0.2

  # Embeddings model (for codebase indexing / @codebase context)
  - name: Nomic Embed
    provider: ollama
    model: nomic-embed-text
    apiBase: http://localhost:11434
    roles:
      - embed
```

> **Note:** The embeddings model (`nomic-embed-text`) must be pulled separately:
> ```bash
> ollama pull nomic-embed-text
> ```
> Skip this block if you don't need `@codebase` context search.

### Using Continue

| Shortcut | Action |
|---|---|
| `Ctrl+L` | Open Chat panel |
| `Ctrl+I` | Inline Edit — highlight code, then apply an AI change |
| `Tab` | Accept autocomplete suggestion |
| `Esc` | Dismiss autocomplete suggestion |

**Context references you can use in chat:**

| Reference | What it includes |
|---|---|
| `@file` | A specific file |
| `@codebase` | Semantic search across your indexed repo |
| `@terminal` | Last terminal output |
| `@docs` | A documentation site you've added |

### Tips

- Start `./windows/start.ps1` (or `./linux/start.sh`) **before** opening VS Code — Continue connects to Ollama on startup.
- If autocomplete feels slow, reduce `maxPromptTokens` to `512` or switch to a smaller model like `qwen2.5-coder:1.5b`.
- For a stronger chat model without changing autocomplete, add a second entry under `models:` with a different model and restrict its role to `chat`.

---

## What Each Script Does

### `setup` (run once)
1. Confirms Ollama is installed.
2. Pulls `DEFAULT_MODEL` and any `EXTRA_MODELS`.
3. Confirms Docker is running.
4. Creates and starts the Open WebUI Docker container.

### `start` (run every session)
1. Starts the Ollama server if it is not already running.
2. Verifies the default model is present (pulls it if missing).
3. Confirms Docker is running.
4. Starts the Open WebUI container (creates it via `setup` if it doesn't exist).
5. Waits up to 30 seconds for the WebUI to be responsive.
6. Opens your browser to `http://localhost:3000`.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `ollama` not found | Restart your terminal after installing Ollama |
| Docker errors | Make sure Docker Desktop / Docker daemon is running |
| WebUI blank or slow | Wait ~30 s on first launch for the container to initialize |
| Model not found | Run `ollama pull qwen2.5-coder:3b` manually |
| Port 3000 already in use | Change `WEBUI_PORT` in your config file to e.g. `3001` |
| VS Code Continue not connecting | Set API base to `http://localhost:11434` in Continue settings |
| Linux: `permission denied` | Run `chmod +x linux/*.sh` |
| Linux: browser doesn't open | Install `xdg-utils` (`sudo apt install xdg-utils`) or open the URL manually |

---

## License

MIT
