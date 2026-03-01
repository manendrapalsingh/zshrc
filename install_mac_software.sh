#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ZSHRC="$SCRIPT_DIR/zshrc"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"

BREW_TAPS=(
  aquasecurity/trivy
  bufbuild/buf
)

BREW_FORMULAE=(
  # Containers & Kubernetes
  colima
  docker
  docker-buildx
  docker-compose
  helm
  minikube
  stern

  # Languages & Runtimes
  go-air
  protobuf

  # Dev tools
  act
  bufbuild/buf/buf
  graphviz
  lazygit
  neovim
  shc
  tmux
  watch

  # Databases
  postgresql@14
  redis

  # Security
  trivy
  trufflehog

  # Networking
  httpie
  k6
  ngrep
  oha
  sshuttle
  telnet

  # Shell enhancements
  bat
  fzf
  ripgrep
  zoxide
  zsh-autosuggestions
  zsh-completions
  zsh-history-substring-search
  zsh-syntax-highlighting

  # AI
  gemini-cli
)

BREW_CASKS=(
  font-jetbrains-mono-nerd-font
  maccy
  ngrok
)

log() {
  printf "[install-mac] %s\n" "$*"
}

ensure_git_repo() {
  local target_path="$1"
  local repo_url="$2"
  local description="$3"

  if git -C "$target_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "$description already installed"
    return
  fi

  if [[ -d "$target_path" ]]; then
    log "$description directory exists but is not a git repository; skipping clone"
    return
  fi

  local parent_dir
  parent_dir="$(dirname "$target_path")"
  mkdir -p "$parent_dir"

  log "Cloning $description from $repo_url"
  git clone "$repo_url" "$target_path"
}

ensure_xcode_cli() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  log "Triggering Xcode Command Line Tools installation (requires user interaction)"
  xcode-select --install || true
  log "Re-run this script after the installation completes"
  exit 0
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed"
    return
  fi

  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    log "Unable to determine Homebrew installation path"
    exit 1
  fi
}

install_brew_taps() {
  for tap in "${BREW_TAPS[@]}"; do
    if brew tap | grep -qx "$tap"; then
      log "Tap '$tap' already added"
      continue
    fi

    log "Adding tap '$tap'"
    brew tap "$tap"
  done
}

install_brew_packages() {
  log "Updating Homebrew"
  brew update

  for formula in "${BREW_FORMULAE[@]}"; do
    if brew list --formula | grep -qx "$formula"; then
      log "Formula '$formula' already installed"
      continue
    fi

    log "Installing formula '$formula'"
    brew install "$formula"
  done

  if [[ ${#BREW_CASKS[@]} -gt 0 ]]; then
    for cask in "${BREW_CASKS[@]}"; do
      if brew list --cask | grep -qx "$cask"; then
        log "Cask '$cask' already installed"
        continue
      fi

      log "Installing cask '$cask'"
      brew install --cask "$cask"
    done
  fi
}

install_oh_my_zsh_dependencies() {
  if git -C "$OH_MY_ZSH_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Oh My Zsh already installed"
  elif [[ -d "$OH_MY_ZSH_DIR" ]]; then
    log "Directory '$OH_MY_ZSH_DIR' exists but is not a git repository; skipping Oh My Zsh installation"
  else
    log "Installing Oh My Zsh into '$OH_MY_ZSH_DIR'"
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
  fi

  local zsh_custom="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
  local theme_dir="$zsh_custom/themes/powerlevel10k"
  local autosuggest_dir="$zsh_custom/plugins/zsh-autosuggestions"
  local syntax_dir="$zsh_custom/plugins/zsh-syntax-highlighting"

  ensure_git_repo "$theme_dir" https://github.com/romkatv/powerlevel10k.git "Powerlevel10k theme"
  ensure_git_repo "$autosuggest_dir" https://github.com/zsh-users/zsh-autosuggestions.git "zsh-autosuggestions plugin"
  ensure_git_repo "$syntax_dir" https://github.com/zsh-users/zsh-syntax-highlighting.git "zsh-syntax-highlighting plugin"
}

install_nvm() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

  if [[ -d "$nvm_dir" ]]; then
    log "NVM already installed at '$nvm_dir'"
    return
  fi

  log "Installing NVM"
  PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh)"
}

install_gobrew() {
  if [[ -f "$HOME/.gobrew/bin/gobrew" ]]; then
    log "GoBrew already installed"
    return
  fi

  log "Installing GoBrew"
  curl -fsSL https://raw.githubusercontent.com/kevincobain2000/gobrew/master/git.io.sh | sh
}

install_zshrc() {
  if [[ ! -f "$REPO_ZSHRC" ]]; then
    log "Repository zshrc not found at '$REPO_ZSHRC'"
    return
  fi

  local target="$HOME/.zshrc"

  if [[ -f "$target" && ! -L "$target" ]]; then
    local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
    log "Backing up existing .zshrc to '$backup'"
    cp "$target" "$backup"
  fi

  log "Copying repository zshrc to '$target'"
  cp "$REPO_ZSHRC" "$target"
}

main() {
  ensure_xcode_cli
  ensure_homebrew
  install_brew_taps
  install_brew_packages
  install_oh_my_zsh_dependencies
  install_nvm
  install_gobrew
  install_zshrc

  if [[ -f "$HOME/.zshrc" ]]; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
      log "Sourcing ~/.zshrc to apply updates"
      # shellcheck disable=SC1090
      source "$HOME/.zshrc"
    else
      log "Run 'source ~/.zshrc' in your shell to pick up changes"
    fi
  fi

  log "All requested software is installed"
}

main "$@"
