# =========================
# Juju's .zshrc (working for fzf 0.68)
# =========================

# --- Environment Variables ---
export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"
export VISUAL="nvim"
export SSH_AUTH_SOCK="/run/user/$UID/gcr/ssh"
# export SUDO_ASKPASS="/usr/bin/ksshaskpass"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# --- Oh My Zsh Plugins ---
plugins=(git colorize colored-man-pages command-not-found man thefuck wallust zsh-autosuggestions zsh-syntax-highlighting)

# --- Custom keybindings for Zsh Plugins ---
bindkey '^F' autosuggest-accept

# Make custom completion files visible before Oh My Zsh runs compinit.
fpath=("$HOME/.zfunc" $fpath)

# --- Source Oh My Zsh ---
source $ZSH/oh-my-zsh.sh

# --- Aliases ---
alias zshconfig="$EDITOR ~/.zshrc"
alias ohmyzsh="$EDITOR ~/.oh-my-zsh"
alias ls="eza -a --color=always --icons=always --group-directories-first"
alias ll="eza -a -l --color=always --icons=always --group-directories-first"
alias clr="clear"
alias nb="newsboat -x open"
alias cdnt="cd ~/Notes"
alias newmatrix='neo-matrix -C ~/.config/neo/colors -m "Fuck Off"'

# --- Vi Mode ---
bindkey -v
export KEYTIMEOUT=1

# --- Zsh Options ---
# Include dotfiles in globs
setopt globdots

# --- Node Version Manager (nvm) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- Custom Prompt ---
setopt PROMPT_SUBST
autoload -Uz vcs_info

# Git status indicators:
#   * = unstaged changes (modified files not yet added)
#   + = staged changes (files added, ready to commit)
#  ** = untracked files (new files git doesn't know about)
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' formats '%b%u%c%m'
zstyle ':vcs_info:git:*' actionformats '%b%u%c%m (%a)'

# Hook to detect untracked files and show ** indicator
+vi-git-untracked() {
  if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]]; then
    if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]]; then
      hook_com[misc]='**'
    fi
  fi
}

zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

precmd() {
  local exit_code=$?
  vcs_info

  # Exit code display (only shown when non-zero)
  if (( exit_code != 0 )); then
    EXIT_STATUS=" %F{red}${exit_code}%f"
  else
    EXIT_STATUS=""
  fi

  # Git info
  local italic_on=$'\x1b[3m'
  local italic_off=$'\x1b[23m'
  if [[ -n ${vcs_info_msg_0_} ]]; then
    GIT_INFO=" %F{green}%{${italic_on}%}${vcs_info_msg_0_}%{${italic_off}%}%f"
  else
    GIT_INFO=""
  fi

  # Python venv indicator
  if [[ -n $VIRTUAL_ENV ]]; then
    VENV_INFO="%F{yellow}($(basename $VIRTUAL_ENV))%f "
  else
    VENV_INFO=""
  fi

  # LLM auto-approve indicator
  if [[ -n $LLM_AUTO_APPROVE ]]; then
    LLM_INFO="%F{red}[llm-auto-approve]%f "
  else
    LLM_INFO=""
  fi
}

# Vi mode indicator (nerd font arrows, color switches by mode)
VI_MODE='%B%F{green}❯%f%b'
function zle-line-init zle-keymap-select {
  case $KEYMAP in
    vicmd) VI_MODE='%B%F{red}❮%f%b' ;;
    *)     VI_MODE='%B%F{green}❯%f%b' ;;
  esac
  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

# Transient prompt - simplify previous prompt after command execution
function zle-line-finish {
  PROMPT='%F{%(?.green.red)}❯%f '
  zle reset-prompt
  set-full-prompt
}
zle -N zle-line-finish

function set-full-prompt {
  PROMPT=$'
%{\x1b[3m%}%~%{\x1b[23m%}${EXIT_STATUS}${GIT_INFO}
${LLM_INFO}${VENV_INFO}${VI_MODE} '
}
set-full-prompt

# --- Completion tweaks ---
# Remove ../ and ./ from completion results
zstyle ':completion:*' special-dirs false

# Dart CLI Completion (if installed)
[[ -f ~/.config/.dart-cli-completion/zsh-config.zsh ]] && . ~/.config/.dart-cli-completion/zsh-config.zsh || true

# --- FZF Setup ---
unset FZF_DEFAULT_OPTS

# Base FZF settings: layout, border, preview, keybindings
export FZF_DEFAULT_OPTS="
--layout=reverse
--border=sharp
--info=inline
--preview-window=right:60%
--bind=ctrl-u:preview-half-page-up
--bind=ctrl-d:preview-half-page-down
--bind=ctrl-p:toggle-preview
"

# Optional: Wallust dynamic colors for fzf
# Only applied if using newer fzf versions or for CLI calls
if [[ -f ~/.cache/wallust/colors.sh ]]; then
    source ~/.cache/wallust/colors.sh
    # Add color options only for commands that support hex values
    # Note: fzf 0.68 requires separate --color flags (no comma-separated values)
    # Uncomment the lines below if your fzf supports hex colors
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
    --color=bg:$background
    --color=fg:$foreground
    --color=hl:$color1
    --color=hl+:$color5
    --color=pointer:$color6
    --color=marker:$color3
    "
fi

# Source fzf keybindings and fuzzy completion
source <(fzf --zsh)

# FZF function for editing files
fe() { fzf -m --preview='bat --color=always {}' --bind 'enter:become(nvim {+})'; }

# Extract .7z archives
ex7z() {
    7z x "$1" -o"${1%.7z}"
}

# ----------------------------
# AIChat shell integration
# ----------------------------
SCRIPTS_DIR="$HOME/.config/aichat/shell-integrations-scripts"

# Optional: bind hotkey for AI-assisted commands
export AICHAT_HOTKEY='^[e'   # Alt+e

# Source CLI completions first
[[ -f "$SCRIPTS_DIR/autocomplete.sh" ]] && source "$SCRIPTS_DIR/autocomplete.sh"

# Source interactive AI hotkey integration
[[ -f "$SCRIPTS_DIR/completions.sh" ]] && source "$SCRIPTS_DIR/completions.sh"
export PATH="$HOME/.npm-global/bin:$PATH"

# pnpm
export PNPM_HOME="/home/juju/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
unalias journal 2>/dev/null
alias journal='aichat --agent journal'

# Toggle LLM auto-approve (skips tool confirmation prompts)
function llm-approve() {
  if [[ -z "$LLM_AUTO_APPROVE" ]]; then
    export LLM_AUTO_APPROVE=1
    echo "LLM auto-approve enabled"
  else
    unset LLM_AUTO_APPROVE
    echo "LLM auto-approve disabled"
  fi
}

# llama.cpp
export PATH="$HOME/repos/llama.cpp/build/bin:$PATH"

# Optional system info
alias sysinfo='macchina'
macchina

# OpenClaw Completion
source "/home/juju/.openclaw/completions/openclaw.zsh"
