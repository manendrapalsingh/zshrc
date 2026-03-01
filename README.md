# Dev Machine Setup

One-script bootstrap to replicate my full development environment on any fresh Mac or Linux machine.

## What Gets Installed

| Category | Tools |
|---|---|
| **Containers & K8s** | Docker, Docker Compose, Docker Buildx, Colima (Mac) / Docker Engine (Linux), Helm, Minikube, Stern |
| **Languages** | Go (via GoBrew), Node.js (via NVM), Air (Go live-reload), Protobuf |
| **Dev Tools** | Neovim, Lazygit, tmux, Act (GitHub Actions), Buf, Graphviz, shc, watch |
| **Databases** | PostgreSQL 14, Redis |
| **Security** | Trivy, TruffleHog |
| **Networking** | HTTPie, k6, oha, ngrep, sshuttle, telnet |
| **Shell** | Zsh, Oh My Zsh, Powerlevel10k, fzf, ripgrep, bat, zoxide, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, zsh-history-substring-search |
| **AI** | Gemini CLI |
| **Mac GUI Apps** | JetBrains Mono Nerd Font, Maccy (clipboard manager), ngrok |

## Usage

### macOS

```bash
git clone https://github.com/<your-username>/zshrc.git
cd zshrc
./install_mac_software.sh
```

Supports both Apple Silicon and Intel Macs. Uses Homebrew for all packages.

### Linux (Ubuntu/Debian or Fedora/RHEL)

```bash
git clone https://github.com/<your-username>/zshrc.git
cd zshrc
./install_linux_software.sh
```

Auto-detects `apt` or `dnf` and installs the appropriate packages. Docker is installed from the official Docker repository. Tools without native packages (Stern, k6, oha, TruffleHog) are installed from GitHub releases or via `go install`.

## What Gets Configured

- **~/.zshrc** -- copied from the repo's `zshrc` file (existing one is backed up with a timestamp)
- **Oh My Zsh** -- cloned with Powerlevel10k theme
- **Plugins** -- zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, zsh-history-substring-search
- **NVM** -- installed for Node.js version management
- **GoBrew** -- installed for Go version management
- **fzf** -- fuzzy finder keybindings loaded automatically
- **zoxide** -- smarter `cd` initialized automatically
- **Default shell** -- set to zsh on Linux (macOS already defaults to zsh)

## Platform Differences

| Feature | macOS | Linux |
|---|---|---|
| Package manager | Homebrew | apt / dnf |
| Container runtime | Colima + Docker CLI | Docker Engine |
| GUI apps (casks) | JetBrains Mono Nerd Font, Maccy, ngrok | N/A |
| Xcode CLI Tools | Installed first | N/A |
| Default shell | Already zsh | Changed to zsh by script |

## Prerequisites

- **macOS**: A fresh Mac (script installs Xcode CLI Tools and Homebrew automatically)
- **Linux**: Ubuntu/Debian or Fedora/RHEL with `sudo` access

## Re-running

Both scripts are idempotent -- they check if each tool is already installed before acting, so you can safely re-run them at any time to pick up new additions.
