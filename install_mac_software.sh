#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ZSHRC="$SCRIPT_DIR/zshrc"

BREW_FORMULAE=(
  bat
  ca-certificates
  colima
  docker
  docker-buildx
  docker-completion
  docker-compose
  go
  helm
  kubernetes-cli
  libgit2
  libpcap
  libssh2
  lima
  minikube
  ngrep
  oniguruma
  openssl@3
  pcre2
  ripgrep
  zsh-autosuggestions
  zsh-syntax-highlighting
)

BREW_CASKS=()

log() {
  printf "[install-mac] %s\n" "$*"
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
  install_brew_packages
  install_zshrc

  log "All requested software is installed"
}

main "$@"

