# =========================
# Juju's Raspberry Pi .zshrc
# =========================

# --- Environment Variables ---
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
[[ -S "/run/user/$UID/gcr/ssh" ]] && export SSH_AUTH_SOCK="/run/user/$UID/gcr/ssh"

# --- PATH ---
# Prepend to PATH without duplicates (safe against re-sourcing)
path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return
  path=("${(@)path:#$dir}")
  path=("$dir" $path)
  typeset -U path PATH
  export PATH
}

export PNPM_HOME="$HOME/.local/share/pnpm"

path_prepend "$HOME/.local/share/npm/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.npm-global/bin"
path_prepend "$PNPM_HOME"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"

# --- Vanilla Zsh Plugins ---
# Plugins live outside Oh My Zsh and are loaded directly with standard zsh.
export ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

# Make custom completions and plugin completions visible before compinit.
fpath=(
  "$HOME/.zfunc"
  "$ZSH_PLUGIN_DIR/wallust"
  "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
  "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
  $fpath
)

autoload -Uz compinit colors
colors
compinit -d "$ZSH_CACHE_DIR/zcompdump"

source_if_readable() { [[ -r "$1" ]] && source "$1"; }

# Helper expected by the vendored git aliases plugin.
git_current_branch() {
  command git symbolic-ref --quiet --short HEAD 2>/dev/null \
    || command git rev-parse --short HEAD 2>/dev/null
}

source_if_readable "$ZSH_PLUGIN_DIR/git/git.plugin.zsh"
source_if_readable "$ZSH_PLUGIN_DIR/colorize/colorize.plugin.zsh"
source_if_readable "$ZSH_PLUGIN_DIR/colored-man-pages/colored-man-pages.plugin.zsh"
source_if_readable "$ZSH_PLUGIN_DIR/man/man.plugin.zsh"
source_if_readable "$ZSH_PLUGIN_DIR/wallust/wallust.plugin.zsh"

# command-not-found: source the platform handler when present.
for command_not_found_file in \
  /usr/share/doc/pkgfile/command-not-found.zsh \
  /usr/share/zsh/plugins/xbps-command-not-found/xbps-command-not-found.zsh; do
  if [[ -r "$command_not_found_file" ]]; then
    source "$command_not_found_file"
    break
  fi
done
unset command_not_found_file

# Debian/Raspberry Pi OS command-not-found helper, if installed.
if [[ -x /usr/lib/command-not-found || -x /usr/share/command-not-found/command-not-found ]]; then
  command_not_found_handler() {
    if [[ -x /usr/lib/command-not-found ]]; then
      /usr/lib/command-not-found -- "$1"
    else
      /usr/share/command-not-found/command-not-found -- "$1"
    fi
  }
fi

# thefuck integration, without Oh My Zsh.
if (( $+commands[thefuck] )); then
  [[ -r "$ZSH_CACHE_DIR/thefuck" ]] || thefuck --alias >| "$ZSH_CACHE_DIR/thefuck"
  source "$ZSH_CACHE_DIR/thefuck"

  fuck-command-line() {
    local fixed_command
    fixed_command="$(THEFUCK_REQUIRE_CONFIRMATION=0 thefuck $(fc -ln -1 | tail -n 1) 2>/dev/null)"
    [[ -z "$fixed_command" ]] && echo -n -e "\a" && return
    BUFFER="$fixed_command"
    zle end-of-line
  }
  zle -N fuck-command-line
  bindkey -M emacs '\e\e' fuck-command-line
fi

source_if_readable "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# --- Aliases ---
alias zshconfig="$EDITOR ~/.zshrc"
alias clr="clear"
alias cdnt="cd ~/Notes"

if (( $+commands[eza] )); then
  alias ls="eza -a --color=always --icons=always --group-directories-first"
  alias ll="eza -a -l --color=always --icons=always --group-directories-first"
else
  alias ls="ls -a --color=auto"
  alias ll="ls -alF --color=auto"
fi

(( $+commands[newsboat] )) && alias nb="newsboat -x open"
(( $+commands[macchina] )) && alias sysinfo="macchina"

# --- Zsh Options ---
# Include dotfiles in globs
setopt globdots

# --- Node Version Manager (nvm) ---
export NVM_DIR="$HOME/.nvm"
source_if_readable "$NVM_DIR/nvm.sh"
source_if_readable "$NVM_DIR/bash_completion"

# --- Custom Prompt ---
setopt PROMPT_SUBST
autoload -Uz vcs_info

# Git status indicators:
#   * = unstaged changes (modified files not yet added)
#   + = staged changes (files added, ready to commit)
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' formats '%b%u%c%m'
zstyle ':vcs_info:git:*' actionformats '%b%u%c%m (%a)'

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
    VENV_INFO="%F{yellow}($(basename -- "$VIRTUAL_ENV"))%f "
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

# Must be loaded after widgets and keybindings.
source_if_readable "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

function set-full-prompt {
  PROMPT=$'
%F{cyan}%n@%m%f
%{\x1b[3m%}%~%{\x1b[23m%}${EXIT_STATUS}${GIT_INFO}
${LLM_INFO}${VENV_INFO}%F{green}>%f '
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
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
    --color=bg:$background
    --color=fg:$foreground
    --color=hl:$color1
    --color=hl+:$color5
    --color=pointer:$color6
    --color=marker:$color3
    "
fi

# Source fzf keybindings and fuzzy completion when supported.
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh 2>/dev/null)

# FZF function for editing files
fe() {
  local editor="${EDITOR:-nvim}"
  if (( $+commands[bat] )); then
    fzf -m --preview='bat --color=always {}' --bind "enter:become($editor {+})"
  else
    fzf -m --bind "enter:become($editor {+})"
  fi
}

# Extract .7z archives
ex7z() {
  7z x "$1" -o"${1%.7z}"
}

# --- AIChat shell integration ---
SCRIPTS_DIR="$HOME/.config/aichat/shell-integrations-scripts"

# Optional: bind hotkey for AI-assisted commands
export AICHAT_HOTKEY='^[e'

# Source CLI completions first
[[ -f "$SCRIPTS_DIR/autocomplete.sh" ]] && source "$SCRIPTS_DIR/autocomplete.sh"

# Source interactive AI hotkey integration
[[ -f "$SCRIPTS_DIR/completions.sh" ]] && source "$SCRIPTS_DIR/completions.sh"

# Override any 'journal' alias defined by aichat scripts above
unalias journal 2>/dev/null
alias journal='aichat --agent journal'
(( $+commands[claude] )) && alias claudev='claude --verbose'

# System update: packages + Neovim plugins
update() {
  if (( $+commands[apt] )); then
    echo "==> Updating packages..."
    sudo apt update && sudo apt full-upgrade
  elif (( $+commands[yay] )); then
    echo "==> Updating packages..."
    yay -Syu
  fi

  if (( $+commands[nvim] )); then
    echo "==> Updating Neovim plugins..."
    time nvim --headless "+Lazy! update" +qa
  fi

  echo "==> Done."
}

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

# --- Figlet greeting ---
zsh_ascii_logo() {
  if (( $+commands[figlet] )); then
    figlet "Rasp Pi 5"
  else
    print -- "Rasp Pi 5"
  fi
}
zsh_ascii_logo
true


# Added by Antigravity CLI installer
export PATH="/home/juju/.local/bin:$PATH"
