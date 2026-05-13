#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ZSHRC="$SCRIPT_DIR/zshrc"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
PKG_MGR=""

APT_PACKAGES=(
  bat
  curl
  fzf
  git
  graphviz
  httpie
  jq
  neovim
  ngrep
  nodejs
  postgresql
  protobuf-compiler
  redis-server
  ripgrep
  shc
  sshuttle
  telnet
  tmux
  watch
  zoxide
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
)

DNF_PACKAGES=(
  bat
  curl
  fzf
  git
  graphviz
  httpie
  jq
  neovim
  ngrep
  nodejs
  postgresql-server
  protobuf-compiler
  redis
  ripgrep
  ShellCheck
  sshuttle
  telnet
  tmux
  watch
  zoxide
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
)

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  GO_ARCH="amd64" ;;
  aarch64) GO_ARCH="arm64" ;;
  *)       GO_ARCH="$ARCH" ;;
esac

log() {
  printf "[install-linux] %s\n" "$*"
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

detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt"
    log "Detected package manager: apt (Debian/Ubuntu)"
  elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
    log "Detected package manager: dnf (Fedora/RHEL)"
  else
    log "ERROR: Neither apt nor dnf found. This script supports Debian/Ubuntu and Fedora/RHEL only."
    exit 1
  fi
}

install_system_packages() {
  if [[ "$PKG_MGR" == "apt" ]]; then
    log "Updating apt package index"
    sudo apt-get update -y

    log "Installing system packages via apt"
    sudo apt-get install -y "${APT_PACKAGES[@]}"
  else
    log "Updating dnf package index"
    sudo dnf makecache -y

    log "Installing system packages via dnf"
    sudo dnf install -y "${DNF_PACKAGES[@]}"
  fi
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed"
    return
  fi

  log "Installing Docker Engine"

  if [[ "$PKG_MGR" == "apt" ]]; then
    sudo apt-get install -y ca-certificates gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    local distro_id
    distro_id="$(. /etc/os-release && echo "$ID")"

    curl -fsSL "https://download.docker.com/linux/${distro_id}/gpg" \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/${distro_id} \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin
  else
    sudo dnf install -y dnf-plugins-core
    local distro_id
    distro_id="$(. /etc/os-release && echo "$ID")"

    sudo dnf config-manager --add-repo \
      "https://download.docker.com/linux/${distro_id}/docker-ce.repo" || true

    sudo dnf install -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin
  fi

  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER" || true
  log "Docker installed. Log out and back in for group membership to take effect."
}

install_kubernetes_tools() {
  if command -v kubectl >/dev/null 2>&1; then
    log "kubectl already installed"
  else
    log "Installing kubectl"
    local kubectl_version
    kubectl_version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
    curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${kubectl_version}/bin/linux/${GO_ARCH}/kubectl"
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
  fi

  if command -v helm >/dev/null 2>&1; then
    log "Helm already installed"
  else
    log "Installing Helm"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi

  if command -v minikube >/dev/null 2>&1; then
    log "Minikube already installed"
  else
    log "Installing Minikube"
    curl -fsSLo /tmp/minikube "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${GO_ARCH}"
    sudo install -o root -g root -m 0755 /tmp/minikube /usr/local/bin/minikube
    rm -f /tmp/minikube
  fi

  if command -v stern >/dev/null 2>&1; then
    log "Stern already installed"
  else
    log "Installing Stern"
    local stern_ver
    stern_ver="$(curl -fsSL https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d '"' -f4)"
    curl -fsSLo /tmp/stern.tar.gz \
      "https://github.com/stern/stern/releases/download/${stern_ver}/stern_${stern_ver#v}_linux_${GO_ARCH}.tar.gz"
    tar -xzf /tmp/stern.tar.gz -C /tmp stern
    sudo install -o root -g root -m 0755 /tmp/stern /usr/local/bin/stern
    rm -f /tmp/stern /tmp/stern.tar.gz
  fi

  if command -v kubelogin >/dev/null 2>&1; then
    log "kubelogin already installed"
  else
    log "Installing kubelogin"
    local kl_ver
    kl_ver="$(curl -fsSL https://api.github.com/repos/Azure/kubelogin/releases/latest | grep tag_name | cut -d '"' -f4)"
    curl -fsSLo /tmp/kubelogin.zip \
      "https://github.com/Azure/kubelogin/releases/download/${kl_ver}/kubelogin-linux-${GO_ARCH}.zip"
    unzip -o /tmp/kubelogin.zip -d /tmp/kubelogin
    sudo install -o root -g root -m 0755 /tmp/kubelogin/bin/linux_${GO_ARCH}/kubelogin /usr/local/bin/kubelogin
    rm -rf /tmp/kubelogin /tmp/kubelogin.zip
  fi

  if command -v kubeseal >/dev/null 2>&1; then
    log "kubeseal already installed"
  else
    log "Installing kubeseal"
    local ks_ver
    ks_ver="$(curl -fsSL https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | grep tag_name | cut -d '"' -f4)"
    curl -fsSLo /tmp/kubeseal.tar.gz \
      "https://github.com/bitnami-labs/sealed-secrets/releases/download/${ks_ver}/kubeseal-${ks_ver#v}-linux-${GO_ARCH}.tar.gz"
    tar -xzf /tmp/kubeseal.tar.gz -C /tmp kubeseal
    sudo install -o root -g root -m 0755 /tmp/kubeseal /usr/local/bin/kubeseal
    rm -f /tmp/kubeseal /tmp/kubeseal.tar.gz
  fi

  if command -v kubetail >/dev/null 2>&1; then
    log "kubetail already installed"
  else
    log "Installing kubetail"
    local kt_ver
    kt_ver="$(curl -fsSL https://api.github.com/repos/johanhaleby/kubetail/releases/latest | grep tag_name | cut -d '"' -f4)"
    curl -fsSLo /tmp/kubetail "https://raw.githubusercontent.com/johanhaleby/kubetail/${kt_ver}/kubetail"
    sudo install -o root -g root -m 0755 /tmp/kubetail /usr/local/bin/kubetail
    rm -f /tmp/kubetail
  fi
}

install_security_tools() {
  if command -v trivy >/dev/null 2>&1; then
    log "Trivy already installed"
  else
    log "Installing Trivy"
    if [[ "$PKG_MGR" == "apt" ]]; then
      sudo apt-get install -y wget apt-transport-https
      wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
      echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
        | sudo tee /etc/apt/sources.list.d/trivy.list >/dev/null
      sudo apt-get update -y
      sudo apt-get install -y trivy
    else
      sudo rpm --import https://aquasecurity.github.io/trivy-repo/rpm/public.key
      cat <<'REPO' | sudo tee /etc/yum.repos.d/trivy.repo >/dev/null
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
REPO
      sudo dnf install -y trivy
    fi
  fi

  if command -v trufflehog >/dev/null 2>&1; then
    log "TruffleHog already installed"
  else
    log "Installing TruffleHog"
    local th_ver
    th_ver="$(curl -fsSL https://api.github.com/repos/trufflesecurity/trufflehog/releases/latest | grep tag_name | cut -d '"' -f4)"
    curl -fsSLo /tmp/trufflehog.tar.gz \
      "https://github.com/trufflesecurity/trufflehog/releases/download/${th_ver}/trufflehog_${th_ver#v}_linux_${GO_ARCH}.tar.gz"
    tar -xzf /tmp/trufflehog.tar.gz -C /tmp trufflehog
    sudo install -o root -g root -m 0755 /tmp/trufflehog /usr/local/bin/trufflehog
    rm -f /tmp/trufflehog /tmp/trufflehog.tar.gz
  fi
}

install_go_tools() {
  local go_bin="${GOPATH:-$HOME/go}/bin"

  if ! command -v go >/dev/null 2>&1; then
    log "Go not found; installing via GoBrew later — skipping go-install tools for now"
    return
  fi

  local -A tools=(
    [air]="github.com/air-verse/air@latest"
    [act]="github.com/nektos/act@latest"
    [lazygit]="github.com/jesseduffield/lazygit@latest"
    [buf]="github.com/bufbuild/buf/cmd/buf@latest"
  )

  for bin in "${!tools[@]}"; do
    if [[ -x "$go_bin/$bin" ]] || command -v "$bin" >/dev/null 2>&1; then
      log "Go tool '$bin' already installed"
      continue
    fi

    log "Installing Go tool '$bin'"
    go install "${tools[$bin]}"
  done
}

install_load_testing_tools() {
  if command -v k6 >/dev/null 2>&1; then
    log "k6 already installed"
  else
    log "Installing k6"
    if [[ "$PKG_MGR" == "apt" ]]; then
      sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
        --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69 2>/dev/null || true
      echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
        | sudo tee /etc/apt/sources.list.d/k6.list >/dev/null
      sudo apt-get update -y
      sudo apt-get install -y k6
    else
      sudo dnf install -y "https://dl.k6.io/rpm/repo.rpm" || true
      sudo dnf install -y k6
    fi
  fi

  if command -v oha >/dev/null 2>&1; then
    log "oha already installed"
  else
    log "Installing oha"
    local oha_ver
    oha_ver="$(curl -fsSL https://api.github.com/repos/hatoo/oha/releases/latest | grep tag_name | cut -d '"' -f4)"
    curl -fsSLo /tmp/oha \
      "https://github.com/hatoo/oha/releases/download/${oha_ver}/oha-linux-${GO_ARCH}" 2>/dev/null || {
      log "oha binary not available for this architecture; skipping"
      return
    }
    sudo install -o root -g root -m 0755 /tmp/oha /usr/local/bin/oha
    rm -f /tmp/oha
  fi
}

install_azure_cli() {
  if command -v az >/dev/null 2>&1; then
    log "Azure CLI already installed"
    return
  fi

  log "Installing Azure CLI"
  curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    log "mise already installed"
    return
  fi

  log "Installing mise"
  curl https://mise.run | sh
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

set_default_shell_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ "$SHELL" == "$zsh_path" ]]; then
    log "Default shell is already zsh"
    return
  fi

  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    log "Adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  log "Changing default shell to zsh"
  chsh -s "$zsh_path"
}

main() {
  detect_package_manager
  install_system_packages
  install_docker
  install_kubernetes_tools
  install_security_tools
  install_load_testing_tools
  install_azure_cli
  install_mise
  install_oh_my_zsh_dependencies
  install_nvm
  install_gobrew
  install_go_tools
  install_zshrc
  set_default_shell_zsh

  if [[ -f "$HOME/.zshrc" ]]; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
      log "Sourcing ~/.zshrc to apply updates"
      # shellcheck disable=SC1090
      source "$HOME/.zshrc"
    else
      log "Run 'source ~/.zshrc' or log out and back in to pick up changes"
    fi
  fi

  log "All requested software is installed"
}

main "$@"
