# toolkit/continue

Drop-in setup for the [Continue](https://marketplace.visualstudio.com/items?itemName=Continue.continue) VS Code extension, wired to a local Ollama instance.

## Contents

```
toolkit/continue/
├── config.yaml          # Ready-to-use Continue config — copy to ~/.continue/
├── windows/
│   └── install.ps1      # Auto-installs config + pulls embed model (Windows)
├── linux/
│   └── install.sh       # Auto-installs config + pulls embed model (Linux/macOS)
└── prompts/             # Custom slash commands for Continue chat
    ├── commit-msg.yaml  # /commit-msg — writes a conventional commit message
    ├── explain.yaml     # /explain    — explains selected code
    ├── refactor.yaml    # /refactor   — refactors selected code
    └── tests.yaml       # /tests      — generates unit tests for selected code
```

## Quick Install

### Windows
```powershell
.\toolkit\continue\windows\install.ps1
```

### Linux / macOS
```bash
chmod +x toolkit/continue/linux/install.sh
./toolkit/continue/linux/install.sh
```

The install script:
1. Creates `~/.continue/` if it doesn't exist
2. Backs up any existing `config.yaml` to `config.yaml.bak`
3. Copies `config.yaml` into place
4. Offers to pull `nomic-embed-text` for `@codebase` semantic search

Then **reload VS Code** (`Ctrl+Shift+P` → "Reload Window").

## Manual Install

If you prefer to copy things yourself:

```bash
cp toolkit/continue/config.yaml ~/.continue/config.yaml
```

For the custom slash commands, copy the prompts into Continue's prompts directory:

```bash
# Linux / macOS
cp toolkit/continue/prompts/*.yaml ~/.continue/prompts/

# Windows (PowerShell)
Copy-Item toolkit\continue\prompts\*.yaml "$env:USERPROFILE\.continue\prompts\"
```

Then in Continue chat, type `/` to see the available commands.

## Models Used

| Role | Model | Notes |
|---|---|---|
| Chat / Agent | `qwen2.5-coder:3b` | Fast, code-focused |
| Autocomplete | `qwen2.5-coder:3b` | Low-temp, debounced |
| Embeddings | `nomic-embed-text` | Powers `@codebase` search |

To use a heavier chat model, uncomment the `qwen2.5:7b` block at the bottom of `config.yaml` and change its role to `chat`.

## Custom Slash Commands

| Command | What it does |
|---|---|
| `/commit-msg` | Writes a conventional commit message from the current diff |
| `/explain` | Explains selected code — what, how, gotchas |
| `/refactor` | Refactors selected code without changing behaviour |
| `/tests` | Generates unit tests for selected code |

Highlight code in the editor, open Continue chat (`Ctrl+L`), and type the command.
