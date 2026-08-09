# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =====================================================================
# ~/.zshrc – Manendra Pal Singh
# Cross-platform developer-ready terminal setup (macOS + Linux)
# =====================================================================

# ----------------------------------
# Load Homebrew (macOS only)
# ----------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ----------------------------------
# Oh My Zsh
# ----------------------------------
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git)

# Only enable optional plugins that are actually installed. This keeps startup
# clean when the same dotfile is used before the bootstrap script has run.
for plugin in \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  zsh-completions \
  zsh-history-substring-search; do
  [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/$plugin" ]] && plugins+=("$plugin")
done

source $ZSH/oh-my-zsh.sh

# ----------------------------------
# Load Powerlevel10k
# ----------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ----------------------------------
# Go environment
# ----------------------------------
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# ----------------------------------
# Version Managers
# ----------------------------------

# GoBrew does not provide a `shellenv` command. Add its documented paths
# directly and let `gobrew use` manage the `current` symlink.
if [[ -d "$HOME/.gobrew" ]]; then
  export PATH="$HOME/.gobrew/current/bin:$HOME/.gobrew/bin:$PATH"
  export GOPATH="$HOME/.gobrew/current/go"
fi

# Mise (polyglot runtime manager)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# ----------------------------------
# fzf & zoxide
# ----------------------------------
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ----------------------------------
# PostgreSQL (Homebrew keg-only path)
# ----------------------------------
if [[ -d /opt/homebrew/opt/postgresql@14/bin ]]; then
  export PATH="/opt/homebrew/opt/postgresql@14/bin:$PATH"
fi

# ----------------------------------
# Terminal Enhancements
# ----------------------------------
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# ----------------------------------
# Aliases
# ----------------------------------
alias ll="ls -lah"
alias gs="git status"
alias gb="git branch"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias lg="lazygit"
alias k="kubectl"
alias cat="bat"
alias grep="rg"

# ----------------------------------
# Editor & Locale
# ----------------------------------
export EDITOR="nvim"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

alias reload="source ~/.zshrc"

# =====================================================================
# End of File
# =====================================================================
