# project-ollama

Local, private AI environment — [Ollama](https://ollama.com) + [Open WebUI](https://github.com/open-webui/open-webui) + [Continue](https://marketplace.visualstudio.com/items?itemName=Continue.continue) for VS Code.

## Stack

| | |
|---|---|
| Ollama | Local LLM inference engine |
| `qwen2.5-coder:3b` | Default model (fast, code-focused) |
| Open WebUI | Chat UI at `http://localhost:3000` |
| Continue | AI coding assistant in VS Code |

## Requirements

- [Ollama](https://ollama.com) on `PATH`
- [Docker](https://www.docker.com/products/docker-desktop/) running
- GPU recommended (NVIDIA GTX 1660 Super or better)
- Windows: PowerShell 5.1+
- Linux/macOS: Bash 4+, `curl`

## Quick Start

**Windows**
```powershell
# One-time: allow local scripts to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

git clone https://github.com/saratrajan/project-ollama.git
cd project-ollama
.\windows\setup.ps1       # first time only
.\windows\start.ps1       # every session
```

**Linux / macOS**
```bash
git clone https://github.com/saratrajan/project-ollama.git
cd project-ollama
chmod +x linux/*.sh
./linux/setup.sh          # first time only
./linux/start.sh          # every session
```

## Configuration

Edit `windows/config.ps1` or `linux/config.sh` before running setup:

| Setting | Default |
|---|---|
| `DEFAULT_MODEL` | `qwen2.5-coder:3b` |
| `EXTRA_MODELS` | `qwen2.5:7b` |
| `WEBUI_PORT` | `3000` |
| `OLLAMA_HOST` | `http://localhost:11434` |
| `AUTO_OPEN_BROWSER` | `true` |

## Script flags

| Script | Flags |
|---|---|
| `setup` | `--skip-webui` / `-SkipWebUI` — Ollama + models only, skip Docker |
| `start` | `--no-browser` / `-NoBrowser` — don't open browser |
| `teardown` | `--yes` / `-Yes` — skip confirmation prompt |

## Stopping & Teardown

### Stop (reversible)
Stops Open WebUI container and Ollama. Models and data are preserved. Run `start` to resume.

**Windows**
```powershell
.\windows\stop.ps1
```

**Linux / macOS**
```bash
./linux/stop.sh
```

### Teardown (destructive)
Stops and **removes** the container and WebUI data volume. Ollama and pulled models are untouched. Run `setup` to rebuild.

**Windows**
```powershell
.\windows\teardown.ps1          # prompts for confirmation
.\windows\teardown.ps1 -Yes     # skip prompt
```

**Linux / macOS**
```bash
./linux/teardown.sh             # prompts for confirmation
./linux/teardown.sh --yes       # skip prompt
```

## Adding Models

```bash
ollama pull qwen2.5-coder:7b   # larger coding model (~5GB)
ollama pull qwen2.5:7b          # general chat (~5GB)
ollama pull qwen2.5-coder:1.5b # CPU-friendly
```

Add model names to `EXTRA_MODELS` in config to pull them automatically next setup.

## Continue (VS Code)

Install: `Ctrl+P` → `ext install Continue.continue`

Configure `~/.continue/config.yaml`:

```yaml
models:
  - name: Qwen Coder (chat)
    provider: ollama
    model: qwen2.5-coder:3b
    apiBase: http://localhost:11434
    roles: [chat, agent]

  - name: Qwen Coder (autocomplete)
    provider: ollama
    model: qwen2.5-coder:3b
    apiBase: http://localhost:11434
    roles: [autocomplete]
    autocompleteOptions:
      debounceDelay: 350
      maxPromptTokens: 1024
      onlyMyCode: true
    defaultCompletionOptions:
      temperature: 0.2

  - name: Nomic Embed
    provider: ollama
    model: nomic-embed-text      # ollama pull nomic-embed-text
    apiBase: http://localhost:11434
    roles: [embed]
```

| Shortcut | Action |
|---|---|
| `Ctrl+L` | Open chat |
| `Ctrl+I` | Inline edit |
| `Tab` | Accept autocomplete |

In chat: `@file`, `@codebase`, `@terminal`, `@docs`

> Start Ollama (`start.ps1` / `start.sh`) before opening VS Code.

## Troubleshooting

| Problem | Fix |
|---|---|
| `ollama` not found | Restart terminal after install |
| Docker errors | Start Docker Desktop / daemon |
| WebUI slow on first launch | Wait ~30s for container init |
| Port 3000 in use | Set `WEBUI_PORT=3001` in config |
| Linux permission denied | `chmod +x linux/*.sh` |
| Linux browser won't open | `sudo apt install xdg-utils` |

## License

MIT
