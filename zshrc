# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =====================================================================
# ~/.zshrc – Manendra Pal Singh (Mac M4)
# Complete developer-ready terminal setup
# =====================================================================

# ----------------------------------
# Load Homebrew (Apple Silicon)
# ----------------------------------
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ----------------------------------
# Oh My Zsh
# ----------------------------------
export ZSH="$HOME/.oh-my-zsh"

# Theme: Powerlevel10k installed in custom folder
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ----------------------------------
# Load Powerlevel10k (for safety)
# ----------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Go environment
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# ----------------------------------
# Autosuggestions & Syntax Highlighting
# ----------------------------------
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ----------------------------------
# Version Managers
# ----------------------------------

# GoBrew
if [ -f "$HOME/.gobrew/bin/gobrew" ]; then
  eval "$($HOME/.gobrew/bin/gobrew shellenv)"
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ----------------------------------
# Terminal Enhancements
# ----------------------------------
# Enable command completion
autoload -Uz compinit && compinit

# History search with arrows
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# Useful aliases
alias ll="ls -lah"
alias gs="git status"
alias gb="git branch"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias cat="bat"  # if you install bat
alias grep="rg"  # if you install ripgrep

# Editor
export EDITOR="nano"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Reload zsh easily
alias reload="source ~/.zshrc"

# =====================================================================
# End of File
# =====================================================================